import "../.."
import "../panels" as Panels
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var service
    property point dragStart: Qt.point(0, 0)
    readonly property real preferredHeight: 340 + (exactBounds.checked ? boundsGrid.implicitHeight + 12 : 0)

    function pixelPoint(x, y) {
        return Qt.point(Math.max(0, Math.min(preview.sourceSize.width - 1, Math.floor((x - (preview.width - preview.paintedWidth) / 2) * preview.sourceSize.width / preview.paintedWidth))), Math.max(0, Math.min(preview.sourceSize.height - 1, Math.floor((y - (preview.height - preview.paintedHeight) / 2) * preview.sourceSize.height / preview.paintedHeight))));
    }

    function selectTo(x, y) {
        const point = pixelPoint(x, y);
        xInput.value = Math.min(dragStart.x, point.x);
        yInput.value = Math.min(dragStart.y, point.y);
        widthInput.value = Math.abs(point.x - dragStart.x) + 1;
        heightInput.value = Math.abs(point.y - dragStart.y) + 1;
    }

    function apply(operation) {
        service.request("edit", {
            "operation": operation,
            "x": xInput.value,
            "y": yInput.value,
            "width": widthInput.value,
            "height": heightInput.value,
            "color": Theme.colChipActive.toString()
        });
    }

    Image {
        id: preview

        Layout.fillWidth: true
        Layout.fillHeight: true
        source: root.service.preview
        fillMode: Image.PreserveAspectFit
        cache: false
        asynchronous: true
        Accessible.role: Accessible.Graphic
        Accessible.name: "Screenshot preview"
        Accessible.description: "Drag to select. Use Exact bounds for keyboard editing."
        onStatusChanged: {
            if (status === Image.Ready) {
                xInput.value = 0;
                yInput.value = 0;
                widthInput.value = sourceSize.width;
                heightInput.value = sourceSize.height;
            }
        }

        Rectangle {
            visible: preview.status === Image.Ready && !!root.service.tools.magick
            x: (preview.width - preview.paintedWidth) / 2 + xInput.value * preview.paintedWidth / Math.max(1, preview.sourceSize.width)
            y: (preview.height - preview.paintedHeight) / 2 + yInput.value * preview.paintedHeight / Math.max(1, preview.sourceSize.height)
            width: widthInput.value * preview.paintedWidth / Math.max(1, preview.sourceSize.width)
            height: heightInput.value * preview.paintedHeight / Math.max(1, preview.sourceSize.height)
            color: "transparent"
            border.width: 2
            border.color: Theme.colChipActive
        }

        MouseArea {
            anchors.fill: parent
            enabled: preview.status === Image.Ready && !!root.service.tools.magick && !root.service.busy
            cursorShape: Qt.CrossCursor
            onPressed: mouse => {
                root.dragStart = root.pixelPoint(mouse.x, mouse.y);
                root.selectTo(mouse.x, mouse.y);
            }
            onPositionChanged: mouse => {
                if (pressed)
                    root.selectTo(mouse.x, mouse.y);
            }
        }
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: root.service.tools.magick ? "Drag to select" : "Install ImageMagick to crop or mark rectangles."
        color: Theme.colFgDim
    }

    Panels.PanelButton {
        id: exactBounds

        visible: !!root.service.tools.magick
        text: "Exact bounds"
        glyph: checked ? "\uf106" : "\uf107"
        checkable: true
        checked: false
        Accessible.description: checked ? "Hide pixel coordinates" : "Show editable pixel coordinates"
    }

    GridLayout {
        id: boundsGrid
        Layout.fillWidth: true
        visible: exactBounds.visible && exactBounds.checked
        enabled: !root.service.busy
        columns: 2
        columnSpacing: 12
        rowSpacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            spacing: 6
            Label {
                text: "X position"
                color: Theme.colFgDim
                font.pixelSize: 12
            }
            Panels.PanelSpinBox {
                id: xInput
                Layout.fillWidth: true
                from: 0
                to: Math.max(0, preview.sourceSize.width - 1)
                Accessible.name: "Rectangle X"
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            spacing: 6
            Label {
                text: "Y position"
                color: Theme.colFgDim
                font.pixelSize: 12
            }
            Panels.PanelSpinBox {
                id: yInput
                Layout.fillWidth: true
                from: 0
                to: Math.max(0, preview.sourceSize.height - 1)
                Accessible.name: "Rectangle Y"
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            spacing: 6
            Label {
                text: "Width"
                color: Theme.colFgDim
                font.pixelSize: 12
            }
            Panels.PanelSpinBox {
                id: widthInput
                Layout.fillWidth: true
                from: 1
                to: Math.max(1, preview.sourceSize.width - xInput.value)
                value: to
                Accessible.name: "Rectangle width"
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            spacing: 6
            Label {
                text: "Height"
                color: Theme.colFgDim
                font.pixelSize: 12
            }
            Panels.PanelSpinBox {
                id: heightInput
                Layout.fillWidth: true
                from: 1
                to: Math.max(1, preview.sourceSize.height - yInput.value)
                value: to
                Accessible.name: "Rectangle height"
            }
        }
    }

    RowLayout {
        visible: !!root.service.tools.magick
        enabled: root.service.ready && !root.service.busy && preview.status === Image.Ready

        Panels.PanelButton {
            text: "Crop"
            glyph: "\uf125"
            onClicked: root.apply("crop")
        }

        Panels.PanelButton {
            text: "Mark"
            glyph: "\uf096"
            onClicked: root.apply("rectangle")
        }

        Panels.PanelButton {
            glyph: "\uf0e2"
            Accessible.name: "Undo edit"
            ToolTip.text: Accessible.name
            ToolTip.visible: hovered || activeFocus
            ToolTip.delay: 500
            enabled: root.service.canUndo
            onClicked: root.service.request("undo")
        }
    }
}
