import "../.."
import "../../components" as Comp
import QtQml.Models
import QtQuick
import QtQuick.Controls
import Quickshell.Services.Notifications

Item {
    id: root

    required property var notifs
    property real maxHeight: 500
    property var hoveredNotification: null
    readonly property real naturalHeight: {
        let total = Math.max(0, cardRepeater.count - 1) * cards.spacing;
        for (let i = 0; i < cardRepeater.count; ++i) {
            const card = cardRepeater.itemAt(i);
            if (card)
                total += Math.min(260, card.implicitHeight);
        }
        return total;
    }
    readonly property bool needsOverflow: naturalHeight > maxHeight
    readonly property real overflowHeight: needsOverflow ? Math.min(54, maxHeight) : 0
    readonly property var layout: {
        let count = 0;
        let used = 0;
        const available = Math.max(0, maxHeight - overflowHeight - (needsOverflow ? 8 : 0));
        for (let i = 0; i < cardRepeater.count; ++i) {
            const card = cardRepeater.itemAt(i);
            if (!card)
                continue;
            const next = used + (count ? cards.spacing : 0) + card.height;
            if (next > available || card.height <= 0)
                break;
            used = next;
            ++count;
        }
        return { count: count, used: used };
    }
    readonly property int visibleCount: layout.count
    readonly property int overflowCount: notifs.popups.length - visibleCount

    function syncTimers() {
        const popups = notifs.popups;
        for (let i = pending.count - 1; i >= 0; --i) {
            if (popups.indexOf(pending.get(i).notification) === -1)
                pending.remove(i);
        }
        for (const notification of popups) {
            let found = false;
            for (let i = 0; i < pending.count; ++i) {
                if (pending.get(i).notification === notification) {
                    found = true;
                    break;
                }
            }
            if (!found)
                pending.append({ "notification": notification });
        }
    }

    implicitWidth: Config.popupWidth
    implicitHeight: layout.used + (overflowCount ? overflowHeight + (visibleCount ? 8 : 0) : 0)
    clip: true
    Component.onCompleted: syncTimers()
    onNotifsChanged: syncTimers()

    Connections {
        target: root.notifs
        function onPopupsChanged() { root.syncTimers(); }
    }

    ListModel { id: pending }

    Instantiator {
        model: pending
        delegate: QtObject {
            id: expiry
            required property var notification
            property int remaining: Math.min(Config.popupTtlNormal, notification.urgency === NotificationUrgency.Low ? Config.popupTtlLow : Config.popupTtlNormal, notification.expireTimeout > 0 ? notification.expireTimeout : Config.popupTtlNormal)
            property double started: 0
            property bool paused: root.visible && root.hoveredNotification === notification
            property Timer timer: Timer {
                interval: Math.max(1, expiry.remaining)
                onTriggered: root.notifs.removePopup(expiry.notification)
            }
            function updateTimer() {
                if (paused) {
                    if (timer.running) {
                        remaining = Math.max(1, remaining - (Date.now() - started));
                        timer.stop();
                    }
                } else if (!timer.running) {
                    started = Date.now();
                    timer.start();
                }
            }
            onPausedChanged: updateTimer()
            Component.onCompleted: updateTimer()
        }
    }

    Column {
        id: cards
        width: parent.width
        spacing: 8

        Repeater {
            id: cardRepeater
            model: root.notifs.popups.slice().reverse()
            delegate: Flickable {
                id: card
                required property var modelData
                required property int index
                readonly property var notification: modelData
                objectName: "popup-" + notification.summary
                width: cards.width
                implicitHeight: popupContent.implicitHeight
                height: Math.min(260, implicitHeight, Math.max(0, root.maxHeight - root.overflowHeight - (root.needsOverflow ? 8 : 0)))
                contentWidth: width
                contentHeight: popupContent.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                opacity: index < root.visibleCount ? 1 : 0
                enabled: opacity > 0
                clip: true

                Comp.NotificationCard {
                    id: popupContent
                    width: card.width
                    height: implicitHeight
                    notification: card.notification
                    imgSize: 32
                    cardRadius: Theme.radiusPanel
                    cardBg: Theme.colBgAlpha095
                    onCloseRequested: root.notifs.removePopup(notification)
                }
                ScrollBar.vertical: Comp.ThemedScrollBar {}
                Component.onDestruction: {
                    if (root.hoveredNotification === notification)
                        root.hoveredNotification = null;
                }

                HoverHandler {
                    id: hover
                    enabled: card.enabled && root.visible
                    onHoveredChanged: {
                        if (hovered)
                            root.hoveredNotification = card.notification;
                        else if (root.hoveredNotification === card.notification)
                            root.hoveredNotification = null;
                    }
                }
            }
        }
    }

    Button {
        id: overflow
        objectName: "popupOverflow"
        y: root.layout.used + (root.visibleCount ? 8 : 0)
        width: parent.width
        height: root.overflowHeight
        visible: root.overflowCount > 0 && height > 0
        readonly property real stackInset: Math.min(14, Math.max(0, height - 32))
        bottomPadding: stackInset
        text: "+" + root.overflowCount + (root.overflowCount === 1 ? " more notification" : " more notifications")
        Accessible.name: text + ", open notification history"
        onClicked: root.notifs.controlCenterVisible = true
        background: Item {
            Repeater {
                model: Math.min(2, root.overflowCount)
                delegate: Rectangle {
                    required property int index
                    readonly property int depth: index + 1
                    objectName: "popupStackLayer" + depth
                    x: depth * 7
                    y: depth * overflow.stackInset / 2
                    width: parent.width - depth * 14
                    height: overflow.height - overflow.stackInset
                    radius: Theme.radiusCard
                    color: depth === 1 ? Theme.g1 : Theme.g2
                    border.color: Theme.colBorderStrong
                    border.width: 1
                    z: -depth
                }
            }
            Rectangle {
                width: parent.width
                height: parent.height - overflow.stackInset
                radius: Theme.radiusCard
                color: overflow.down ? Theme.g2 : overflow.hovered ? Theme.g1 : Theme.colBgAlpha095
                border.color: overflow.visualFocus ? Theme.colFg : Theme.colBorder
                border.width: overflow.visualFocus ? 2 : 1
            }
        }
        contentItem: Text {
            text: overflow.text
            color: Theme.colFg
            font.family: Theme.fontUi
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
