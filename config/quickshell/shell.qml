import Quickshell
import "modules" as Modules
import "services" as Services

ShellRoot {
    Theme { id: theme }
    Services.AudioService { id: audio }
    Services.NotificationService { id: notifs }

    Modules.Bar { theme: theme; audio: audio; notifs: notifs }
    Modules.Osd { theme: theme; audio: audio }
    Modules.NotificationPopups { theme: theme; notifs: notifs }
    Modules.NotificationCenter { theme: theme; notifs: notifs }
}
