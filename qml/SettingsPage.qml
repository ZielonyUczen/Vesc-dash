import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * Settings page – BLE device selection and drivetrain configuration.
 */
Item {
    id: root

    required property var vesc
    required property var bleClient

    signal back()

    Rectangle {
        anchors.fill: parent
        color: "#0a1120"

        ColumnLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 12

            // ── Header ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "←"
                    flat: true
                    font.pixelSize: 18
                    onClicked: root.back()
                }
                Text {
                    text: "⚙  Ustawienia"
                    color: "#e8f0fe"
                    font { pixelSize: 18; bold: true }
                }
            }

            // ── BLE ──────────────────────────────────────────────────────
            Text { text: "POŁĄCZENIE BLE"; color: "#8899aa"; font { pixelSize: 11; letterSpacing: 1 } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Button {
                    text: "Szukaj urządzeń"
                    onClicked: bleClient.startScan()
                }
                Button {
                    text: "Zatrzymaj"
                    onClicked: bleClient.stopScan()
                }
                Button {
                    text: "Rozłącz"
                    enabled: bleClient.connected
                    onClicked: bleClient.disconnect()
                }
            }

            ComboBox {
                id: deviceCombo
                Layout.fillWidth: true
                model: bleClient.foundDevices
                displayText: count > 0 ? currentText : "Brak urządzeń"
            }

            Button {
                text: "Połącz z urządzeniem"
                enabled: deviceCombo.count > 0
                onClicked: bleClient.connectToDevice(deviceCombo.currentText)
            }

            // ── Drivetrain ───────────────────────────────────────────────
            Text { text: "NAPĘD BBS02B"; color: "#8899aa"; font { pixelSize: 11; letterSpacing: 1 }; topPadding: 8 }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8; columnSpacing: 12

                Text { text: "Pary biegunów"; color: "#e8f0fe"; font.pixelSize: 13 }
                SpinBox { value: vesc.polePairs; from: 1; to: 20; onValueModified: vesc.polePairs = value }

                Text { text: "Przełożenie silnika (1:x)"; color: "#e8f0fe"; font.pixelSize: 13 }
                TextField {
                    text: vesc.motorGearRatio.toFixed(1)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onEditingFinished: { const v = parseFloat(text); if (v > 0) vesc.motorGearRatio = v }
                }

                Text { text: "Zębatka przednia (T)"; color: "#e8f0fe"; font.pixelSize: 13 }
                SpinBox { value: vesc.frontTeeth; from: 10; to: 60; onValueModified: vesc.frontTeeth = value }

                Text { text: "Zębatka tylna aktywna (T)"; color: "#e8f0fe"; font.pixelSize: 13 }
                ComboBox {
                    model: [11, 13, 15, 17, 20, 23, 26, 30, 34, 38, 42]
                    currentIndex: model.indexOf(vesc.rearTeeth)
                    onActivated: vesc.rearTeeth = model[currentIndex]
                }

                Text { text: "Obwód koła (m)"; color: "#e8f0fe"; font.pixelSize: 13 }
                TextField {
                    text: vesc.wheelCircumference.toFixed(3)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onEditingFinished: { const v = parseFloat(text); if (v > 0) vesc.wheelCircumference = v }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
