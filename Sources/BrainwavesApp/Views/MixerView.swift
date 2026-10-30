// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import BrainwavesCore
import SwiftUI

struct MixerView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let p = model.parameters
        VStack(alignment: .leading, spacing: 14) {
            LabeledSlider(title: "Music level", value: p.musicLevel, range: 0...1,
                          format: { "\(Int($0 * 100))%" }) { model.set(\.musicLevel, $0) }
            LabeledSlider(title: "Brightness", value: p.brightnessHz, range: SessionParameters.brightnessRange,
                          format: { "\(Int($0)) hertz" }) { model.set(\.brightnessHz, $0) }
            LabeledSlider(title: "Tempo", value: p.tempoBPM, range: SessionParameters.tempoRange, step: 1,
                          format: { "\(Int($0)) beats per minute" }) { model.set(\.tempoBPM, $0) }
            LabeledSlider(title: "Melody density", value: p.motifDensity, range: SessionParameters.densityRange,
                          format: { "\(Int($0 * 100))%" }) { model.set(\.motifDensity, $0) }

            Picker("Noise colour", selection: Binding(get: { p.noiseColor }, set: { model.set(\.noiseColor, $0) })) {
                ForEach(NoiseColor.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            LabeledSlider(title: "Noise level", value: p.noiseLevel, range: 0...1,
                          format: { "\(Int($0 * 100))%" }) { model.set(\.noiseLevel, $0) }

            if p.mode == .relax {
                Toggle("Breathing swell", isOn: Binding(get: { p.breathing.enabled }, set: { model.set(\.breathing.enabled, $0) }))
                LabeledSlider(title: "Breaths per minute", value: p.breathing.breathsPerMinute,
                              range: BreathingSettings.rateRange, step: 0.5,
                              format: { String(format: "%.1f", $0) }) { model.set(\.breathing.breathsPerMinute, $0) }
            }

            Divider()
            textureSection(p)
        }
    }

    @ViewBuilder
    private func textureSection(_ p: SessionParameters) -> some View {
        if !AmplitudeModulator.isCompiledIn {
            Text("Pulse texture is not included in this build.").foregroundStyle(.secondary)
        } else if !model.userData.settings.amTextureAllowed {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pulse texture").font(.headline)
                EvidenceCardView(card: card("texture"))
                Button("Allow pulse texture") { model.updateSettings { $0.amTextureAllowed = true } }
            }
        } else {
            Toggle("Pulse texture", isOn: Binding(get: { p.amTexture.enabled }, set: { model.set(\.amTexture.enabled, $0) }))
            if p.amTexture.enabled {
                LabeledSlider(title: "Pulse rate", value: p.amTexture.rateHz, range: AMTextureSettings.rateRange, step: 1,
                              format: { "\(Int($0)) hertz" }) { model.set(\.amTexture.rateHz, $0) }
                LabeledSlider(title: "Pulse depth", value: p.amTexture.depth, range: AMTextureSettings.depthRange,
                              format: { "\(Int($0 * 100))%" }) { model.set(\.amTexture.depth, $0) }
            }
        }
    }
}

func card(_ id: String) -> EvidenceCard {
    UserFacingCopy.evidenceCards.first { $0.id == id } ?? UserFacingCopy.evidenceCards[0]
}

struct EvidenceCardView: View {
    let card: EvidenceCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(card.title).font(.headline)
                Spacer()
                Text("Certainty: \(card.certainty.rawValue)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Palette.neutral))
            }
            Text(card.summary).fixedSize(horizontal: false, vertical: true)
            ForEach(card.sources, id: \.self) { source in
                Text("• \(source)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.focus.opacity(0.25)))
        .accessibilityElement(children: .combine)
    }
}

struct EvidenceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("What the evidence says").font(.largeTitle).bold()
                Text(UserFacingCopy.disclaimer).foregroundStyle(.secondary)
                ForEach(UserFacingCopy.evidenceCards) { EvidenceCardView(card: $0) }
                Text("Full review with references: docs/research/evidence-review.md in the source repository.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 680, alignment: .leading)
        }
        .navigationTitle("Evidence")
    }
}
