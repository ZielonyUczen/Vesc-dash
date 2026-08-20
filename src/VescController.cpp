#include "VescController.h"

#include <QMap>
#include <cmath>

// VESC firmware 7.x fault codes
static const QMap<int, QString> FAULT_CODES = {
    { 0,  QStringLiteral("Brak błędu") },
    { 1,  QStringLiteral("Przepięcie") },
    { 2,  QStringLiteral("Zbyt niskie napięcie") },
    { 3,  QStringLiteral("Błąd DRV") },
    { 4,  QStringLiteral("Przekroczenie prądu ABS") },
    { 5,  QStringLiteral("Przegrzanie MOSFET") },
    { 6,  QStringLiteral("Przegrzanie silnika") },
    { 7,  QStringLiteral("Przepięcie gate driver") },
    { 8,  QStringLiteral("Zbyt niskie napięcie gate driver") },
    { 9,  QStringLiteral("Zbyt niskie napięcie MCU") },
    { 10, QStringLiteral("Reset watchdog") },
    { 11, QStringLiteral("Błąd SPI enkodera") },
    { 14, QStringLiteral("Uszkodzenie flash") },
    { 18, QStringLiteral("Niezbalansowane prądy") },
};

VescController::VescController(QObject *parent)
    : QObject(parent)
{}

void VescController::setPolePairs(int v)
{
    if (v > 0 && v != m_polePairs) {
        m_polePairs = v;
        recalcSpeed();
        emit configChanged();
    }
}

void VescController::setMotorGearRatio(double v)
{
    if (v > 0 && !qFuzzyCompare(v, m_motorGearRatio)) {
        m_motorGearRatio = v;
        recalcSpeed();
        emit configChanged();
    }
}

void VescController::setFrontTeeth(int v)
{
    if (v > 0 && v != m_frontTeeth) {
        m_frontTeeth = v;
        recalcSpeed();
        emit configChanged();
    }
}

void VescController::setRearTeeth(int v)
{
    if (v > 0 && v != m_rearTeeth) {
        m_rearTeeth = v;
        recalcSpeed();
        emit configChanged();
    }
}

void VescController::setWheelCircumference(double v)
{
    if (v > 0 && !qFuzzyCompare(v, m_wheelCircumference)) {
        m_wheelCircumference = v;
        recalcSpeed();
        emit configChanged();
    }
}

void VescController::updateTelemetry(double erpm,
                                     double voltage,
                                     double currentMotor,
                                     double currentInput,
                                     double dutyCycle,
                                     double ampHours,
                                     double wattHours,
                                     double tempMosfet,
                                     double tempMotor,
                                     int    faultCode)
{
    m_erpm         = std::abs(erpm);
    m_voltage      = voltage;
    m_currentMotor = currentMotor;
    m_currentInput = currentInput;
    m_dutyCycle    = dutyCycle;
    m_ampHours     = ampHours;
    m_wattHours    = wattHours;
    m_tempMosfet   = tempMosfet;
    m_tempMotor    = tempMotor;
    m_faultCode    = faultCode;

    recalcSpeed();
    emit telemetryChanged();
}

double VescController::erpmToSpeedKmh(double erpm) const
{
    if (erpm <= 0) return 0.0;
    const double mechanicalRpm = erpm / m_polePairs;
    const double crankRpm      = mechanicalRpm / m_motorGearRatio;
    const double wheelRpm      = crankRpm * (static_cast<double>(m_frontTeeth)
                                             / static_cast<double>(m_rearTeeth));
    return wheelRpm * m_wheelCircumference * 60.0 / 1000.0;
}

QString VescController::faultLabel() const
{
    return FAULT_CODES.value(m_faultCode,
                             QStringLiteral("Kod błędu %1").arg(m_faultCode));
}

void VescController::recalcSpeed()
{
    m_speedKmh = erpmToSpeedKmh(m_erpm);
}
