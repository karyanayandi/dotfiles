pragma Singleton
import QtQuick

QtObject {
    // layout
    property int barHeight: 38
    property int barMinWidth: 400
    property int barMaxWidth: 900
    property int barRadius: 10
    property int barBottomMargin: 10
    property int barSideMargin: 12
    property int barExclusiveZone: 48

    // osd
    property int osdWidth: 200
    property int osdHeight: 176
    property int osdHideMs: 1800
    property int osdRadius: 18

    // notifications
    property int popupWidth: 400
    property int popupTtlLow: 2000
    property int popupTtlNormal: 4000
    property int popupTtlCritical: 6000
    property int centerWidth: 420
    property int centerMaxHeight: 720

    // launcher
    property int launcherWidth: 680
    property int launcherMaxHeight: 560
    property int launcherRadius: 20
    property int launcherInputHeight: 56

    // animations (ms)
    property int animFast: 120
    property int animNormal: 200
    property int animSlow: 360
}
