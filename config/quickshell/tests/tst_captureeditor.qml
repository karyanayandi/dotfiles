import QtQuick
import QtTest
import ".." as Modules

TestCase {
    id: test
    name: "CaptureEditor"
    when: windowShown
    visible: true
    width: 640
    height: 900

    QtObject {
        id: service
        property bool ready: true
        property bool busy: false
        property bool canUndo: false
        property bool recording: false
        property bool windowSupported: true
        property int elapsed: 0
        property string action: ""
        property string message: ""
        property bool hasResult: false
        property var sources: []
        property var tools: ({
                magick: true
            })
        property string preview: "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100"><rect width="200" height="100" fill="white"/></svg>')
        property var requestData: null
        signal feedback(string text, bool failed)
        function request(action, options) {
            requestData = {
                action: action,
                options: options
            };
            return true;
        }
    }

    CaptureEditor {
        id: editor
        width: 620
        height: 800
        service: service
    }

    Modules.CapturePanel {
        id: panel
        width: 1100
        height: 800
        opened: false
        service: service
    }

    function test_workspace() {
        panel.opened = true;
        wait(50);
        verify(panel.editing);
        const image = findChild(panel, "annotationPreview");
        verify(image.width > 640);
        verify(image.height > 250);
        const save = findChild(panel, "captureStart");
        verify(save.mapToItem(panel, 0, save.height).y <= panel.height);
        verify(!panel.expanded);
        panel.width = 960;
        panel.height = 760;
        wait(50);
        verify(image.height > 250);
        verify(save.mapToItem(panel, 0, save.height).y <= panel.height);
        panel.configuring = true;
        verify(!panel.editing);
        panel.configuring = false;
        panel.video = true;
        verify(!panel.editing);
        panel.video = false;
        panel.opened = false;
    }

    function test_zoom() {
        const image = findChild(editor, "annotationPreview");
        const width = image.width;
        editor.zoom = 2;
        wait(20);
        compare(image.width, width * 2);
        const point = editor.pixelPoint(image.width / 2, image.height / 2);
        compare(point.x, 100);
        compare(point.y, 50);
        editor.tool = "pan";
        verify(findChild(editor, "annotationViewport").interactive);
        verify(!findChild(editor, "annotationCanvas").enabled);
        editor.zoom = 1 / editor.fitScale;
        wait(20);
        compare(image.width, 200);
    }

    function init() {
        editor.zoom = 1;
        service.busy = false;
        service.requestData = null;
        editor.tool = "rectangle";
        editor.points = [];
        tryCompare(findChild(editor, "annotationPreview"), "status", Image.Ready);
    }

    function test_draw_data() {
        return [
            {
                tag: "marker",
                tool: "marker"
            },
            {
                tag: "arrow",
                tool: "arrow"
            }
        ];
    }

    function test_draw(data) {
        editor.tool = data.tool;
        const canvas = findChild(editor, "annotationCanvas");
        mousePress(canvas, canvas.width * 0.3, canvas.height * 0.45);
        mouseMove(canvas, canvas.width * 0.5, canvas.height * 0.5);
        verify(editor.points.length >= 2);
        compare(service.requestData, null);
        mouseRelease(canvas, canvas.width * 0.7, canvas.height * 0.55);
        compare(service.requestData.action, "edit");
        compare(service.requestData.options.operation, data.tool);
        verify(service.requestData.options.points.length >= 2);
        for (const point of service.requestData.options.points) {
            verify(point[0] >= 0 && point[0] < 200);
            verify(point[1] >= 0 && point[1] < 100);
        }
    }

    function test_text() {
        mouseClick(findChild(editor, "annotationTool_text"));
        const field = findChild(editor, "annotationText");
        const canvas = findChild(editor, "annotationCanvas");
        verify(!field.enabled);
        for (let i = 0; i < 2; i++) {
            const x = canvas.width * (0.1 + i * 0.4);
            const y = canvas.height * 0.2;
            const location = editor.pixelPoint(x, y);
            mouseDrag(canvas, x, y, canvas.width * 0.1, canvas.height * 0.1);
            tryCompare(field, "activeFocus", true);
            verify(field.enabled);
            compare(field.text, "");
            for (const character of "Literal <text>")
                keyClick(character);
            if (i === 0)
                mouseClick(findChild(editor, "applyAnnotation"));
            else
                keyClick(Qt.Key_Return);
            compare(service.requestData.options.text, "Literal <text>");
            compare(service.requestData.options.fontSize, 28);
            verify(Math.abs(service.requestData.options.x - location.x) <= 1);
            verify(Math.abs(service.requestData.options.y - location.y) <= 1);
            verify(editor.textPending);
            // The worker publishes a new preview only after the label is baked in.
            service.previewChanged();
            verify(!editor.textPending);
            verify(!editor.textPlaced);
            compare(field.text, "");
        }
    }

    function test_busyBlocksDrawing() {
        editor.tool = "marker";
        service.busy = true;
        const canvas = findChild(editor, "annotationCanvas");
        mouseDrag(canvas, 20, 20, 40, 40);
        compare(service.requestData, null);
    }

    function test_failureClearsStroke() {
        editor.points = [[1, 1], [20, 20]];
        service.feedback("Edit failed", true);
        compare(editor.points.length, 0);
    }
}
