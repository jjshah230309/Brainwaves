// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import AppKit
import BrainwavesCore
import SwiftUI

@main
struct BrainwavesApp: App {
    @State private var model = AppModel()

    init() {
        // Running the bare SwiftPM executable (without the .app bundle) needs a regular activation policy.
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup("Brainwaves") {
            ContentView()
                .environment(model)
                .frame(minWidth: 760, minHeight: 520)
        }
        .commands {
            CommandMenu("Playback") {
                Button(model.isPlaying ? "Stop" : "Play") { model.togglePlay() }
                    .keyboardShortcut(.return, modifiers: .command)
                Divider()
                ForEach(Array(Mode.allCases.enumerated()), id: \.element) { index, mode in
                    Button(mode.displayName) { model.select(mode) }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }
        }

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}

/// Pastel accent palette. Accents are used for fills and large shapes only;
/// text uses system semantic colours to keep WCAG AA contrast.
enum Palette {
    static let focus = Color(red: 0.70, green: 0.81, blue: 0.95)   // soft blue
    static let relax = Color(red: 0.74, green: 0.89, blue: 0.80)   // muted green
    static let sleep = Color(red: 0.80, green: 0.76, blue: 0.93)   // soft purple
    static let neutral = Color(red: 0.90, green: 0.91, blue: 0.93) // pastel grey

    static func color(for mode: Mode) -> Color {
        switch mode {
        case .focus: return focus
        case .relax: return relax
        case .sleep: return sleep
        }
    }
}
