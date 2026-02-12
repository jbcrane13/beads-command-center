import SwiftUI

@main
struct BeadsCommandCenterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .frame(minWidth: 900, minHeight: 600)
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}
