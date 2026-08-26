import Quickshell
import "modules" as Modules
import "services" as Services

ShellRoot {
    Services.AudioService { id: audio }
    Services.NotificationService { id: notifs }

    Modules.Bar { audio: audio; notifs: notifs }
    Modules.Launcher { audioSvc: audio }
    Modules.Osd { audio: audio }
    Modules.NotificationPopups { notifs: notifs }
    Modules.NotificationCenter { notifs: notifs }
}
