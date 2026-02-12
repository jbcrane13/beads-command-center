import SwiftUI

@main
struct BeadsCommandCenterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .frame(minWidth: 1000, minHeight: 650)
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 1400, height: 850)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}
