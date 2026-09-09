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

    Modules.LockScreen {
        wallpaper: wallpaper.current
    }

    Modules.Wallpaper {
        wallpaper: wallpaper
    }

    Modules.Island {
        audio: audio
        notifs: notifs
        wallpaper: wallpaper
    }

    Modules.NotificationPopups {
        notifs: notifs
    }

}
