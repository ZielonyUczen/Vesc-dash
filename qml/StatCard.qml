import QtQuick

/**
 * Simple stat card — shows a label and a large value string.
 *
 * Properties:
 *   label   – descriptor text (small, muted)
 *   value   – pre-formatted value string
 *   unit    – optional unit appended in muted colour
 *   warning – when true the card border turns red
 */
Rectangle {
    id: root

    property string label:   ""
    property string value:   "–"
    property string unit:    ""
    property bool   warning: false

    implicitWidth:  130
    implicitHeight: 60
    radius: 10
    color:  "#111e2e"
    border.color: warning ? "#f44336" : "transparent"
    border.width: 1

    Column {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 2

        Text {
            text: root.label
            color: "#8899aa"
            font.pixelSize: 10
        }
        Row {
            spacing: 3
            Text {
                text: root.value
                color: "white"
                font { pixelSize: 18; bold: true }
            }
            Text {
                text: root.unit
                color: "#8899aa"
                font.pixelSize: 11
                anchors.bottom: parent.bottom
                bottomPadding: 2
            }
        }
    }
}
