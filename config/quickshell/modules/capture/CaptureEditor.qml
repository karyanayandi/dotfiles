pragma ComponentBehavior: Bound
import "../.."
import "../panels" as Panels
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var service
    property point dragStart: Qt.point(0, 0)
    property string tool: "rectangle"
    property bool textPlaced: false
    property bool textPending: false
    property real zoom: 1
    readonly property real fitScale: preview.sourceSize.width > 0 && preview.sourceSize.height > 0 ? Math.min(viewport.width / preview.sourceSize.width, viewport.height / preview.sourceSize.height) : 1
    property string ink: "#ef4444"
    property var points: []
    readonly property real preferredHeight: 480 + (tool === "text" ? 52 : 0) + (exactBounds.checked ? boundsGrid.implicitHeight + 12 : 0)

    function appendPoint(x, y) {
        const point = pixelPoint(x, y);
        if (tool === "arrow")
            points = [points[0], [point.x, point.y]];
        else if (points.length < 4096)
            points.push([point.x, point.y]);
        stroke.requestPaint();
    }

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
        if (operation === "text" && (!textPlaced || annotationText.text.trim() === ""))
            return;
        const accepted = service.request("edit", {
            "operation": operation,
            "x": xInput.value,
            "y": yInput.value,
            "width": widthInput.value,
            "height": heightInput.value,
            "color": ink,
            "points": points,
            "strokeWidth": sizeInput.value,
            "fontSize": fontSize.value,
            "text": annotationText.text
        });
        if (accepted && operation === "text")
            textPending = true;
    }

    RowLayout {
        Layout.fillWidth: true
        enabled: root.service.ready && !root.service.busy && !!root.service.tools.magick

        Repeater {
            model: ["rectangle", "marker", "arrow", "text", "pan"]

            Panels.PanelButton {
                required property string modelData
                objectName: "annotationTool_" + modelData
                Layout.fillWidth: true
                glyph: modelData === "rectangle" ? "\uf096" : modelData === "marker" ? "\uf040" : modelData === "arrow" ? "\uf178" : modelData === "text" ? "\uf031" : "\uf047"
                Accessible.name: modelData === "rectangle" ? "Select" : modelData === "pan" ? "Move" : modelData.charAt(0).toUpperCase() + modelData.slice(1)
                ToolTip.visible: hovered || activeFocus
                checkable: true
                checked: root.tool === modelData
                onClicked: {
                    root.tool = modelData;
                    root.points = [];
                    stroke.requestPaint();
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        enabled: !root.service.busy
        visible: !!root.service.tools.magick
        spacing: 8

        Repeater {
            model: ["#ef4444", "#facc15", "#22c55e", "#3b82f6", "#ffffff", "#111111"]

            AbstractButton {
                id: swatch
                required property string modelData
                Accessible.name: "Ink " + modelData
                Accessible.role: Accessible.RadioButton
                checkable: true
                checked: root.ink === modelData
                implicitWidth: 30
                implicitHeight: 34
                onClicked: root.ink = modelData
                background: Rectangle {
                    anchors.centerIn: parent
                    width: swatch.down ? 22 : 26
                    height: width
                    radius: width / 2
                    color: swatch.modelData
                    border.width: swatch.checked || swatch.visualFocus ? 3 : 1
                    border.color: swatch.checked || swatch.visualFocus ? Theme.colFg : Theme.colBorder
                    Text {
                        anchors.centerIn: parent
                        text: swatch.checked ? "✓" : ""
                        color: swatch.modelData === "#111111" || swatch.modelData === "#3b82f6" ? "white" : "black"
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
        }
        Label {
            text: "Width"
            color: Theme.colFgDim
        }
        Panels.PanelSpinBox {
            id: sizeInput
            Accessible.name: "Stroke width in pixels"
            from: 1
            to: 64
            value: 6
            Layout.preferredWidth: 120
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.tool === "text"
        enabled: !root.service.busy

        Panels.PanelTextField {
            id: annotationText
            objectName: "annotationText"
            Layout.fillWidth: true
            Accessible.name: "Annotation text"
            enabled: root.textPlaced
            placeholderText: root.textPlaced ? "Type text, then press Enter" : "Drag on the image to place text first"
            maximumLength: 500
            onAccepted: {
                if (root.service.ready && !root.service.busy && !root.textPending)
                    root.apply("text");
            }
        }
        Panels.PanelSpinBox {
            id: fontSize
            Accessible.name: "Text size in pixels"
            from: 8
            to: 144
            value: 28
        }
    }

    Connections {
        target: root.service
        function onPreviewChanged() {
            if (root.textPending) {
                annotationText.clear();
                root.textPlaced = false;
                root.textPending = false;
            }
        }
        function onFeedback(text, failed) {
            if (failed) {
                root.textPending = false;
                root.points = [];
                stroke.requestPaint();
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120
        color: Theme.colInputBg
        radius: 12
        clip: true

        Flickable {
            id: viewport
            objectName: "annotationViewport"
            anchors.fill: parent
            anchors.margins: 8
            contentWidth: Math.max(width, preview.width)
            contentHeight: Math.max(height, preview.height)
            clip: true
            interactive: root.tool === "pan"
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.horizontal: ScrollBar {}
            ScrollBar.vertical: ScrollBar {}

            Image {
                id: preview
                objectName: "annotationPreview"

                width: sourceSize.width * root.fitScale * root.zoom
                height: sourceSize.height * root.fitScale * root.zoom
                x: Math.max(0, (viewport.width - width) / 2)
                y: Math.max(0, (viewport.height - height) / 2)
                source: root.service.preview
                fillMode: Image.PreserveAspectFit
                cache: false
                asynchronous: true
                retainWhileLoading: true
                clip: true
                Accessible.role: Accessible.Graphic
                Accessible.name: "Screenshot preview"
                Accessible.description: "Drag to draw or select. Click to place text. Exact bounds provides keyboard positioning."
                onStatusChanged: {
                    if (status === Image.Ready) {
                        root.points = [];
                        stroke.requestPaint();
                        xInput.value = 0;
                        yInput.value = 0;
                        widthInput.value = sourceSize.width;
                        heightInput.value = sourceSize.height;
                    }
                }

                Rectangle {
                    visible: preview.status === Image.Ready && !!root.service.tools.magick && (root.tool === "rectangle" || (root.tool === "text" && (root.textPlaced || drawingArea.pressed)))
                    x: (preview.width - preview.paintedWidth) / 2 + xInput.value * preview.paintedWidth / Math.max(1, preview.sourceSize.width)
                    y: (preview.height - preview.paintedHeight) / 2 + yInput.value * preview.paintedHeight / Math.max(1, preview.sourceSize.height)
                    width: widthInput.value * preview.paintedWidth / Math.max(1, preview.sourceSize.width)
                    height: heightInput.value * preview.paintedHeight / Math.max(1, preview.sourceSize.height)
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.colChipActive
                }

                Text {
                    visible: root.tool === "text" && root.textPlaced && preview.status === Image.Ready
                    x: (preview.width - preview.paintedWidth) / 2 + xInput.value * preview.paintedWidth / Math.max(1, preview.sourceSize.width)
                    y: (preview.height - preview.paintedHeight) / 2 + yInput.value * preview.paintedHeight / Math.max(1, preview.sourceSize.height)
                    text: annotationText.text
                    textFormat: Text.PlainText
                    color: root.ink
                    font.family: "DejaVu Sans"
                    font.pixelSize: Math.max(1, fontSize.value * preview.paintedWidth / Math.max(1, preview.sourceSize.width))
                }

                Canvas {
                    id: stroke
                    anchors.fill: parent
                    visible: root.points.length > 0
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        if (root.points.length < 2 || preview.paintedWidth <= 0)
                            return;
                        ctx.translate((preview.width - preview.paintedWidth) / 2, (preview.height - preview.paintedHeight) / 2);
                        ctx.scale(preview.paintedWidth / preview.sourceSize.width, preview.paintedHeight / preview.sourceSize.height);
                        ctx.strokeStyle = root.ink;
                        ctx.lineWidth = sizeInput.value;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(root.points[0][0], root.points[0][1]);
                        for (let i = 1; i < root.points.length; i++)
                            ctx.lineTo(root.points[i][0], root.points[i][1]);
                        if (root.tool === "arrow") {
                            const first = root.points[0];
                            const last = root.points[root.points.length - 1];
                            const length = Math.hypot(last[0] - first[0], last[1] - first[1]);
                            if (length > 0) {
                                const ux = (last[0] - first[0]) / length;
                                const uy = (last[1] - first[1]) / length;
                                const head = Math.min(length, Math.max(8, sizeInput.value * 3));
                                for (const side of [-1, 1]) {
                                    ctx.moveTo(last[0], last[1]);
                                    ctx.lineTo(last[0] - head * ux + side * head * uy / 2, last[1] - head * uy - side * head * ux / 2);
                                }
                            }
                        }
                        ctx.stroke();
                    }
                }

                MouseArea {
                    id: drawingArea
                    anchors.fill: parent
                    objectName: "annotationCanvas"
                    enabled: preview.status === Image.Ready && !!root.service.tools.magick && !root.service.busy && root.tool !== "pan"
                    cursorShape: Qt.CrossCursor
                    preventStealing: true
                    onPressed: mouse => {
                        if (mouse.x < (preview.width - preview.paintedWidth) / 2 || mouse.x > (preview.width + preview.paintedWidth) / 2 || mouse.y < (preview.height - preview.paintedHeight) / 2 || mouse.y > (preview.height + preview.paintedHeight) / 2) {
                            mouse.accepted = false;
                            return;
                        }
                        root.dragStart = root.pixelPoint(mouse.x, mouse.y);
                        root.selectTo(mouse.x, mouse.y);
                        root.points = [[root.dragStart.x, root.dragStart.y]];
                        stroke.requestPaint();
                    }
                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        if (root.tool === "marker" || root.tool === "arrow")
                            root.appendPoint(mouse.x, mouse.y);
                        else
                            root.selectTo(mouse.x, mouse.y);
                    }
                    onReleased: mouse => {
                        if (root.tool === "marker" || root.tool === "arrow") {
                            root.appendPoint(mouse.x, mouse.y);
                            root.apply(root.tool);
                        } else {
                            root.points = [];
                            stroke.requestPaint();
                            if (root.tool === "text") {
                                root.textPlaced = true;
                                annotationText.forceActiveFocus(Qt.OtherFocusReason);
                            }
                        }
                    }
                    onCanceled: {
                        root.points = [];
                        stroke.requestPaint();
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Panels.PanelButton {
            text: "Fit"
            checkable: true
            checked: root.zoom === 1
            onClicked: root.zoom = 1
        }
        Panels.PanelButton {
            text: "100%"
            enabled: root.fitScale > 0
            onClicked: root.zoom = 1 / root.fitScale
        }
        Panels.PanelButton {
            text: "−"
            Accessible.name: "Zoom out"
            enabled: root.zoom > 1
            onClicked: root.zoom = Math.max(1, root.zoom / 1.25)
        }
        Label {
            text: Math.round(root.fitScale * root.zoom * 100) + "%"
            color: Theme.colFgDim
        }
        Panels.PanelButton {
            text: "+"
            Accessible.name: "Zoom in"
            enabled: root.zoom < Math.max(8, 1 / root.fitScale)
            onClicked: root.zoom = Math.min(Math.max(8, 1 / root.fitScale), root.zoom * 1.25)
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
        Item {
            Layout.fillWidth: true
        }
        Label {
            text: preview.sourceSize.width + " × " + preview.sourceSize.height
            color: Theme.colFgDim
        }
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: !root.service.tools.magick ? "Install ImageMagick to edit screenshots." : root.tool === "pan" ? "Drag to move around the zoomed image." : root.tool === "text" ? (root.textPlaced ? "Type your text, then press Enter or Add text. Drag again to move it before adding." : "Drag on the image to place a new text label. Each added label stays on the screenshot.") : root.tool === "rectangle" ? "Drag to select, then Crop or Mark." : "Drag to draw. Release to apply. Undo restores the previous image."
        color: Theme.colFgDim
    }

    GridLayout {
        id: boundsGrid
        Layout.fillWidth: true
        visible: exactBounds.visible && exactBounds.checked
        enabled: !root.service.busy
        columns: root.width >= 700 ? 4 : 2
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
            visible: root.tool === "rectangle"
            text: "Crop"
            glyph: "\uf125"
            onClicked: root.apply("crop")
        }

        Panels.PanelButton {
            visible: root.tool === "rectangle"
            text: "Outline"
            glyph: "\uf096"
            onClicked: root.apply("rectangle")
        }

        Panels.PanelButton {
            objectName: "applyAnnotation"
            text: root.tool === "text" ? "Add text" : "Draw from bounds"
            visible: root.tool !== "rectangle" && root.tool !== "pan"
            enabled: root.tool !== "text" || (root.textPlaced && !root.textPending && annotationText.text.trim() !== "")
            onClicked: {
                root.points = [[xInput.value, yInput.value], [xInput.value + widthInput.value - 1, yInput.value + heightInput.value - 1]];
                root.apply(root.tool);
            }
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
