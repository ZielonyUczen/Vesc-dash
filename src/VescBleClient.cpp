#include "VescBleClient.h"
#include "VescController.h"

#include <QDebug>
#include <QtEndian>
#include <cstring>

/*
 * libsimplebm integration notes
 * ─────────────────────────────
 * libsimplebm exposes a C API. Include the library header and link against it
 * via CMakeLists.txt (target: simplebm).
 *
 * VESC Nordic UART Service (NUS) UUIDs:
 *   Service  : 6e400001-b5a3-f393-e0a9-e50e24dcca9e
 *   TX (notify): 6e400003-b5a3-f393-e0a9-e50e24dcca9e  (VESC → app)
 *   RX (write) : 6e400002-b5a3-f393-e0a9-e50e24dcca9e  (app → VESC)
 *
 * RT data request packet to send periodically on RX:
 *   { 0x02, 0x01, 0x04, <crc_high>, <crc_low>, 0x03 }
 *
 * The header below is a forward declaration — the actual libsimplebm header
 * must be present at build time (third_party/libsimplebm/include/simplebm.h).
 */
#ifdef HAVE_LIBSIMPLEBM
#  include <simplebm.h>
#endif

// ── VESC packet framing constants ──────────────────────────────────────────
static constexpr quint8 VESC_START_BYTE   = 0x02;
static constexpr quint8 VESC_END_BYTE     = 0x03;
static constexpr quint8 COMM_GET_VALUES   = 0x04;
// Byte offsets inside a COMM_GET_VALUES response payload (firmware 7.x)
static constexpr int OFF_TEMP_MOS    = 0;   // float16 → scale ×10
static constexpr int OFF_TEMP_MOTOR  = 2;   // float16 → scale ×10
static constexpr int OFF_I_MOTOR     = 4;   // float32
static constexpr int OFF_I_INPUT     = 8;   // float32
static constexpr int OFF_V_INPUT     = 20;  // float32
static constexpr int OFF_DUTY        = 24;  // float16 → scale ×1000
static constexpr int OFF_ERPM        = 26;  // int32
static constexpr int OFF_AH          = 34;  // float32
static constexpr int OFF_WH          = 42;  // float32
static constexpr int OFF_FAULT       = 72;  // uint8

// ── CRC-16 (CCITT) for VESC packet ─────────────────────────────────────────
static quint16 crc16(const quint8 *data, int len)
{
    quint16 crc = 0;
    for (int i = 0; i < len; ++i) {
        crc ^= static_cast<quint16>(data[i]) << 8;
        for (int j = 0; j < 8; ++j)
            crc = (crc & 0x8000) ? (crc << 1) ^ 0x1021 : crc << 1;
    }
    return crc;
}

// ── Build a COMM_GET_VALUES request packet ──────────────────────────────────
static QByteArray buildGetValuesPacket()
{
    quint8 payload[1] = { COMM_GET_VALUES };
    quint16 crc = crc16(payload, 1);
    QByteArray pkt;
    pkt.append(static_cast<char>(VESC_START_BYTE));
    pkt.append(static_cast<char>(0x01));           // length = 1 byte
    pkt.append(static_cast<char>(COMM_GET_VALUES));
    pkt.append(static_cast<char>((crc >> 8) & 0xFF));
    pkt.append(static_cast<char>(crc & 0xFF));
    pkt.append(static_cast<char>(VESC_END_BYTE));
    return pkt;
}

// ───────────────────────────────────────────────────────────────────────────

VescBleClient::VescBleClient(QObject *parent)
    : QObject(parent)
{}

VescBleClient::~VescBleClient()
{
    disconnect();
}

void VescBleClient::setController(VescController *c)
{
    if (m_controller != c) {
        m_controller = c;
        emit controllerChanged();
    }
}

void VescBleClient::setStatus(const QString &s)
{
    if (m_status != s) {
        m_status = s;
        emit statusChanged();
    }
}

void VescBleClient::startScan()
{
    setStatus(QStringLiteral("Skanowanie…"));
    m_foundDevices.clear();
    emit foundDevicesChanged();

#ifdef HAVE_LIBSIMPLEBM
    // libsimplebm scan — results arrive via callback registered during init.
    // See libsimplebm documentation / examples for exact API.
    simplebm_start_scan(m_bleHandle);
#else
    qWarning() << "libsimplebm not available — BLE scan skipped.";
    setStatus(QStringLiteral("Brak libsimplebm"));
#endif
}

