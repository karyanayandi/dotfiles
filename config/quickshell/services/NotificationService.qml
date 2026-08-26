import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false

    property bool doNotDisturb: false
    property bool controlCenterVisible: false
    property int notifCount: {
        if (!server.trackedNotifications) return 0
        let c = server.trackedNotifications.count
        if (c !== undefined && c !== null) return c
        if (server.trackedNotifications.values) return server.trackedNotifications.values.length
        if (server.trackedNotifications.length !== undefined) return server.trackedNotifications.length
        return 0
    }
    property bool hasUnread: notifCount > 0
    property var popups: []

    property alias server: server

    NotificationServer {
        id: server
        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: notif => {
            notif.tracked = true
            if (root.doNotDisturb) return
            const arr = root.popups.slice()
            arr.push(notif)
            root.popups = arr
            notif.closed.connect(() => {
                const idx = root.popups.indexOf(notif)
                if (idx !== -1) {
                    const a = root.popups.slice()
                    a.splice(idx, 1)
                    root.popups = a
                }
            })
        }
    }

    function removePopup(notif) {
        const idx = popups.indexOf(notif)
        if (idx !== -1) {
            const a = popups.slice()
            a.splice(idx, 1)
            popups = a
        }
    }

    onDoNotDisturbChanged: if (doNotDisturb) popups = []

    function dismissAll() {
        let guard = 200
        while (notifCount > 0 && guard-- > 0) {
            try {
                let n = null
                if (server.trackedNotifications.get) n = server.trackedNotifications.get(0)
                else if (server.trackedNotifications.values) n = server.trackedNotifications.values[0]
                else break
                if (!n) break
                n.dismiss()
            } catch(e) { break }
        }
        popups = []
    }

    function grouped() {
        let map = {}
        let order = []
        let src = server.trackedNotifications.values ? server.trackedNotifications.values : []
        if (!src || src.length === 0) {
            let cnt = notifCount
            src = []
            for (let i = 0; i < cnt; i++) {
                try { let n = server.trackedNotifications.get(i); if (n) src.push(n) } catch(e) {}
            }
        }
        for (let n of src) {
            let key = n.appName || "Unknown"
            if (!map[key]) { map[key] = { appName: key, appIcon: n.appIcon || n.desktopEntry || "", notifications: [] }; order.push(key) }
            map[key].notifications.push(n)
            if (n.appIcon) map[key].appIcon = n.appIcon
        }
        return order.map(k => map[k])
    }

    function dismissGroup(group) {
        for (let n of group.notifications) try { n.dismiss() } catch(e) {}
    }

    function getCount() { return root.notifCount }
    function toggleDnd() { doNotDisturb = !doNotDisturb }
    function toggleCenter() { controlCenterVisible = !controlCenterVisible }

    IpcHandler {
        target: "notifications"
        function toggle() { root.toggleCenter() }
        function open() { root.controlCenterVisible = true }
        function close() { root.controlCenterVisible = false }
        function clear() { root.dismissAll() }
        function dismissAll() { root.dismissAll() }
        function getCount() { return root.getCount() }
        function toggleDnd() { root.toggleDnd() }
        function dndOn() { root.doNotDisturb = true }
        function dndOff() { root.doNotDisturb = false }
    }
}
