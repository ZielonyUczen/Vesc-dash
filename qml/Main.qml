import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VescDash

ApplicationWindow {
    id: root
    width: 800
    height: 480
    visible: true
    title: qsTr("VESC Dash – Marketbase 75200 V2 · BBS02B")
    color: "#0a1120"

    // ── Backend objects ──────────────────────────────────────────────────
    VescController {
        id: vesc
    }

    VescBleClient {
        id: bleClient
        controller: vesc
    }

    // ── Stack: Dashboard / Settings ──────────────────────────────────────
    StackLayout {
        id: stack
        anchors.fill: parent
        currentIndex: 0

        // ── Page 0: Dashboard ────────────────────────────────────────────
        Item {
            ColumnLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 10

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "VESC Dash"
                        font { pixelSize: 22; bold: true }
                        color: "#e8f0fe"
                    }
                    Text {
                        text: "Marketbase 75200 V2 · BBS02B"
                        font.pixelSize: 13
                        color: "#8899aa"
                        leftPadding: 8
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 120; height: 26; radius: 13
                        color: bleClient.connected ? "#00c853"
                             : bleClient.status === qsTr("Łączenie…") ? "#f0a500"
                             : "#f44336"
                        Text {
                            anchors.centerIn: parent
                            text: bleClient.status
                            color: "white"
                            font { pixelSize: 11; bold: true }
                        }
                    }
                    Button {
                        text: "⚙"
                        flat: true
                        font.pixelSize: 18
                        onClicked: stack.currentIndex = 1
                    }
                }

                // Fault banner
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    color: "#f44336"
                    visible: vesc.faultCode !== 0
                    Accessible.role: Accessible.AlertMessage
                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                        text: "⚠  " + vesc.faultLabel
                        color: "white"
                        font { pixelSize: 13; bold: true }
                    }
                }

                // Speed gauge – centred, large
                Gauge {
                    id: speedGauge
                    Layout.alignment: Qt.AlignHCenter
                    width: 220; height: 220
                    value: vesc.speedKmh
                    maxValue: 60
                    label: qsTr("Prędkość")
                    unit: "km/h"
                    arcColor: "#00d4ff"
                    decimals: 1
                }

                // Secondary gauges
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Gauge { value: vesc.voltage;             maxValue: 60;  label: "Napięcie";     unit: "V";   arcColor: "#ffd700"; decimals: 1; Layout.fillWidth: true }
                    Gauge { value: Math.abs(vesc.currentMotor); maxValue: 100; label: "Prąd silnika"; unit: "A";   arcColor: "#ff6b35"; decimals: 1; Layout.fillWidth: true }
                    Gauge { value: vesc.powerW / 1000;       maxValue: 3;   label: "Moc";           unit: "kW";  arcColor: "#00e676"; decimals: 2; Layout.fillWidth: true }
                    Gauge { value: vesc.dutyCycle;           maxValue: 100; label: "Duty cycle";    unit: "%";   arcColor: "#aa80ff"; decimals: 0; Layout.fillWidth: true }
                }

                // Stat cards
                GridLayout {
                    Layout.fillWidth: true
                    columns: 6
                    rowSpacing: 8; columnSpacing: 8
                    StatCard { label: "eRPM";          value: vesc.erpm.toFixed(0);           Layout.fillWidth: true }
                    StatCard { label: "Prąd baterii";  value: vesc.currentInput.toFixed(1);  unit: "A";  Layout.fillWidth: true }
                    StatCard { label: "Zużycie";        value: vesc.wattHours.toFixed(1);     unit: "Wh"; Layout.fillWidth: true }
                    StatCard { label: "Pojemność";      value: vesc.ampHours.toFixed(2);      unit: "Ah"; Layout.fillWidth: true }
                    StatCard { label: "Temp. MOSFET";   value: vesc.tempMosfet.toFixed(1);   unit: "°C"; warning: vesc.tempMosfet > 70; Layout.fillWidth: true }
                    StatCard { label: "Temp. silnika";  value: vesc.tempMotor.toFixed(1);    unit: "°C"; warning: vesc.tempMotor  > 80; Layout.fillWidth: true }
                }
            }
        }

        // ── Page 1: Settings ─────────────────────────────────────────────
        SettingsPage {
            vesc: vesc
            bleClient: bleClient
            onBack: stack.currentIndex = 0
        }
    }
}
