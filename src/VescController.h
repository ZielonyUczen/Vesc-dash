#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

/**
 * VescController – QML-exposed C++ object that holds live telemetry data
 * and exposes the eRPM → speed calculation for the BBS02B drivetrain.
 *
 * Hardware constants (BBS02B, Marketbase 75200 V2):
 *   polePairs        = 8
 *   motorGearRatio   = 21.9   (motor shaft : crank)
 *   frontTeeth       = 40
 *   rearTeeth        = 22     (default; user-configurable)
 *   wheelCircumference = 2.155 m  (26" wheel)
 */
class VescController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // ── Drivetrain config ────────────────────────────────────────────────
    Q_PROPERTY(int    polePairs          READ polePairs          WRITE setPolePairs          NOTIFY configChanged)
    Q_PROPERTY(double motorGearRatio     READ motorGearRatio     WRITE setMotorGearRatio     NOTIFY configChanged)
    Q_PROPERTY(int    frontTeeth        READ frontTeeth         WRITE setFrontTeeth         NOTIFY configChanged)
    Q_PROPERTY(int    rearTeeth         READ rearTeeth          WRITE setRearTeeth          NOTIFY configChanged)
    Q_PROPERTY(double wheelCircumference READ wheelCircumference WRITE setWheelCircumference NOTIFY configChanged)

    // ── Live telemetry (read-only from QML) ─────────────────────────────
    Q_PROPERTY(double speedKmh      READ speedKmh      NOTIFY telemetryChanged)
    Q_PROPERTY(double voltage       READ voltage       NOTIFY telemetryChanged)
    Q_PROPERTY(double currentMotor  READ currentMotor  NOTIFY telemetryChanged)
    Q_PROPERTY(double currentInput  READ currentInput  NOTIFY telemetryChanged)
    Q_PROPERTY(double dutyCycle     READ dutyCycle     NOTIFY telemetryChanged)
    Q_PROPERTY(double powerW        READ powerW        NOTIFY telemetryChanged)
    Q_PROPERTY(double erpm          READ erpm          NOTIFY telemetryChanged)
    Q_PROPERTY(double ampHours      READ ampHours      NOTIFY telemetryChanged)
    Q_PROPERTY(double wattHours     READ wattHours     NOTIFY telemetryChanged)
    Q_PROPERTY(double tempMosfet    READ tempMosfet    NOTIFY telemetryChanged)
    Q_PROPERTY(double tempMotor     READ tempMotor     NOTIFY telemetryChanged)
    Q_PROPERTY(int    faultCode     READ faultCode     NOTIFY telemetryChanged)
    Q_PROPERTY(QString faultLabel   READ faultLabel    NOTIFY telemetryChanged)

public:
    explicit VescController(QObject *parent = nullptr);

    // Config getters
    int    polePairs()          const { return m_polePairs; }
    double motorGearRatio()     const { return m_motorGearRatio; }
    int    frontTeeth()         const { return m_frontTeeth; }
    int    rearTeeth()          const { return m_rearTeeth; }
    double wheelCircumference() const { return m_wheelCircumference; }

    // Config setters
    void setPolePairs(int v);
    void setMotorGearRatio(double v);
    void setFrontTeeth(int v);
    void setRearTeeth(int v);
    void setWheelCircumference(double v);

    // Telemetry getters
    double  speedKmh()      const { return m_speedKmh; }
    double  voltage()       const { return m_voltage; }
    double  currentMotor()  const { return m_currentMotor; }
    double  currentInput()  const { return m_currentInput; }
    double  dutyCycle()     const { return m_dutyCycle; }
    double  powerW()        const { return m_voltage * m_currentInput; }
    double  erpm()          const { return m_erpm; }
    double  ampHours()      const { return m_ampHours; }
    double  wattHours()     const { return m_wattHours; }
    double  tempMosfet()    const { return m_tempMosfet; }
    double  tempMotor()     const { return m_tempMotor; }
    int     faultCode()     const { return m_faultCode; }
    QString faultLabel()    const;

    /** Called by VescBleClient when a new RT data packet arrives. */
    Q_INVOKABLE void updateTelemetry(double erpm,
                                     double voltage,
                                     double currentMotor,
                                     double currentInput,
                                     double dutyCycle,
                                     double ampHours,
                                     double wattHours,
                                     double tempMosfet,
                                     double tempMotor,
                                     int    faultCode);

    /** Utility: compute km/h from arbitrary eRPM using current config. */
    Q_INVOKABLE double erpmToSpeedKmh(double erpm) const;

signals:
    void configChanged();
    void telemetryChanged();

private:
    // Config (defaults for BBS02B / 75200 V2 setup)
    int    m_polePairs          { 8 };
    double m_motorGearRatio     { 21.9 };
    int    m_frontTeeth         { 40 };
    int    m_rearTeeth          { 22 };
    double m_wheelCircumference { 2.155 };

    // Telemetry
    double m_speedKmh      { 0 };
    double m_voltage       { 0 };
    double m_currentMotor  { 0 };
    double m_currentInput  { 0 };
    double m_dutyCycle     { 0 };
    double m_erpm          { 0 };
    double m_ampHours      { 0 };
    double m_wattHours     { 0 };
    double m_tempMosfet    { 0 };
    double m_tempMotor     { 0 };
    int    m_faultCode     { 0 };

    void recalcSpeed();
};
