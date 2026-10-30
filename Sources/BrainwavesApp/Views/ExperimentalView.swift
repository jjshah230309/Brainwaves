// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import BrainwavesCore
import SwiftUI

struct ExperimentalView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmHeadphones = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Experimental").font(.largeTitle).bold()
                Callout(text: UserFacingCopy.experimentalAdvisory, systemImage: "exclamationmark.triangle",
                        tint: Palette.sleep)
                if model.userData.settings.experimentalUnlocked {
                    controls
                } else {
                    Button("I have read this. Show the experimental layers.") {
                        model.updateSettings { $0.experimentalUnlocked = true }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .navigationTitle("Experimental")
        .alert("Use headphones", isPresented: $confirmHeadphones) {
            Button("I'm wearing headphones") { model.set(\.binaural.enabled, true) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Binaural beats only exist when each ear hears a different tone. Through speakers you'll hear an ordinary steady tone.")
        }
    }

    @ViewBuilder
    private var controls: some View {
        let p = model.parameters
        EvidenceCardView(card: card("binaural"))
        Toggle("Binaural beat", isOn: Binding(
            get: { p.binaural.enabled },
            set: { on in
                if on {
                    confirmHeadphones = true
                } else {
                    model.set(\.binaural.enabled, false)
                }
            }))
        if p.binaural.enabled {
            LabeledSlider(title: "Beat frequency", value: p.binaural.beatHz, range: BinauralSettings.beatRange, step: 1,
                          format: { "\(Int($0)) hertz" }) { model.set(\.binaural.beatHz, $0) }
            LabeledSlider(title: "Beat level", value: p.binaural.level, range: BinauralSettings.levelRange,
                          format: { "\(Int($0 * 100))%" }) { model.set(\.binaural.level, $0) }
        }
        Divider()
        EvidenceCardView(card: card("gamma"))
        if AmplitudeModulator.isCompiledIn {
            Toggle("40 Hz pulsing", isOn: Binding(get: { p.gamma.enabled }, set: { model.set(\.gamma.enabled, $0) }))
            if p.gamma.enabled {
                LabeledSlider(title: "40 Hz depth", value: p.gamma.depth, range: GammaSettings.depthRange,
                              format: { "\(Int($0 * 100))%" }) { model.set(\.gamma.depth, $0) }
            }
        }
        Button("Turn off all experimental layers") {
            model.set(\.binaural.enabled, false)
            model.set(\.gamma.enabled, false)
        }
    }
}
