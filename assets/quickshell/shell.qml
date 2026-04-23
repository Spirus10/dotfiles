import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    // One bar per connected screen.
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Launcher — only instantiated while open.
    LazyLoader {
        id: launcherLoader
        active: false

        Launcher {
            onDismissed: launcherLoader.active = false
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { launcherLoader.active = !launcherLoader.active }
        function show(): void   { launcherLoader.active = true }
        function hide(): void   { launcherLoader.active = false }
    }

    // Clipboard history — same lifecycle as the launcher.
    LazyLoader {
        id: clipboardLoader
        active: false

        Clipboard {
            onDismissed: clipboardLoader.active = false
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void { clipboardLoader.active = !clipboardLoader.active }
        function show(): void   { clipboardLoader.active = true }
        function hide(): void   { clipboardLoader.active = false }
    }
}