void VescBleClient::stopScan()
{
#ifdef HAVE_LIBSIMPLEBM
    simplebm_stop_scan(m_bleHandle);
#endif
    setStatus(QStringLiteral("Skanowanie zatrzymane"));
}

void VescBleClient::connectToDevice(const QString &deviceAddress)
{
    setStatus(QStringLiteral("Łączenie…"));

#ifdef HAVE_LIBSIMPLEBM
    simplebm_connect(m_bleHandle, deviceAddress.toStdString().c_str());
#else
    Q_UNUSED(deviceAddress)
    setStatus(QStringLiteral("Brak libsimplebm"));
#endif
}

void VescBleClient::disconnect()
{
    if (m_connected) {
#ifdef HAVE_LIBSIMPLEBM
        simplebm_disconnect(m_bleHandle);
#endif
        m_connected = false;
        setStatus(QStringLiteral("Rozłączono"));
    }
}

// ── Packet parsing ─────────────────────────────────────────────────────────

double VescBleClient::readFloat32(const QByteArray &data, int offset)
{
    if (offset + 4 > data.size()) return 0.0;
    quint32 raw;
    std::memcpy(&raw, data.constData() + offset, 4);
    raw = qFromBigEndian(raw);
    float f;
    std::memcpy(&f, &raw, 4);
    return static_cast<double>(f);
}

qint32 VescBleClient::readInt32(const QByteArray &data, int offset)
{
    if (offset + 4 > data.size()) return 0;
    qint32 raw;
    std::memcpy(&raw, data.constData() + offset, 4);
    return qFromBigEndian(raw);
}

void VescBleClient::parsePacket(const QByteArray &data)
{
    // Minimal framing check
    if (data.size() < 6) return;
    if (static_cast<quint8>(data[0]) != VESC_START_BYTE) return;
    if (static_cast<quint8>(data.back()) != VESC_END_BYTE) return;

    const int payloadLen = static_cast<quint8>(data[1]);
    if (data.size() < payloadLen + 4) return;

    // CRC check (bytes [2 .. 1+payloadLen])
    const quint8 *payloadPtr = reinterpret_cast<const quint8 *>(data.constData()) + 2;
    quint16 calcCrc = crc16(payloadPtr, payloadLen);
    quint16 pktCrc  = (static_cast<quint16>(static_cast<quint8>(data[2 + payloadLen])) << 8)
                    |  static_cast<quint16>(static_cast<quint8>(data[3 + payloadLen]));
    if (calcCrc != pktCrc) return;

    const quint8 cmdId = static_cast<quint8>(data[2]);
    if (cmdId != COMM_GET_VALUES) return;

    // Extract payload (skip command byte)
    QByteArray payload = data.mid(3, payloadLen - 1);

    if (!m_controller) return;

    const double tempMos   = static_cast<qint16>(
                                 qFromBigEndian<quint16>(
                                     reinterpret_cast<const quint8 *>(
                                         payload.constData() + OFF_TEMP_MOS))) / 10.0;
    const double tempMotor = static_cast<qint16>(
                                 qFromBigEndian<quint16>(
                                     reinterpret_cast<const quint8 *>(
                                         payload.constData() + OFF_TEMP_MOTOR))) / 10.0;
    const double iMotor    = readFloat32(payload, OFF_I_MOTOR);
    const double iInput    = readFloat32(payload, OFF_I_INPUT);
    const double vInput    = readFloat32(payload, OFF_V_INPUT);
    const double duty      = static_cast<qint16>(
                                 qFromBigEndian<quint16>(
                                     reinterpret_cast<const quint8 *>(
                                         payload.constData() + OFF_DUTY))) / 1000.0;
    const double erpmVal   = static_cast<double>(readInt32(payload, OFF_ERPM));
    const double ah        = readFloat32(payload, OFF_AH);
    const double wh        = readFloat32(payload, OFF_WH);
    const int    fault     = static_cast<quint8>(payload.value(OFF_FAULT, 0));

    m_controller->updateTelemetry(erpmVal, vInput, iMotor, iInput,
                                  duty, ah, wh, tempMos, tempMotor, fault);
}
