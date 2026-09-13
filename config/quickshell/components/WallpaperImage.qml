import ".."
import QtQuick

Item {
    id: root

    property url source
    readonly property bool transitioning: fade.running
    readonly property url displayedSource: back.source

    // Keep the old image opaque until its replacement has decoded and faded in.
    // Fast selections coalesce to the latest source while the current fade finishes.
    function loadLatest() {
        if (!fade.running && source !== back.source)
            front.source = source;

    }

    function present() {
        if (front.status !== Image.Ready)
            return ;

        if (!back.source.toString() || Config.reducedMotion)
            finish();
        else
            fade.start();
    }

    function finish() {
        back.source = front.source;
        front.opacity = 0;
        Qt.callLater(loadLatest);
    }

    onSourceChanged: loadLatest()

    Connections {
        function onReducedMotionChanged() {
            if (Config.reducedMotion && fade.running) {
                fade.stop();
                root.finish();
            }
        }

        target: Config
    }

    Image {
        id: back

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        cache: true
    }

    Image {
        id: front

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: 0
        onStatusChanged: root.present()
    }

    NumberAnimation {
        id: fade

        target: front
        property: "opacity"
        from: 0
        to: 1
        duration: Config.animNormal
        easing.type: Easing.InOutQuad
        onFinished: root.finish()
    }

}
