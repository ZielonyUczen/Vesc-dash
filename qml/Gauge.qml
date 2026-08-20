import QtQuick
import QtQuick.Shapes

/**
 * Arc gauge component.
 *
 * Properties:
 *   value     – current value
 *   maxValue  – full-scale value
 *   label     – text below gauge
 *   unit      – unit string inside gauge
 *   arcColor  – colour of the active arc
 *   decimals  – decimal places for the value text
 */
Item {
    id: root

    property double value:    0
    property double maxValue: 100
    property string label:    ""
    property string unit:     ""
    property color  arcColor: "#00d4ff"
    property int    decimals: 1

    implicitWidth:  140
    implicitHeight: 140

    readonly property double _pct: Math.min(1.0, Math.max(0.0, value / maxValue))

    // Arc geometry: 270° span, starting at 135°
    readonly property double _startAngle:   135
    readonly property double _sweepTotal:   270
    readonly property double _sweepActive:  _sweepTotal * _pct
    readonly property double _r:            (Math.min(width, height) / 2) - 10
    readonly property double _cx:           width  / 2
    readonly property double _cy:           height / 2

    // Background arc (static)
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor:  "#1e2a3a"
            strokeWidth:  10
            fillColor:    "transparent"
            capStyle:     ShapePath.RoundCap
            PathAngleArc {
                centerX:      root._cx
                centerY:      root._cy
                radiusX:      root._r
                radiusY:      root._r
                startAngle:   root._startAngle
                sweepAngle:   root._sweepTotal
            }
        }
    }

    // Active arc
    Shape {
        anchors.fill: parent
        ShapePath {
            id: activePath
            strokeColor:  root.arcColor
            strokeWidth:  10
            fillColor:    "transparent"
            capStyle:     ShapePath.RoundCap
            PathAngleArc {
                centerX:    root._cx
                centerY:    root._cy
                radiusX:    root._r
                radiusY:    root._r
                startAngle: root._startAngle
                sweepAngle: root._sweepActive

                Behavior on sweepAngle {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    // Value text
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: -8 }
        text: root.value.toFixed(root.decimals)
        color: "white"
        font { pixelSize: Math.max(14, root.width * 0.14); bold: true }
    }

    // Unit text
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: 10 }
        text: root.unit
        color: "#8899aa"
        font.pixelSize: Math.max(9, root.width * 0.09)
    }

    // Label below
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
        text: root.label
        color: "#8899aa"
        font.pixelSize: Math.max(9, root.width * 0.09)
    }
}
