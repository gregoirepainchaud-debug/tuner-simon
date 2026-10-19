import SwiftUI
import UIKit

@main
struct TunerSimonApp: App {
    init() {
        // Écran maintenu allumé pendant l'accord.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
