import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../services" as Services

PanelWindow {
    id: win
    property bool visibleLauncher: false
    property string query: ""
    property int selected: 0
    property string mode: "apps" 
    property var audioSvc

    IpcHandler {
        target: "launcher"
        function toggle() { win.visibleLauncher = !win.visibleLauncher; if (win.visibleLauncher) { win.query=""; win.selected=0; Qt.callLater(()=> input.forceActiveFocus()) } }
        function open(arg: string) { let m = arg || "apps"; win.mode = m; win.visibleLauncher=true; win.query=""; win.selected=0; Qt.callLater(()=> input.forceActiveFocus()) }
        function close() { win.visibleLauncher=false }
    }

    visible: visibleLauncher || _opacity > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: visibleLauncher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: cardWrap }

    property real _opacity: visibleLauncher ? 1 : 0
    Behavior on _opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0x1d/255,0x20/255,0x21/255, visibleLauncher?0.34:0)
        opacity: win._opacity
        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: win.visibleLauncher=false; enabled: win.visibleLauncher }
    }

    Item {
        id: cardWrap
        width: Math.min(Config.launcherWidth, parent.width - 48)
        scale: 0.96 + win._opacity * 0.04
        opacity: win._opacity
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: card.implicitHeight

        Rectangle {
            id: card
            width: parent.width
            implicitHeight: col.implicitHeight + 2
            radius: Config.launcherRadius
            color: Theme.colLauncherBg
            border.color: Theme.colLauncherBorder
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 6
                radius: parent.radius
                color: Theme.colShadow
                opacity: 0.55
                z: -1
            }
            ColumnLayout {
                id: col
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Config.launcherInputHeight
                    spacing: 12
                    Layout.leftMargin: 16; Layout.rightMargin: 16

                    Text {
                        text: "\u{f0349}"
                        color: Theme.colMuted
                        font.family: Theme.fontFamily; font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: Theme.colFg
                        selectionColor: Theme.colSelected
                        selectedTextColor: Theme.colBg
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.Normal
                        clip: true
                        focus: true
                        onTextChanged: { win.query = text; win.selected = 0 }
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) { win.visibleLauncher=false; e.accepted=true }
                            else if (e.key === Qt.Key_Down) { let n = (win.mode==="emoji"||win.mode==="nerd") ? gridCols : 1; let max = resultCount()-1; win.selected = Math.min(win.selected+n, max); e.accepted=true }
                            else if (e.key === Qt.Key_Up) { let n = (win.mode==="emoji"||win.mode==="nerd") ? gridCols : 1; win.selected = Math.max(win.selected-n, 0); e.accepted=true }
                            else if (e.key === Qt.Key_Left && (win.mode==="emoji"||win.mode==="nerd")) { win.selected = Math.max(win.selected-1, 0); e.accepted=true }
                            else if (e.key === Qt.Key_Right && (win.mode==="emoji"||win.mode==="nerd")) { win.selected = Math.min(win.selected+1, resultCount()-1); e.accepted=true }
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { triggerSelected(e.modifiers & Qt.ControlModifier); e.accepted=true }
                            else if (e.key === Qt.Key_Tab) { cycleMode(); e.accepted=true }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !parent.text.length
                            text: {
                                if (win.mode==="clipboard") return "Search clipboard\u2026  (autopaste on Enter, copy on Ctrl+Enter)"
                                if (win.mode==="emoji") return "Search emoji\u2026  (e.g. fire, heart)"
                                if (win.mode==="nerd") return "Search Nerd Fonts\u2026"
                                if (win.mode==="bluetooth") return "Bluetooth devices\u2026"
                                if (win.mode==="audio") return "Audio sinks & sources\u2026"
                                return "Search apps, clipboard, emoji\u2026  (Tab to switch mode)"
                            }
                            color: Theme.g19
                            font.pixelSize: win.mode==="emoji" ? 18 : 15
                        }
                    }
                    Text {
                        visible: input.text.length>0
                        text: "\u2715"
                        color: Theme.colMuted; font.pixelSize: 14; font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { input.text=""; input.forceActiveFocus() } }
                    }
                    Text {
                        text: "esc"
                        color: Qt.rgba(0x7c/255,0x6f/255,0x64/255,0.9)
                        font.family: Theme.fontFamily; font.pixelSize: 10
                        visible: !input.text.length
                        Layout.alignment: Qt.AlignVCenter
                        Rectangle { anchors.centerIn: parent; width: parent.width+10; height: parent.height+6; radius: 6; color: Theme.colChipBg; z: -1; border.color: Theme.colBorder; border.width: 1 }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.colBorder; opacity: 0.9 }

                Row {
                    id: chips
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.topMargin: 10; Layout.bottomMargin: 6
                    spacing: 8
                    Repeater {
                        model: [
                            {id:"apps", label:"Apps", icon:"\u{f003b}"},
                            {id:"clipboard", label:"Clipboard", icon:"\u{f0147}"},
                            {id:"emoji", label:"Emoji", icon:"\u{1f600}"},
                            {id:"nerd", label:"Nerd", icon:"\u{f0b10}"},
                            {id:"bluetooth", label:"Bluetooth", icon:"\u{f00af}"},
                            {id:"audio", label:"Audio", icon:"\u{f04c3}"}
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            property bool active: win.mode === modelData.id
                            height: 28; radius: 14
                            color: active ? Theme.colFg : Theme.colChipBg
                            border.color: active ? Theme.colFg : Theme.colBorder
                            border.width: active?0:1
                            scale: ma.pressed ? 0.96 : 1
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: modelData.icon; color: active?Theme.colBg:Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                Text { text: modelData.label; color: active?Theme.colBg:Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: active?Font.DemiBold:Font.Normal }
                            }
                            implicitWidth: chipLabel.implicitWidth + 28
                            Text { id: chipLabel; visible:false; text: modelData.label; font.family: Theme.fontFamily; font.pixelSize: 12 }
                            width: Math.max(64, implicitWidth)

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { win.mode = modelData.id; win.selected=0; input.forceActiveFocus() }
                            }
                        }
                    }
                }

                Item {
                    id: resultsArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 360

                ListView {
                    id: list
                    anchors.fill: parent
                    visible: count>0 && !(win.mode==="emoji" || win.mode==="nerd")
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { }

                    model: filteredModel
                    currentIndex: win.selected
                    highlightMoveDuration: 140
                    highlightMoveVelocity: -1
                    highlight: Rectangle { radius: 10; color: Theme.colHoverAlpha; border.color: Theme.colBorder; border.width: 1 }
                    delegate: Item {
                        width: list.width
                        height: 52
                        required property var modelData
                        required property int index
                        property bool isSel: index === win.selected

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            spacing: 12
                            Rectangle {
                                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                radius: 8
                                color: isSel ? Theme.colFg : Theme.g1
                                border.color: Theme.colBorder; border.width: 1
                                IconImage {
                                    anchors.centerIn: parent
                                    visible: win.mode==="apps" && !!modelData.icon
                                    source: visible ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
                                    implicitWidth: 22; implicitHeight: 22
                                }
                                Image {
                                    anchors.centerIn: parent
                                    visible: win.mode==="clipboard" && !!modelData.img
                                    source: visible ? "file://" + modelData.img : ""
                                    width: 26; height: 26; fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: !(win.mode==="apps" && !!modelData.icon) && !(win.mode==="clipboard" && !!modelData.img)
                                    text: modelData.icon || "\u{f003b}"
                                    color: isSel ? Theme.colBg : Theme.colFg
                                    font.family: win.mode==="emoji" ? "Noto Color Emoji" : Theme.fontFamily; font.pixelSize: win.mode==="emoji" ? 18 : 15
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    text: modelData.title || ""
                                    color: Theme.colFg
                                    font.family: Theme.fontFamily; font.pixelSize: 14
                                    font.weight: isSel?Font.DemiBold:Font.Normal
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.subtitle || ""
                                    color: Theme.g19
                                    font.family: Theme.fontFamily; font.pixelSize: 11
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                    visible: text.length>0
                                }
                            }
                            Text {
                                visible: !!modelData.actionHint
                                text: modelData.actionHint
                                color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.selected = index
                            onClicked: { win.selected=index; triggerSelected(mouse.modifiers & Qt.ControlModifier) }
                        }
                    }
                }

                GridView {
                    id: grid
                    anchors.fill: parent
                    visible: count>0 && (win.mode==="emoji" || win.mode==="nerd")
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { }

                    model: filteredModel
                    currentIndex: win.selected
                    cellWidth: 56
                    cellHeight: 56
                    highlightMoveDuration: 120
                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight
                        required property var modelData
                        required property int index
                        Rectangle {
                            anchors.centerIn: parent
                            width: 48; height: 48
                            radius: 10
                            color: index === win.selected ? Theme.colHoverAlpha : (cellMa.containsMouse ? Theme.colBgSec : "transparent")
                            border.color: index === win.selected ? Theme.colBorderStrong : "transparent"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: Theme.colFg
                                font.family: win.mode==="emoji" ? "Noto Color Emoji" : Theme.fontFamily
                                font.pixelSize: win.mode==="emoji" ? 26 : 22
                            }
                            MouseArea {
                                id: cellMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.selected = index
                                onClicked: { win.selected = index; triggerSelected(mouse.modifiers & Qt.ControlModifier) }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: resultsArea
                    visible: resultCount()===0
                    text: win.mode==="clipboard" ? "No clipboard history yet \u2014 copy something" : win.mode==="bluetooth" ? "No devices \u2014 press Scan" : "No results"
                    color: Theme.g19; font.family: Theme.fontFamily; font.pixelSize: 12
                }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 14; Layout.rightMargin: 14
                    Layout.topMargin: 8; Layout.bottomMargin: 10
                    spacing: 12
                    Text { text: "\u21B5 select"; color: Theme.g18; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    Text { text: "\u21E7\u21B5 copy"; color: Theme.g18; font.family: Theme.fontFamily; font.pixelSize: 10; visible: win.mode==="clipboard"||win.mode==="emoji"||win.mode==="nerd" }
                    Text { text: "tab mode"; color: Theme.g18; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    Text { text: "esc close"; color: Theme.g18; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        visible: win.mode==="bluetooth"
                        height: 24; radius: 8
                        color: btSvc.scanning ? Theme.colHoverAlpha : Theme.colChipBg
                        border.color: Theme.colBorder; border.width: 1
                        implicitWidth: btLabel.implicitWidth + 20
                        Text { id: btLabel; anchors.centerIn: parent; text: btSvc.scanning ? "Scanning\u2026" : "Scan"; color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btSvc.scan() }
                    }
                    Rectangle {
                        visible: win.mode==="bluetooth"
                        height: 24; radius: 8
                        color: btSvc.powered ? Theme.g7 : Theme.colChipBg
                        border.color: Theme.colBorder; border.width: 1
                        implicitWidth: pwLabel.implicitWidth + 20
                        Text { id: pwLabel; anchors.centerIn: parent; text: btSvc.powered ? "BT On" : "BT Off"; color: btSvc.powered?Theme.colBg:Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btSvc.togglePower() }
                    }
                    Rectangle {
                        visible: win.mode==="clipboard"
                        height: 24; radius: 8
                        color: Theme.colChipBg; border.color: Theme.colBorder; border.width: 1
                        implicitWidth: clrLabel.implicitWidth + 20
                        Text { id: clrLabel; anchors.centerIn: parent; text: "Clear"; color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: clipSvc.clear() }
                    }
                }
            }
        }
    }

    Services.ClipboardService { id: clipSvc }
    Services.BluetoothService { id: btSvc }
    Services.EmojiService { id: emojiSvc }
    Services.NerdFontService { id: nerdSvc }

    property var appsModel: []
    readonly property int gridCols: Math.max(1, Math.floor((Config.launcherWidth - 24) / 56))
    function resultCount() { return (win.mode==="emoji" || win.mode==="nerd") ? grid.count : list.count }
    function refreshApps() {
        appsModel = DesktopEntries.applications.values.filter(e => !e.noDisplay && e.execString).map(e => ({
            title: e.name || e.id,
            subtitle: (e.execString || "").split(" ")[0].replace(/^.*\//, ""),
            icon: e.icon || "",
            entry: e,
            actionHint: "\u21B5"
        }));
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: if (win.appsModel.length === 0) win.refreshApps() }
    property var filteredModel: {
        let q = win.query.toLowerCase().trim();
        let m = win.mode;
        let grid = (m==="emoji" || m==="nerd");
        let limit = grid ? 300 : 200;
        function score(s, q){
            if (!q) return 1;
            s=s.toLowerCase();
            if (s===q) return 100;
            if (s.startsWith(q)) return 50;
            if (s.includes(q)) return 10;
            let j=0; for(let c of q){ let i=s.indexOf(c,j); if(i===-1) return 0; j=i+1; }
            return 1;
        }
        if (m==="apps") {
            let arr = win.appsModel.map(function(a){ let b={}; for(let k in a) b[k]=a[k]; b._s = score(a.title,q)+score(a.exec||"",q)*0.5; return b; }).filter(function(a){ return !q || a._s>0 });
            arr.sort(function(a,b){ return b._s - a._s });
            return arr.slice(0,limit);
        }
        if (m==="clipboard") {
            let arr = clipSvc.history.map((h,i)=> ({
                img: h.img || "",
                title: h.img ? "\u{1f5bc} Image" : (h.preview||h.text).slice(0,72) + (h.text.length>72?"\u2026":""),
                subtitle: new Date(h.time).toLocaleTimeString() + " \u00B7 " + (h.img ? "image" : h.text.length + " chars"),
                icon: h.img ? "" : "\u{f0147}", text: h.text, idx: i, actionHint: "\u21B5 paste"
            }));
            if (q) arr = arr.filter(x=> x.img ? true : x.text.toLowerCase().includes(q));
            return arr.slice(0,limit);
        }
        if (m==="emoji") {
            let arr = emojiSvc.emojis.map(x=> ({ title: x.e + "  " + x.n, subtitle: x.n, icon: x.e, text: x.e, actionHint:"\u21B5 paste"}));
            if (q) arr = arr.filter(x=> x.title.toLowerCase().includes(q) || x.subtitle.includes(q));
            return arr.slice(0,limit);
        }
        if (m==="nerd") {
            let arr = nerdSvc.icons.map(x=> ({ title: x.c + "  " + x.n, subtitle: x.k + " \u00B7 " + x.n, icon: x.c, text: x.c, actionHint:"\u21B5 paste"}));
            if (q) arr = arr.filter(x=> x.n.toLowerCase().includes(q) || x.k.includes(q));
            return arr.slice(0,limit);
        }
        if (m==="bluetooth") {
            let arr = btSvc.devices.map(d=> ({
                title: d.name, subtitle: d.addr + (d.connected?" \u00B7 connected":""), icon: "\u{f00af}",
                addr: d.addr, connected: d.connected, actionHint: d.connected?"disconnect":"connect"
            }));
            if (q) arr = arr.filter(x=> x.title.toLowerCase().includes(q));
            arr.sort((a,b)=> (b.connected?1:0) - (a.connected?1:0));
            if (!q) arr.unshift({ title: btSvc.powered?"Bluetooth On":"Bluetooth Off", subtitle: "Toggle power", icon: "\u{f00af}", _action:"power", actionHint:"toggle"});
            return arr.slice(0,limit);
        }
        if (m==="audio") {
            let out=[];
            for (let d of audioDevices) out.push(d);
            if (q) out = out.filter(x=> x.title.toLowerCase().includes(q));
            return out.slice(0,limit);
        }
        return [];
    }

    property var audioDevices: []
    Process {
        id: audioPoll
        command: ["sh","-c", "wpctl status 2>/dev/null | awk '/Sinks:/,/Sources:/{print}' | head -n 40; echo '---'; pactl list short sinks 2>/dev/null | head -n 20"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let lines=data.split("\\n");
                let devs=[];
                let inSinks=false;
                for(let l of lines){
                    if(l.includes("Sinks:")) {inSinks=true; continue}
                    if(l.includes("Sources:")||l.includes("---")) {inSinks=false; if(l.includes("---")) break; continue}
                    let m=l.match(new RegExp("\\*?\\s*([0-9]+)\\.\\s*(.+?)\\s*\\[vol:"));
                    if(m && inSinks) devs.push({ title: m[2].trim(), subtitle: "Sink \u00B7 " + m[1], icon:"\u{f04c3}", pid: m[1], kind:"sink", actionHint:"set default"});
                    let m2=l.match(new RegExp("\\*?\\s*([0-9]+)\\.\\s*(.+?)\\s*\\[vol:"));
                    if(m2 && !inSinks && l.includes("vol:")) devs.push({ title: m2[2].trim(), subtitle:"Source \u00B7 "+m2[1], icon:"\uF130", pid: m2[1], kind:"source", actionHint:"set default"});
                }
                if(devs.length) win.audioDevices = devs;
            }
        }
    }
    Timer { interval: 4000; running: win.visibleLauncher && win.mode==="audio"; repeat: true; onTriggered: audioPoll.running=true }

    function cycleMode(){
        let order=["apps","clipboard","emoji","nerd","bluetooth","audio"];
        let i=order.indexOf(win.mode);
        win.mode = order[(i+1)%order.length];
        win.selected=0;
    }
    function triggerSelected(ctrl){
        let m = win.filteredModel[win.selected];
        if(!m) return;
        let mode = win.mode;
        if(mode==="apps"){
            if(m.entry && m.entry.execute) m.entry.execute();
            else { let p=Qt.createQmlObject('import Quickshell.Io; Process {}', win); p.command=["sh","-c",(m.exec||"")+" >/dev/null 2>&1 & disown"]; p.running=true; }
            win.visibleLauncher=false;
        } else if(mode==="clipboard"){
            if(m.img) { clipSvc.copyFile(m.img); }
            else if(ctrl) clipSvc.copy(m.text);
            else clipSvc.autopaste(m.text);
            win.visibleLauncher=false;
        } else if(mode==="emoji"||mode==="nerd"){
            if(ctrl) { let pp=Qt.createQmlObject('import Quickshell.Io; Process {}', win); pp.command=["sh","-c","printf %s '" + m.text.replace(/'/g,"'\\\\''") + "' | wl-copy"]; pp.running=true; }
            else { let pp=Qt.createQmlObject('import Quickshell.Io; Process {}', win); pp.command=["sh","-c","printf %s '" + m.text.replace(/'/g,"'\\\\''") + "' | wl-copy; sleep 0.12; if command -v wtype >/dev/null 2>&1; then wtype -- '" + m.text.replace(/'/g,"'\\\\''") + "' 2>/dev/null; fi"]; pp.running=true; }
            win.visibleLauncher=false;
        } else if(mode==="bluetooth"){
            if(m._action==="power") btSvc.togglePower();
            else if(m.connected) btSvc.disconnect(m.addr);
            else btSvc.connect(m.addr);
        } else if(mode==="audio"){
            let pp=Qt.createQmlObject('import Quickshell.Io; Process {}', win);
            pp.command=["sh","-c","wpctl set-default " + m.pid + " 2>/dev/null || pactl set-default-sink " + m.pid + " 2>/dev/null"];
            pp.running=true;
            win.visibleLauncher=false;
        }
    }

    onVisibleLauncherChanged: if(visibleLauncher) { Qt.callLater(()=> input.forceActiveFocus()); refreshApps(); if(mode==="audio") audioPoll.running=true; if(mode==="bluetooth") btSvc.refresh(); }
}
