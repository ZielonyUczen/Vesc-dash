#include <QtTest>
#include "VescController.h"

/**
 * Unit tests for VescController – speed calculation and telemetry updates.
 *
 * Hardware constants under test (BBS02B / Marketbase 75200 V2 defaults):
 *   polePairs        = 8
 *   motorGearRatio   = 21.9
 *   frontTeeth       = 40
 *   rearTeeth        = 22
 *   wheelCircumference = 2.155 m
 */
class TestVescController : public QObject
{
    Q_OBJECT

private slots:
    void test_zeroErpmReturnsZeroSpeed()
    {
        VescController c;
        QCOMPARE(c.erpmToSpeedKmh(0.0), 0.0);
    }

    void test_negativeErpmReturnsZeroSpeed()
    {
        VescController c;
        QCOMPARE(c.erpmToSpeedKmh(-5000.0), 0.0);
    }

    void test_knownErpmValue()
    {
        // eRPM=10 000 → mechRPM=1250 → crankRPM≈57.08 → wheelRPM≈103.78 → ~13.41 km/h
        VescController c;
        const double speed = c.erpmToSpeedKmh(10000.0);
        QVERIFY2(qAbs(speed - 13.41) < 0.1,
                 qPrintable(QStringLiteral("Expected ~13.41 km/h, got %1").arg(speed)));
    }

    void test_linearScaling()
    {
        VescController c;
        const double s1 = c.erpmToSpeedKmh(10000.0);
        const double s2 = c.erpmToSpeedKmh(20000.0);
        QVERIFY2(qAbs(s2 - s1 * 2.0) < 1e-6,
                 qPrintable(QStringLiteral("Speed should scale linearly: 2×s1=%1, s2=%2").arg(s1*2).arg(s2)));
    }

    void test_smallerRearSprocketGivesHigherSpeed()
    {
        VescController small;
        small.setRearTeeth(11);

        VescController large;
        large.setRearTeeth(42);

        QVERIFY(small.erpmToSpeedKmh(20000.0) > large.erpmToSpeedKmh(20000.0));
    }

    void test_configChangeRecalcsTelemetrySpeed()
    {
        VescController c;
        // Feed some telemetry
        c.updateTelemetry(20000, 42.0, 10.0, 5.0, 50.0, 0.0, 0.0, 30.0, 35.0, 0);
        const double speedBefore = c.speedKmh();
        QVERIFY(speedBefore > 0);

        // Halve front chainring — speed should halve
        c.setFrontTeeth(20);
        QVERIFY2(qAbs(c.speedKmh() - speedBefore / 2.0) < 0.01,
                 qPrintable(QStringLiteral("Speed should halve when front teeth halved: before=%1 after=%2")
                            .arg(speedBefore).arg(c.speedKmh())));
    }

    void test_faultCodeLabelNoFault()
    {
        VescController c;
        c.updateTelemetry(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        QCOMPARE(c.faultCode(), 0);
        QCOMPARE(c.faultLabel(), QStringLiteral("Brak błędu"));
    }

    void test_powerCalculation()
    {
        VescController c;
        c.updateTelemetry(0, 42.0, 0.0, 10.0, 0, 0, 0, 0, 0, 0);
        QVERIFY2(qAbs(c.powerW() - 420.0) < 1e-6,
                 qPrintable(QStringLiteral("42V × 10A = 420W, got %1").arg(c.powerW())));
    }
};

QTEST_MAIN(TestVescController)
#include "TestVescController.moc"
