import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "panels"

Panel {
    id: root

    property date today: new Date()

    title: "Calendar"
    icon: "\uf073"
    ipcTarget: "calendarPanel"

    CalendarModel {
        id: calendar
    }

    Timer {
        interval: 30000
        running: root.opened
        repeat: true
        triggeredOnStart: true
        onTriggered: root.today = new Date()
    }

    RowLayout {
        Layout.fillWidth: true

        PanelButton {
            glyph: "\uf104"
            Accessible.name: "Previous month"
            ToolTip.visible: hovered || visualFocus
            ToolTip.text: Accessible.name
            onClicked: calendar.moveMonth(-1)
        }

        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(calendar.month, "MMMM yyyy")
            color: Theme.colFg
            font.family: Theme.fontUi
            font.pixelSize: 18
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }

        PanelButton {
            glyph: "\uf105"
            Accessible.name: "Next month"
            ToolTip.visible: hovered || visualFocus
            ToolTip.text: Accessible.name
            onClicked: calendar.moveMonth(1)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 4
        rowSpacing: 4

        Repeater {
            model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

            Text {
                required property string modelData

                Layout.fillWidth: true
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.weight: Font.Medium
                text: modelData
                color: Theme.colFgDim
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Repeater {
            id: days

            model: 42

            PanelButton {
                id: day

                required property int index
                readonly property date date: calendar.dayAt(index)

                function move(delta) {
                    calendar.moveDays(delta);
                    Qt.callLater(() => {
                        for (let i = 0; i < days.count; i++) {
                            const button = days.itemAt(i);
                            if (button.checked)
                                button.forceActiveFocus();
                        }
                    });
                }

                Layout.fillWidth: true
                Layout.preferredWidth: 0
                implicitWidth: 40
                text: date.getDate() + (date.toDateString() === root.today.toDateString() ? "•" : "")
                checked: date.toDateString() === calendar.selected.toDateString()
                opacity: date.getMonth() === calendar.month.getMonth() || checked || visualFocus ? 1 : 0.5
                activeFocusOnTab: checked
                Accessible.name: Qt.formatDate(date, "dddd, d MMMM yyyy") + (date.toDateString() === root.today.toDateString() ? ", today" : "")
                onClicked: calendar.selected = date
                Keys.onLeftPressed: move(-1)
                Keys.onRightPressed: move(1)
                Keys.onUpPressed: move(-7)
                Keys.onDownPressed: move(7)
            }
        }
    }

    PanelButton {
        text: "Today"
        glyph: "\uf133"
        onClicked: calendar.selected = new Date()
    }

    Text {
        Layout.fillWidth: true
        font.family: Theme.fontUi
        text: Qt.formatDate(calendar.selected, "dddd, d MMMM yyyy")
        color: Theme.colFgDim
        wrapMode: Text.WordWrap
    }
}
