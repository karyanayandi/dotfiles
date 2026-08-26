import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false
    property var icons: []
    Process {
        id: load
        command: ["sh","-c",
            "F=$HOME/.cache/quickshell/nerdfonts.json; " +
            "if [ ! -s \"$F\" ]; then mkdir -p \"$(dirname \"$F\")\"; " +
            "curl -fsSL https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json 2>/dev/null" +
            " | python3 $HOME/.config/quickshell/scripts/nerdfonts.py > \"$F\"; fi; " +
            "cat \"$F\" 2>/dev/null || echo '[]'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let v = JSON.parse(data.trim());
                    if (Array.isArray(v) && v.length) root.icons = v;
                } catch(e) {}
            }
        }
    }
}
