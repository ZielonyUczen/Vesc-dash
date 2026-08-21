#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class VescController;

/**
 * VescBleClient – thin wrapper around libsimplebm's BLE communication.
 *
 * libsimplebm provides an event-driven API for VESC BLE (Nordic UART Service).
 * This class:
 *  1. Scans for VESC devices advertising the NUS service UUID.
 *  2. Connects and subscribes to the TX characteristic.
 *  3. Parses incoming RT data packets (COMM_GET_VALUES, id 0x04).
 *  4. Calls VescController::updateTelemetry() on each valid packet.
 *
 * Usage from QML:
 *   VescBleClient { id: bleClient; controller: vesc }
 *   bleClient.startScan()
 *   bleClient.connectToDevice(bleClient.foundDevices[0])
 */
class VescBleClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(VescController* controller READ controller WRITE setController NOTIFY controllerChanged)
    Q_PROPERTY(QString status  READ status  NOTIFY statusChanged)
    Q_PROPERTY(QStringList foundDevices READ foundDevices NOTIFY foundDevicesChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY statusChanged)

public:
    explicit VescBleClient(QObject *parent = nullptr);
    ~VescBleClient() override;

    VescController* controller() const { return m_controller; }
    void setController(VescController *c);

    QString     status()       const { return m_status; }
    QStringList foundDevices() const { return m_foundDevices; }
    bool        connected()    const { return m_connected; }

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();
    Q_INVOKABLE void connectToDevice(const QString &deviceAddress);
    Q_INVOKABLE void disconnect();

signals:
    void controllerChanged();
    void statusChanged();
    void foundDevicesChanged();

private:
    void setStatus(const QString &s);
    void parsePacket(const QByteArray &data);

    // Extracts a big-endian float from the packet buffer at offset.
    static double readFloat32(const QByteArray &data, int offset);
    // Extracts a big-endian int32 from the packet buffer at offset.
    static qint32 readInt32(const QByteArray &data, int offset);

    VescController *m_controller  { nullptr };
    QString         m_status      { QStringLiteral("Rozłączono") };
    QStringList     m_foundDevices;
    bool            m_connected   { false };

    // libsimplebm opaque handle – allocated in startScan / freed in destructor
    void *m_bleHandle { nullptr };
};
