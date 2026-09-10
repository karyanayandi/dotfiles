import QtQuick
import QtTest

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

    function init() {
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
        editor.tool = "text";
        findChild(editor, "annotationText").text = "Literal <text>";
        editor.apply("text");
        compare(service.requestData.options.text, "Literal <text>");
        compare(service.requestData.options.fontSize, 28);
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
