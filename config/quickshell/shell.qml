import Quickshell
import "modules" as Modules
import "services" as Services

ShellRoot {
    Services.AudioService {
        id: audio
    }
    Services.NotificationService {
        id: notifs
    }
    Services.WallpaperService {
        id: wallpaper
    }

    Modules.Wallpaper {
        wallpaper: wallpaper
    }
    Modules.Bar {
        audio: audio
        notifs: notifs
    }
    Modules.Launcher {
        wallpaper: wallpaper
    }
    Modules.Osd {
        audio: audio
    }
    Modules.NotificationPopups {
        notifs: notifs
    }
    Modules.NotificationCenter {
        notifs: notifs
    }
}
