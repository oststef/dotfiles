// Entry point. One bar per monitor, one toast stack on the focused monitor.
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    NotificationPopups {}
    Launcher {}
}
