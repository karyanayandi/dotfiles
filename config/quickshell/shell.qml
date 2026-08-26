import Quickshell
import "modules" as Modules
import "services" as Services

ShellRoot {
    Theme { id: theme }
    Services.AudioService { id: audio }

    Modules.Bar { theme: theme; audio: audio }
    Modules.Osd { theme: theme; audio: audio }
}
