import QtQuick 2.5
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0

Item {
    id: root
    anchors.fill: parent

    // === Ustawienia skalowania i rozmiarów UI ===
    property real uiScale: 1.0
    property int gaugeHeightSetting: 220
    property int gearBarHeightSetting: 70
    property int gridTileHeightSetting: 50

    property var mCommands: VescIf.commands()
    property var mMcConf: VescIf.mcConfig()

    readonly property real wheelDiameterM: 0.710
    readonly property real wheelCircumferenceM: Math.PI * wheelDiameterM
    readonly property real internalRatio: 20.04
    readonly property int polePairs: 8
    readonly property int frontChainring: 40
    readonly property var rearTeeth: [46, 37, 32, 28, 24, 21, 18, 15, 13, 11]
    readonly property int gearCount: 10

    property int currentGear: 1
    property int page: 0

    property bool telemetryValid: false
    property bool voltageValid: false
    property bool rpmValid: false
    property bool batteryCurrentValid: false
    property bool motorCurrentValid: false
    property bool dutyValid: false
    property bool tempMosValid: false
    property bool tempMotorValid: false
    property bool maxErpmValid: false
    property bool fluxValid: false

    property real batteryVoltage: 0
    property real batteryCurrent: 0
    property real motorCurrent: 0
    property real duty: 0
    property real motorErpm: 0
    property real speedKmh: 0
    property real tempMos: 0
    property real tempMotor: 0
    property real inputPowerKw: 0
    property bool regenActive: false

    property real configuredMaxErpm: 0
    property real voltageLimitedErpm: 0
    property real effectiveMaxErpm: 0
    property string connectionText: "DISCONNECTED"
    property string lastUpdateText: "—"

    property var statMaxSpeed: [0,0,0,0,0,0,0,0]
    property var statMaxErpm: [0,0,0,0,0,0,0,0]
    property var statMinVoltage: [0,0,0,0,0,0,0,0]
    property var statMaxBatteryCurrent: [0,0,0,0,0,0,0,0]
    property var statMaxMotorCurrent: [0,0,0,0,0,0,0,0]
    property var statSeen: [false,false,false,false,false,false,false,false]
    property int statsGeneration: 0

    function validNumber(v) {
        return typeof v === "number" && isFinite(v)
    }

    function safeParam(name, fallback) {
        if (!mMcConf || typeof mMcConf.getParamDouble !== "function")
            return fallback
        try {
            var value = mMcConf.getParamDouble(name)
            return validNumber(value) ? value : fallback
        } catch (e) {
            return fallback
        }
    }

    function clampGearIndex(index) {
        return Math.max(0, Math.min(gearCount - 1, Math.round(Number(index))))
    }

    function speedFromErpm(erpm, gearIndex) {
        if (!validNumber(erpm))
            return NaN
        var teeth = rearTeeth[clampGearIndex(gearIndex)]
        if (!validNumber(teeth) || teeth <= 0)
            return NaN
        var mechanicalRpm = erpm / polePairs
        var crankRpm = mechanicalRpm / internalRatio
        var wheelRpm = crankRpm * frontChainring / teeth
        return wheelRpm * wheelCircumferenceM * 60.0 / 1000.0
    }

    function erpmForSpeed(speed, gearIndex) {
        if (!validNumber(speed))
            return NaN
        var teeth = rearTeeth[clampGearIndex(gearIndex)]
        if (!validNumber(teeth) || teeth <= 0)
            return NaN
        var wheelRpm = speed * 1000.0 / (wheelCircumferenceM * 60.0)
        var crankRpm = wheelRpm * teeth / frontChainring
        return crankRpm * internalRatio * polePairs
    }

    function theoreticalMaxSpeed(gearIndex) {
        if (!maxErpmValid || effectiveMaxErpm <= 0)
            return NaN
        return speedFromErpm(effectiveMaxErpm, gearIndex)
    }

    function computeVoltageLimitedErpm(voltage) {
        var flux = safeParam("foc_motor_flux_linkage", 0)
        fluxValid = flux > 0
        if (!validNumber(voltage) || voltage <= 0 || !fluxValid)
            return 0
        return voltage * 60.0 / (Math.sqrt(3.0) * 2.0 * Math.PI * flux)
    }

    function computeEffectiveMaxErpm() {
        var cfg = safeParam("l_max_erpm", 0)
        configuredMaxErpm = cfg > 0 ? cfg : 0
        maxErpmValid = configuredMaxErpm > 0
        voltageLimitedErpm = voltageValid ? computeVoltageLimitedErpm(batteryVoltage) : 0

        if (maxErpmValid && voltageLimitedErpm > 0)
            effectiveMaxErpm = Math.min(configuredMaxErpm, voltageLimitedErpm)
        else if (maxErpmValid)
            effectiveMaxErpm = configuredMaxErpm
        else
            effectiveMaxErpm = voltageLimitedErpm

        if (!validNumber(effectiveMaxErpm) || effectiveMaxErpm <= 0)
            effectiveMaxErpm = 0
    }

    function setGear(g) {
        currentGear = Math.max(1, Math.min(gearCount, Math.round(Number(g))))
        if (rpmValid)
            speedKmh = speedFromErpm(motorErpm, currentGear - 1)
    }

    function requestValues() {
        if (!mCommands || typeof mCommands.getValues !== "function")
            return false
        try {
            mCommands.getValues()
            return true
        } catch (e) {
            return false
        }
    }

    function refreshConnection() {
        var connected = false
        try {
            connected = !!VescIf.isPortConnected()
        } catch (e) {
            connected = false
        }
        connectionText = connected ? "CONNECTED" : "DISCONNECTED"
        return connected
    }

    function resetStats() {
        statMaxSpeed = [0,0,0,0,0,0,0,0]
        statMaxErpm = [0,0,0,0,0,0,0,0]
        statMinVoltage = [0,0,0,0,0,0,0,0]
        statMaxBatteryCurrent = [0,0,0,0,0,0,0,0]
        statMaxMotorCurrent = [0,0,0,0,0,0,0,0]
        statSeen = [false,false,false,false,false,false,false,false]
        statsGeneration++
    }

    function updateStats() {
        if (!telemetryValid)
            return

        var idx = currentGear - 1
        if (idx < 0 || idx >= gearCount)
            return

        var speeds = statMaxSpeed.slice(0)
        var erpms = statMaxErpm.slice(0)
        var mins = statMinVoltage.slice(0)
        var batt = statMaxBatteryCurrent.slice(0)
        var motor = statMaxMotorCurrent.slice(0)
        var seen = statSeen.slice(0)

        var speed = rpmValid ? Math.abs(speedKmh) : NaN
        var erpm = rpmValid ? Math.abs(motorErpm) : NaN
        var voltage = voltageValid ? batteryVoltage : NaN
        var iBatt = batteryCurrentValid ? Math.max(0, batteryCurrent) : NaN
        var iMotor = motorCurrentValid ? Math.abs(motorCurrent) : NaN

        if (!seen[idx]) {
            seen[idx] = true
            speeds[idx] = validNumber(speed) ? speed : 0
            erpms[idx] = validNumber(erpm) ? erpm : 0
            mins[idx] = validNumber(voltage) ? voltage : 0
            batt[idx] = validNumber(iBatt) ? iBatt : 0
            motor[idx] = validNumber(iMotor) ? iMotor : 0
        } else {
            if (validNumber(speed)) speeds[idx] = Math.max(speeds[idx], speed)
            if (validNumber(erpm)) erpms[idx] = Math.max(erpms[idx], erpm)
            if (validNumber(voltage))
                mins[idx] = mins[idx] > 0 ? Math.min(mins[idx], voltage) : voltage
            if (validNumber(iBatt)) batt[idx] = Math.max(batt[idx], iBatt)
            if (validNumber(iMotor)) motor[idx] = Math.max(motor[idx], iMotor)
        }

        statMaxSpeed = speeds
        statMaxErpm = erpms
        statMinVoltage = mins
        statMaxBatteryCurrent = batt
        statMaxMotorCurrent = motor
        statSeen = seen
        statsGeneration++
    }

    function erpmStatusRatio() {
        if (!rpmValid || effectiveMaxErpm <= 0)
            return 0
        return Math.max(0, Math.min(1.2, Math.abs(motorErpm) / effectiveMaxErpm))
    }

    function erpmStatusText() {
        if (!rpmValid)
            return "NO eRPM"
        if (effectiveMaxErpm <= 0)
            return "NO LIMIT"
        var ratio = erpmStatusRatio()
        if (ratio >= 1.0) return "LIMIT — SHIFT GEAR"
        if (ratio >= 0.92) return "WARNING — SHIFT GEAR"
        if (ratio >= 0.82) return "APPROACHING LIMIT"
        return "RANGE OK"
    }

    function erpmStatusColor() {
        if (!rpmValid || effectiveMaxErpm <= 0)
            return "#718096"
        var ratio = erpmStatusRatio()
        if (ratio >= 1.0) return "#ff4056"
        if (ratio >= 0.92) return "#ff7a00"
        if (ratio >= 0.82) return "#ffd000"
        return "#61ff3d"
    }

    function formatValue(v, digits, unit) {
        return validNumber(v) ? Number(v).toFixed(digits) + unit : "—"
    }

    function formatInt(v) {
        return validNumber(v) ? Math.round(v).toString() : "—"
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: {
            if (root.refreshConnection()) {
                root.requestValues()
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            root.lastUpdateText = Qt.formatDateTime(new Date(), "hh:mm:ss")
        }
    }

    Component.onCompleted: {
        root.refreshConnection()
        root.computeEffectiveMaxErpm()
        root.lastUpdateText = Qt.formatDateTime(new Date(), "hh:mm:ss")
    }

    Connections {
        target: mCommands

        function onValuesReceived(values, mask) {
    console.log(
        "TELEMETRY:",
        "V=" + values.v_in,
        "Ibat=" + values.current_in,
        "Imotor=" + values.current_motor,
        "RPM=" + values.rpm,
        "Duty=" + values.duty_now,
        "MOS=" + values.temp_mos,
        "MotorTemp=" + values.temp_motor
    )

    if (!values)
        return

    // reszta Twojego kodu...

            if (!values)
                return

            var vIn = values.v_in
            var iIn = values.current_in
            var iMotor = values.current_motor
            var erpm = values.rpm
            var dutyNow = values.duty_now
            var tm = values.temp_mos
            var tMotor = values.temp_motor

            root.voltageValid = root.validNumber(vIn)
            root.rpmValid = root.validNumber(erpm)
            root.batteryCurrentValid = root.validNumber(iIn)
            root.motorCurrentValid = root.validNumber(iMotor)
            root.dutyValid = root.validNumber(dutyNow)
            root.tempMosValid = root.validNumber(tm)
            root.tempMotorValid = root.validNumber(tMotor)

            if (!root.rpmValid) {
                root.telemetryValid = false
                return
            }

            root.telemetryValid = true
            root.batteryVoltage = root.voltageValid ? vIn : 0
            root.batteryCurrent = root.batteryCurrentValid ? iIn : 0
            root.motorCurrent = root.motorCurrentValid ? iMotor : 0
            root.motorErpm = erpm
            root.duty = root.dutyValid ? dutyNow * 100.0 : 0
            root.tempMos = root.tempMosValid ? tm : 0
            root.tempMotor = root.tempMotorValid ? tMotor : 0
            root.inputPowerKw = root.voltageValid && root.batteryCurrentValid ? root.batteryVoltage * root.batteryCurrent / 1000.0 : NaN
            root.regenActive = root.batteryCurrentValid && root.batteryCurrent < -0.5

            root.computeEffectiveMaxErpm()
            root.speedKmh = root.speedFromErpm(root.motorErpm, root.currentGear - 1)
            root.lastUpdateText = Qt.formatDateTime(new Date(), "hh:mm:ss")
            root.updateStats()
        }
    }

    Rectangle { anchors.fill: parent; color: "#05080c" }

    // Główny kontener wspierający skalowanie UI Scale
    Item {
        id: scaledContainer
        anchors.fill: parent
        transform: Scale {
            origin.x: scaledContainer.width / 2
            origin.y: scaledContainer.height / 2
            xScale: root.uiScale
            yScale: root.uiScale
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 9
                color: "#08121a"
                border.width: 1
                border.color: "#153244"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    Text { text: "VESC"; color: "#63ff49"; font.pixelSize: 16; font.bold: true }
                    Text { text: root.connectionText; color: root.connectionText === "CONNECTED" ? "#55ff40" : "#ff4056"; font.pixelSize: 12; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Text { text: "BBS02B • 75200 v2"; color: "#9aa9b7"; font.pixelSize: 12 }
                    Text { text: root.lastUpdateText; color: "#d6e0e8"; font.pixelSize: 12 }
                    
                    Button { 
                        text: root.page === 0 ? "STATS" : (root.page === 1 ? "UI SETTINGS" : "RIDE")
                        onClicked: {
                            if (root.page === 0) root.page = 1
                            else if (root.page === 1) root.page = 2
                            else root.page = 0
                        }
                    }
                }
            }

            StackLayout {
                id: pages
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.page

                // STRONA 0: RIDE DISPLAY
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.gaugeHeightSetting
                            spacing: 8

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Canvas {
                                    anchors.fill: parent
                                    property real value: Math.abs(root.speedKmh)
                                    property real maximum: 100
                                    onValueChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        var cx = width / 2
                                        var cy = height * 0.62
                                        var r = Math.min(width, height) * 0.40
                                        var start = Math.PI * 0.75
                                        var end = Math.PI * 2.25
                                        var ratio = Math.max(0, Math.min(1, value / maximum))
                                        ctx.reset()
                                        ctx.clearRect(0, 0, width, height)
                                        ctx.lineWidth = Math.max(8, r * 0.08)
                                        ctx.strokeStyle = "#172a37"
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, start, end, false)
                                        ctx.stroke()
                                        ctx.strokeStyle = "#11a8ff"
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, start, start + (end - start) * ratio, false)
                                        ctx.stroke()
                                    }
                                }
                                Column {
                                    anchors.centerIn: parent
                                    Text { 
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.rpmValid ? root.formatValue(root.speedKmh,0,"") : "—"
    color: "#f5f9fc"
    font {
        pixelSize: Math.max(30, Math.round(root.gaugeHeightSetting * 0.32))
        bold: true
    }
}
                                    Text { 
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.currentGear + " / " + root.gearCount
    color: "#ffffff"
    font {
        pixelSize: Math.max(16, Math.round(root.gearBarHeightSetting * 0.37))
        bold: true
    }
}
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "GEAR " + root.currentGear + "/" + root.gearCount; color: "#8091a1"; font.pixelSize: Math.max(10, root.gaugeHeightSetting * 0.055) }
                                }
                            }

                            Item {
                                Layout.preferredWidth: 250
                                Layout.fillHeight: true
                                Canvas {
                                    anchors.fill: parent
                                    property real value: Math.abs(root.motorErpm)
                                    property real maximum: Math.max(1, root.effectiveMaxErpm)
                                    property color accent: root.erpmStatusColor()
                                    onValueChanged: requestPaint()
                                    onMaximumChanged: requestPaint()
                                    onAccentChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        var cx = width / 2
                                        var cy = height * 0.55
                                        var r = Math.min(width, height) * 0.39
                                        var start = Math.PI * 0.76
                                        var end = Math.PI * 2.24
                                        var ratio = Math.max(0, Math.min(1, value / maximum))
                                        ctx.reset()
                                        ctx.clearRect(0, 0, width, height)
                                        ctx.lineWidth = Math.max(7, r * 0.08)
                                        ctx.strokeStyle = "#182a1a"
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, start, end, false)
                                        ctx.stroke()
                                        ctx.strokeStyle = accent
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, start, start + (end - start) * ratio, false)
                                        ctx.stroke()
                                    }
                                }
                                Column {
                                    anchors.centerIn: parent
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "eRPM"; color: "#71ff3d"; font.pixelSize: Math.max(12, root.gaugeHeightSetting * 0.07); font.bold: true }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.rpmValid ? root.formatInt(Math.abs(root.motorErpm)) : "—"; color: "#f5f9fc"; font.pixelSize: Math.max(22, root.gaugeHeightSetting * 0.19); font.bold: true }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.erpmStatusText(); color: root.erpmStatusColor(); font.pixelSize: Math.max(9, root.gaugeHeightSetting * 0.045); font.bold: true }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: root.gearBarHeightSetting; radius: 10; color: "#08121a"; border.width: 1; border.color: "#183144"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 8
                                Button { 
                                    Layout.fillWidth: true
                                    text: "−\nGEAR"
                                    onClicked: root.setGear(root.currentGear - 1)
                                }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 8; color: "#0c1d27"; border.width: 1; border.color: "#1c809e"
                                    Column { anchors.centerIn: parent
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.currentGear + " / " + root.gearCount; color: "#ffffff"; font.pixelSize: Math.max(16, root.gearBarHeightSetting * 0.37); font.bold: true }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.rearTeeth[root.currentGear - 1] + "T"; color: "#17b7ff"; font.pixelSize: Math.max(9, root.gearBarHeightSetting * 0.15) }
                                    }
                                }
                                Button { 
                                    Layout.fillWidth: true
                                    text: "+\nGEAR"
                                    onClicked: root.setGear(root.currentGear + 1)
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 10; radius: 5; color: "#101923"
                            Rectangle { width: parent.width * Math.min(1, root.erpmStatusRatio()); height: parent.height; radius: 5; color: root.erpmStatusColor() }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 2
                            rowSpacing: 6
                            columnSpacing: 6

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.gridTileHeightSetting; color: "#071018"; border.width: 1; border.color: "#68ff35"; radius: 8
                                Column { anchors.fill: parent; anchors.margins: 6
                                    Text { text: "BATTERY VOLTAGE"; color: "#8ea0af"; font.pixelSize: 10 }
                                    Text { text: root.voltageValid ? root.formatValue(root.batteryVoltage, 1, " V") : "—"; color: "#68ff35"; font.pixelSize: Math.max(14, root.gridTileHeightSetting * 0.4); font.bold: true }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.gridTileHeightSetting; color: "#071018"; border.width: 1; border.color: "#ffd12d"; radius: 8
                                Column { anchors.fill: parent; anchors.margins: 6
                                    Text { text: "INPUT POWER"; color: "#8ea0af"; font.pixelSize: 10 }
                                    Text { text: root.validNumber(root.inputPowerKw) ? root.formatValue(root.inputPowerKw, 2, " kW") : "—"; color: "#ffd12d"; font.pixelSize: Math.max(14, root.gridTileHeightSetting * 0.4); font.bold: true }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.gridTileHeightSetting; color: "#071018"; border.width: 1; border.color: "#15d9f0"; radius: 8
                                Column { anchors.fill: parent; anchors.margins: 6
                                    Text { text: "BATTERY CURRENT"; color: "#8ea0af"; font.pixelSize: 10 }
                                    Text { text: root.batteryCurrentValid ? root.formatValue(root.batteryCurrent, 1, " A") : "—"; color: "#15d9f0"; font.pixelSize: Math.max(14, root.gridTileHeightSetting * 0.4); font.bold: true }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.gridTileHeightSetting; color: "#071018"; border.width: 1; border.color: "#b867ff"; radius: 8
                                Column { anchors.fill: parent; anchors.margins: 6
                                    Text { text: "MOTOR CURRENT"; color: "#8ea0af"; font.pixelSize: 10 }
                                    Text { text: root.motorCurrentValid ? root.formatValue(root.motorCurrent, 1, " A") : "—"; color: "#b867ff"; font.pixelSize: Math.max(14, root.gridTileHeightSetting * 0.4); font.bold: true }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.gridTileHeightSetting; color: "#071018"; border.width: 1; border.color: "#ff7c1a"; radius: 8
                                Column { anchors.fill: parent; anchors.margins: 6
                                    Text { text: "DUTY CYCLE"; color: "#8ea0af"; font.pixelSize: 10 }
                                    Text { text: root.dutyValid ? root.formatValue(root.duty, 1, " %") : "—"; color: "#ff7c1a"; font.pixelSize: Math.max(14, root.gridTileHeightSetting * 0.4); font.bold: true }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.gridTileHeightSetting; color: "#071018"; border.width: 1; border.color: "#ff5f81"; radius: 8
                                Column { anchors.fill: parent; anchors.margins: 6
                                    Text { text: "REGENERATION"; color: "#8ea0af"; font.pixelSize: 10 }
                                    Text { text: root.batteryCurrentValid ? (root.regenActive ? "ACTIVE" : "OFF") : "—"; color: "#ff5f81"; font.pixelSize: Math.max(14, root.gridTileHeightSetting * 0.4); font.bold: true }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.gridTileHeightSetting; color: "#071018"; border.width: 1; border.color: "#67b5ff"; radius: 8
                                Column { anchors.fill: parent; anchors.margins: 6
                                    Text { text: "MOSFET TEMP."; color: "#8ea0af"; font.pixelSize: 10 }
                                    Text { text: root.tempMosValid ? root.formatValue(root.tempMos, 0, " °C") : "—"; color: "#67b5ff"; font.pixelSize: Math.max(14, root.gridTileHeightSetting * 0.4); font.bold: true }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.gridTileHeightSetting; color: "#071018"; border.width: 1; border.color: "#f29a4a"; radius: 8
                                Column { anchors.fill: parent; anchors.margins: 6
                                    Text { text: "MOTOR TEMP."; color: "#8ea0af"; font.pixelSize: 10 }
                                    Text { text: root.tempMotorValid ? root.formatValue(root.tempMotor, 0, " °C") : "—"; color: "#f29a4a"; font.pixelSize: Math.max(14, root.gridTileHeightSetting * 0.4); font.bold: true }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 8; color: "#071018"
                            RowLayout { anchors.fill: parent; anchors.margins: 8
                                Text { text: root.tempMosValid ? "MOSFET " + root.formatValue(root.tempMos,0," °C") : "MOSFET —"; color: "#8da1b1"; font.pixelSize: 11 }
                                Text { text: root.tempMotorValid ? "MOTOR " + root.formatValue(root.tempMotor,0," °C") : "MOTOR —"; color: "#8da1b1"; font.pixelSize: 11 }
                                Text { text: root.batteryCurrentValid ? (root.regenActive ? "REGEN" : "BRAKE OFF") : "BRAKE —"; color: "#8da1b1"; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: "CAN " + (root.connectionText === "CONNECTED" ? "OK" : "OFF"); color: root.connectionText === "CONNECTED" ? "#61ff3d" : "#ff4056"; font.pixelSize: 11; font.bold: true }
                            }
                        }
                    }
                }

                // STRONA 1: STATISTICS / PEAKS
                Item {
                    ColumnLayout {
                        anchors.fill: parent; spacing: 8
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 60; color: "#08121a"; radius: 9
                            RowLayout { anchors.fill: parent; anchors.margins: 8
                                Text { Layout.fillWidth: true; text: "SCREEN 2 — STATISTICS / PEAKS"; color: "#eff7fb"; font.pixelSize: 17; font.bold: true }
                                Button { 
                                    text: "RESET"
                                    onClicked: root.resetStats()
                                }
                            }
                        }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 40; color: "#0a1720"; radius: 6
                            RowLayout { anchors.fill: parent; anchors.margins: 4
                                Text { Layout.preferredWidth: 45; text: "GEAR"; color: "#9cafbd"; font.pixelSize: 9; font.bold: true }
                                Text { Layout.preferredWidth: 100; text: "MAX V km/h"; color: "#20b8ff"; font.pixelSize: 9; font.bold: true }
                                Text { Layout.preferredWidth: 90; text: "MAX eRPM"; color: "#75ff39"; font.pixelSize: 9; font.bold: true }
                                Text { Layout.preferredWidth: 100; text: "MIN V"; color: "#ffd13a"; font.pixelSize: 9; font.bold: true }
                                Text { Layout.preferredWidth: 110; text: "MAX I BATT"; color: "#1cd9ef"; font.pixelSize: 9; font.bold: true }
                                Text { Layout.fillWidth: true; text: "MAX I MOTOR"; color: "#c177ff"; font.pixelSize: 9; font.bold: true }
                            }
                        }
                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: root.gearCount; spacing: 2
                            delegate: Rectangle {
                                width: ListView.view ? ListView.view.width : 0; height: 44; radius: 5
                                color: (index + 1) === root.currentGear ? "#102639" : "#071018"
                                RowLayout { anchors.fill: parent; anchors.margins: 5
                                    Text { Layout.preferredWidth: 45; text: index + 1; color: "#ffffff"; font.pixelSize: 14; font.bold: true }
                                    Text { Layout.preferredWidth: 100; text: root.statSeen[index] ? root.formatValue(root.statMaxSpeed[index],1,"") : "—"; color: "#2ebeff"; font.pixelSize: 13 }
                                    Text { Layout.preferredWidth: 90; text: root.statSeen[index] && root.statMaxErpm[index] > 0 ? root.formatInt(root.statMaxErpm[index]) : "—"; color: "#79ff43"; font.pixelSize: 13 }
                                    Text { Layout.preferredWidth: 100; text: root.statSeen[index] && root.statMinVoltage[index] > 0 ? root.formatValue(root.statMinVoltage[index],1,"") : "—"; color: "#ffd33e"; font.pixelSize: 13 }
                                    Text { Layout.preferredWidth: 110; text: root.statSeen[index] ? root.formatValue(root.statMaxBatteryCurrent[index],1,"") : "—"; color: "#20dff0"; font.pixelSize: 13 }
                                    Text { Layout.fillWidth: true; text: root.statSeen[index] ? root.formatValue(root.statMaxMotorCurrent[index],1,"") : "—"; color: "#c477ff"; font.pixelSize: 13 }
                                }
                            }
                        }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 52; color: "#071018"; radius: 8
                            Column { anchors.fill: parent; anchors.margins: 7
                                Text { text: "GEAR " + root.currentGear + "/" + root.gearCount + " • " + root.rearTeeth[root.currentGear - 1] + "T • eRPM LIMIT: " + (root.maxErpmValid ? root.formatInt(root.effectiveMaxErpm) : "—"); color: "#e9f1f5"; font.pixelSize: 11; font.bold: true }
                                Text { text: "THEORY @ LIMIT: " + (root.validNumber(root.theoreticalMaxSpeed(root.currentGear - 1)) ? root.formatValue(root.theoreticalMaxSpeed(root.currentGear - 1),1," km/h") : "—"); color: "#7f94a5"; font.pixelSize: 10 }
                            }
                        }
                    }
                }

                // STRONA 2: PANEL USTAWIEN ROZMIARU UI
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            color: "#08121a"
                            radius: 8
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                Text { text: "UI SIZE & LAYOUT CONFIGURATION"; color: "#16b8ff"; font.pixelSize: 16; font.bold: true }
                                Item { Layout.fillWidth: true }
                                Button {
                                    text: "RESET UI"
                                    onClicked: {
                                        root.uiScale = 1.0
                                        root.gaugeHeightSetting = 220
                                        root.gearBarHeightSetting = 70
                                        root.gridTileHeightSetting = 50
                                    }
                                }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ColumnLayout {
                                width: parent.width
                                spacing: 16

                                // Skala Ogólna Interfejsu
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "GLOBAL UI SCALE: " + Number(root.uiScale).toFixed(2) + "x"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 0.7
                                        to: 1.4
                                        stepSize: 0.05
                                        value: root.uiScale
                                        onValueChanged: root.uiScale = value
                                    }
                                }

                                // Wysokość Zegarów (Speedometer & eRPM)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "GAUGES HEIGHT: " + root.gaugeHeightSetting + " px"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 140
                                        to: 350
                                        stepSize: 10
                                        value: root.gaugeHeightSetting
                                        onValueChanged: root.gaugeHeightSetting = Math.round(value)
                                    }
                                }

                                // Wysokość Paska Wyboru Biegu
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "GEAR BAR HEIGHT: " + root.gearBarHeightSetting + " px"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 40
                                        to: 120
                                        stepSize: 5
                                        value: root.gearBarHeightSetting
                                        onValueChanged: root.gearBarHeightSetting = Math.round(value)
                                    }
                                }

                                // Wysokość Kafli Telemetrii
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "TELEMETRY TILE HEIGHT: " + root.gridTileHeightSetting + " px"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 35
                                        to: 90
                                        stepSize: 5
                                        value: root.gridTileHeightSetting
                                        onValueChanged: root.gridTileHeightSetting = Math.round(value)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
