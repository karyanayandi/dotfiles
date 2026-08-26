import QtQuick

QtObject {
    // gruvbox palette
    property color g0: "#1d2021"
    property color g1: "#32302f"
    property color g2: "#45403d"
    property color g3: "#5a524c"
    property color g4: "#bdae93"
    property color g5: "#ebdbb2"
    property color g6: "#d5c4a1"
    property color g7: "#8ec07c"
    property color g8: "#689d6a"
    property color g9: "#83a598"
    property color g10: "#458588"
    property color g11: "#fb4934"
    property color g12: "#fe8019"
    property color g13: "#fabd2f"
    property color g14: "#b8bb26"
    property color g15: "#d3869b"
    property color colFg: g5
    property color colBg: g0
    property color colBgAlt: g1
    property color colBgSec: g1
    property color colSelected: g6
    property color colHoverAlpha: Qt.rgba(0x5a/255, 0x52/255, 0x4c/255, 0.8)
    property color colHoverSolid: g4
    property color colAccent: g2
    property color colUrgent: g11
    property color colCritical: g11
    property color colBorder: g0
    property color colDndChecked: g10
    property color colActionBg: Qt.rgba(0xd5/255, 0xc4/255, 0xa1/255, 0.6)
    property color colBgAlpha095: Qt.rgba(0x1d/255, 0x20/255, 0x21/255, 1.0)
    property color colBgAlpha085: Qt.rgba(0x1d/255, 0x20/255, 0x21/255, 0.95)
    property string fontFamily: "JetBrainsMono NFM"
    property string fontFallback: "Nerd Font"
    property int fontSize: 15
}
