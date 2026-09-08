import "../.."
import "../../components" as Comp
import QtQml.Models
import QtQuick
import Quickshell.Services.Notifications

Item {
    id: root

    required property var notifs
    readonly property var latest: notifs.popups.length ? notifs.popups[notifs.popups.length - 1] : null

    // Keep surviving timer delegates when the service replaces its popup array.
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
                pending.append({
                    "notification": notification
                });
        }
    }

    implicitWidth: Config.popupWidth
    implicitHeight: latest ? Math.min(260, card.implicitHeight) : 0
    clip: true
    Component.onCompleted: syncTimers()
    onNotifsChanged: syncTimers()
    onLatestChanged: viewport.contentY = 0

    Connections {
        function onPopupsChanged() {
            root.syncTimers();
        }

        target: root.notifs
    }

    ListModel {
        id: pending
    }

    Instantiator {
        model: pending

        delegate: Timer {
            required property var notification

            interval: {
                if (notification.urgency === NotificationUrgency.Low)
                    return Config.popupTtlLow;

                if (notification.urgency === NotificationUrgency.Critical)
                    return Config.popupTtlCritical;

                if (notification.expireTimeout > 0)
                    return notification.expireTimeout;

                return Config.popupTtlNormal;
            }
            running: !(root.visible && root.latest === notification && popupHover.hovered)
            onTriggered: root.notifs.removePopup(notification)
        }
    }

    Flickable {
        id: viewport

        anchors.fill: parent
        contentWidth: width
        contentHeight: card.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        clip: true

        Comp.NotificationCard {
            id: card

            width: viewport.width
            height: implicitHeight
            notification: root.latest
            visible: root.latest !== null
            imgSize: 32
            cardRadius: 20
            cardBg: Theme.colBg
            onCloseRequested: root.notifs.removePopup(root.latest)
        }

        HoverHandler {
            id: popupHover

            enabled: root.visible && root.latest !== null
        }
    }
}
