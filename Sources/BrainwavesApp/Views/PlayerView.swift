// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import BrainwavesCore
import SwiftUI

struct PlayerView: View {
    let mode: Mode
    @Environment(AppModel.self) private var model
    @State private var showMixer = false

    private let timerChoices: [Int?] = [nil, 5, 15, 25, 45, 50, 90, 120]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                transport
                volume
                if model.mode == .relax, model.parameters.breathing.enabled {
                    BreathingGuide(breathsPerMinute: model.parameters.breathing.breathsPerMinute,
                                   start: model.sessionStart)
                        .frame(maxWidth: .infinity)
                }
                if let notice = UserFacingCopy.exposureNotice(for: model.userData.exposure.status) {
                    Callout(text: notice + " " + UserFacingCopy.exposureEstimateNote,
                            systemImage: "ear.trianglebadge.exclamationmark", tint: Palette.sleep)
                }
                if mode == .sleep {
                    Callout(text: UserFacingCopy.infantAdvisory, systemImage: "moon.zzz", tint: Palette.sleep)
                }
                DisclosureGroup("Mixer", isExpanded: $showMixer) {
                    MixerView().padding(.top, 8)
                }
                .accessibilityHint("Shows detailed sound controls")
            }
            .padding(24)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .navigationTitle(mode.displayName)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mode.displayName).font(.largeTitle).bold()
            Text(UserFacingCopy.modeDescription(mode))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.color(for: mode).opacity(0.45)))
    }

    private var transport: some View {
        HStack(alignment: .center, spacing: 20) {
            Button {
                if model.mode != mode && !model.isPlaying { model.select(mode) }
                model.togglePlay()
            } label: {
                Label(model.isPlaying ? "Stop" : "Play", systemImage: model.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .frame(minWidth: 110, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.space, modifiers: [])
            .accessibilityLabel(model.isPlaying ? "Stop \(mode.displayName)" : "Play \(mode.displayName)")

            VStack(alignment: .leading, spacing: 6) {
                Picker("Timer", selection: Binding(get: { model.timerChoice }, set: { model.setTimer(minutes: $0) })) {
                    ForEach(timerChoices, id: \.self) { minutes in
                        Text(minutes.map { "\($0) min" } ?? "No timer").tag(minutes)
                    }
                }
                .frame(maxWidth: 220)
                if let remaining = model.remainingSeconds, model.isPlaying {
                    Text("\(Int(remaining) / 60):\(String(format: "%02d", Int(remaining) % 60)) remaining")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("\(Int(remaining) / 60) minutes remaining")
                }
                if model.isPlaying {
                    Text("Variant: \(model.currentArm.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var volume: some View {
        LabeledSlider(title: "Volume", value: model.parameters.masterGain, range: 0...max(model.parameters.volumeCap, 0.01),
                      format: { "\(Int($0 * 100))%" }) { model.set(\.masterGain, $0) }
    }
}

/// Slider with a visible title, a spoken value and full keyboard support.
struct LabeledSlider: View {
    let title: String
    let value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    let format: (Double) -> String
    let onChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(format(value)).monospacedDigit().foregroundStyle(.secondary)
            }
            Group {
                if let step {
                    Slider(value: Binding(get: { value }, set: onChange), in: range, step: step)
                } else {
                    Slider(value: Binding(get: { value }, set: onChange), in: range)
                }
            }
            .labelsHidden()
            .accessibilityLabel(title)
            .accessibilityValue(format(value))
        }
    }
}

struct Callout: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.35)))
        .accessibilityElement(children: .combine)
    }
}

/// Slow visual breathing cue in phase with the audio swell. With Reduce
/// Motion on, it is a static ring with a text cue.
struct BreathingGuide: View {
    let breathsPerMinute: Double
    let start: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 1.0 / 30.0)) { context in
            let phase = currentPhase(at: context.date)
            let inhaling = phase >= 0.5
            // Matches the renderer: gain is lowest at phase 0.5 and highest at phase 0.
            let fullness = 1 - (1 - cos(2 * Double.pi * phase)) / 2
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Palette.relax, lineWidth: 6)
                        .frame(width: 140, height: 140)
                    if !reduceMotion {
                        Circle()
                            .fill(Palette.relax.opacity(0.6))
                            .frame(width: 140, height: 140)
                            .scaleEffect(0.45 + 0.55 * fullness)
                    }
                }
                Text(start == nil ? "Press Play to begin" : (inhaling ? "Breathe in" : "Breathe out"))
                    .font(.title3)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Breathing guide")
            .accessibilityValue(start == nil ? "Not started" : (inhaling ? "Breathe in" : "Breathe out"))
        }
    }

    private func currentPhase(at date: Date) -> Double {
        guard let start else { return 0.5 }
        let cycles = date.timeIntervalSince(start) * breathsPerMinute / 60 + 0.5
        return cycles - cycles.rounded(.down)
    }
}
