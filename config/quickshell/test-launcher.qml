import "modules/launcher"
// Run: QT_QPA_PLATFORM=offscreen quickshell -p config/quickshell/test-launcher.qml
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int step: 0

    FloatingWindow {
        visible: true
        implicitWidth: 640
        implicitHeight: 400

        Results {
            id: results

            anchors.fill: parent
        }

    }

    Timer {
        interval: 30
        running: true
        repeat: true
        onTriggered: {
            const list = results.children[0];
            const grid = results.children[1];
            const active = results.valueGrid ? grid : list;
            const inactive = results.valueGrid ? list : grid;
            if (active.count !== results.model.length || inactive.count !== 0)
                throw new Error("Wrong active delegate count");

            if (results.model.length && (!active.itemAtIndex(0) || active.itemAtIndex(0).modelData.title !== results.model[0].title))
                throw new Error("Stale delegate data");

            if (++root.step > 100) {
                console.log("PASS: launcher list/grid replacement, shrink and empty models");
                Qt.quit();
                return ;
            }
            const kind = root.step % 4 < 2 ? "app" : "emoji";
            results.model = Array.from({
                "length": root.step % 5 === 0 ? 0 : 20
            }, (_, index) => {
                return ({
                    "kind": kind,
                    "title": root.step + ":" + index,
                    "text": "x",
                    "icon": ""
                });
            });
        }
    }

}
