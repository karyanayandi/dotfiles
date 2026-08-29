import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false
    property var emojis: []
    Process {
        id: load
        command: ["sh", "-c", "F=$HOME/.cache/quickshell/emoji.json; " + "if [ ! -s \"$F\" ]; then mkdir -p \"$(dirname \"$F\")\"; " + "curl -fsSL https://unicode.org/Public/emoji/15.1/emoji-test.txt 2>/dev/null" + " | python3 $HOME/.config/quickshell/scripts/emoji.py > \"$F\"; fi; " + "cat \"$F\" 2>/dev/null || echo '[]'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let v = JSON.parse(data.trim());
                    if (Array.isArray(v) && v.length)
                        root.emojis = v;
                } catch (e) {}
            }
        }
    }
}
