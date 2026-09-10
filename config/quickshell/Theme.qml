import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    // Keep legacy palette names so every consumer updates through existing bindings.
    property FileView colorsFile
    property color g0: palette.g0
    property color g1: palette.g1
    property color g2: palette.g2
    property color g3: palette.g3
    property color g4: palette.g4
    property color g5: palette.g5
    property color g6: palette.g6
    property color g7: palette.g7
    property color g8: palette.g8
    property color g9: palette.g9
    property color g10: palette.g10
    property color g11: palette.g11
    property color g12: palette.g12
    property color g13: palette.g13
    property color g14: palette.g14
    property color g15: palette.g15
    property color g16: palette.g16
    property color g17: palette.g17
    property color g18: palette.g18
    property color g19: palette.g19
    property color g20: palette.g20
    property color colFg: g5
    property color colFgDim: g4
    property color colBg: g0
    property color colBgAlt: g1
    property color colBgSec: g1
    property color colSelected: g6
    property color colHoverAlpha: Qt.rgba(g3.r, g3.g, g3.b, 0.8)
    property color colHoverSolid: g4
    property color colAccent: g2
    property color colUrgent: g11
    property color colCritical: g11
    property color colBorder: Qt.rgba(g3.r, g3.g, g3.b, 0.45)
    property color colBorderStrong: Qt.rgba(g3.r, g3.g, g3.b, 0.65)
    property color colDndChecked: g10
    property color colActionBg: Qt.rgba(g6.r, g6.g, g6.b, 0.55)
    property color colShadow: Qt.rgba(g0.r, g0.g, g0.b, 0.45)
    property color colMeterBg: Qt.rgba(g2.r, g2.g, g2.b, 0.9)
    property color colMeterFg: g5
    property color colMuted: g4
    property color colBgAlpha095: Qt.rgba(g0.r, g0.g, g0.b, 0.95)
    property color colBgAlpha085: Qt.rgba(g0.r, g0.g, g0.b, 0.85)
    property color colBgAlpha078: Qt.rgba(g0.r, g0.g, g0.b, 0.78)
    property string fontUi: "Adwaita Sans"
    property string fontFamily: "JetBrainsMono NF"
    property color colLauncherBg: Qt.rgba(g0.r, g0.g, g0.b, 0.98)
    property color colLauncherBorder: Qt.rgba(g17.r, g17.g, g17.b, 0.35)
    property color colInputBg: Qt.rgba(g1.r, g1.g, g1.b, 0.65)
    property color colChipBg: Qt.rgba(g2.r, g2.g, g2.b, 0.9)
    property color colChipActive: g6
    property string fontFallback: "Nerd Font"
    property int fontSize: 15

    colorsFile: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: palette

            property string g0: "#1d2021"
            property string g1: "#3c3836"
            property string g2: "#504945"
            property string g3: "#665c54"
            property string g4: "#bdae93"
            property string g5: "#ebdbb2"
            property string g6: "#d5c4a1"
            property string g7: "#8ec07c"
            property string g8: "#689d6a"
            property string g9: "#83a598"
            property string g10: "#458588"
            property string g11: "#fb4934"
            property string g12: "#fe8019"
            property string g13: "#fabd2f"
            property string g14: "#b8bb26"
            property string g15: "#d3869b"
            property string g16: "#282828"
            property string g17: "#7c6f64"
            property string g18: "#928374"
            property string g19: "#a89984"
            property string g20: "#fbf1c7"
        }

    }

}
