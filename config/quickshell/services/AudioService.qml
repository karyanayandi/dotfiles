import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Item {
    id: svc
    visible: false

    property var sink: Pipewire.defaultAudioSink
    property real vol: 0.3
    property bool muted: false
    property real prevVol: 0.3
    property bool prevMuted: false
    property bool _synced: false

    property bool osdVisible: false
    property string osdKind: "sink"
    property string osdIcon: ""
    property int osdPercent: 30

    readonly property string volumeIcon: {
        var s = svc.sink;
        var m = svc.muted || (s && s.audio ? s.audio.muted : false);
        var v = svc.vol;
        if (m)
            return "󰸈";
        var d = s && s.description ? s.description : "";
        var n = s && s.properties ? (s.properties["node.name"] || "") : "";
        var lowerD = d.toLowerCase();
        var lowerN = n.toLowerCase();
        if (lowerD.indexOf("headphone") !== -1 || lowerN.indexOf("headphone") !== -1)
            return "󰋋";
        if (v <= 0.01)
            return "";
        if (v < 0.2)
            return "";
        if (v < 0.4)
            return "";
        if (v < 0.8)
            return "󰕾";
        return "";
    }

    Timer {
        id: osdHide
        interval: 1800
        onTriggered: svc.osdVisible = false
    }
    function showOsd(kind) {
        svc.osdKind = kind || "sink";
        var m = svc.muted;
        var v = svc.vol;
        if (svc.sink && svc.sink.audio && svc.sink.audio.muted)
            m = true;
        svc.osdPercent = Math.round(v * 100);
        if (kind === "mic")
            svc.osdIcon = m ? "" : "";
        else {
            if (m)
                svc.osdIcon = "󰸈";
            else if (v <= 0.01)
                svc.osdIcon = "";
            else if (v < 0.34)
                svc.osdIcon = "";
            else if (v < 0.67)
                svc.osdIcon = "󰕾";
            else
                svc.osdIcon = "";
        }
        svc.osdVisible = true;
        osdHide.restart();
    }

    Process {
        id: volRaiseProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+", "-l", "1.0"]
    }
    Process {
        id: volLowerProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
    }
    Process {
        id: volMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }
    Process {
        id: micMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }
    Process {
        id: volPoll
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | cut -d' ' -f2; pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q 'yes' && echo mute || echo unmute"]
        stdout: SplitParser {
            onRead: data => {
                if (!data)
                    return;
                data = data.trim();
                if (data === "mute")
                    svc.muted = true;
                else if (data === "unmute")
                    svc.muted = false;
                else {
                    var v = parseFloat(data);
                    if (!isNaN(v))
                        svc.vol = v;
                }
                var volChanged = Math.abs(svc.vol - svc.prevVol) > 0.005;
                var muteChanged = svc.muted !== svc.prevMuted;
                if (volChanged || muteChanged) {
                    var firstSync = !svc._synced;
                    svc.prevVol = svc.vol;
                    svc.prevMuted = svc.muted;
                    svc._synced = true;
                    if (!firstSync)
                        svc.showOsd("sink");
                }
            }
        }
    }
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: volPoll.running = true
        Component.onCompleted: volPoll.running = true
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            if (Pipewire.defaultAudioSink?.audio)
                svc.vol = Pipewire.defaultAudioSink.audio.volume;
        }
        function onMutedChanged() {
            if (Pipewire.defaultAudioSink?.audio)
                svc.muted = Pipewire.defaultAudioSink.audio.muted;
        }
    }
    onSinkChanged: {
        if (svc.sink && svc.sink.audio) {
            svc.vol = svc.sink.audio.volume;
            svc.muted = svc.sink.audio.muted;
        }
    }
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                svc.sink = Pipewire.defaultAudioSink;
                svc.vol = Pipewire.defaultAudioSink.audio.volume;
                svc.muted = Pipewire.defaultAudioSink.audio.muted;
            }
        }
    }

    function volRaise() {
        volRaiseProc.running = true;
        volPoll.running = true;
        showOsd("sink");
        Qt.callLater(() => volPoll.running = true);
    }
    function volLower() {
        volLowerProc.running = true;
        volPoll.running = true;
        showOsd("sink");
        Qt.callLater(() => volPoll.running = true);
    }
    function volMuteToggle() {
        volMuteProc.running = true;
        showOsd("sink");
        Qt.callLater(() => volPoll.running = true);
    }
    function micMuteToggle() {
        micMuteProc.running = true;
        showOsd("mic");
    }
}
