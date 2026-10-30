// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import BrainwavesCore
import SwiftUI

@MainActor
struct SelfTestView: View {
    @Environment(AppModel.self) private var model
    @State private var comparison: SelfTestComparison = .noise
    @State private var pairs = 6
    @State private var stage: Stage = .idle

    enum Stage { case idle, listening, task }

    /// Listen for this long before the reaction-time task (docs/design/personalization.md §3.1).
    static let listeningSeconds: TimeInterval = 10 * 60

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Self-test").font(.largeTitle).bold()
                Text(UserFacingCopy.selfTestIntro)
                Callout(text: UserFacingCopy.selfTestLimitations, systemImage: "info.circle", tint: Palette.neutral)
                if let experiment = model.activeExperiment {
                    active(experiment)
                } else {
                    create
                }
                if !model.completedExperiments.isEmpty {
                    Divider()
                    Text("Results").font(.title2).bold()
                    ForEach(model.completedExperiments) { result($0) }
                }
            }
            .padding(24)
            .frame(maxWidth: 680, alignment: .leading)
        }
        .navigationTitle("Self-test")
    }

    private var create: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New comparison").font(.title2).bold()
            Picker("Compare", selection: $comparison) {
                ForEach(SelfTestComparison.allCases.filter { $0.isAvailable(settings: model.userData.settings) }) {
                    Text($0.title).tag($0)
                }
            }
            Stepper("Pairs of sessions: \(pairs)", value: $pairs, in: NOf1Experiment.pairRange)
            Text("That is \(pairs * 2) sessions of about 13 minutes each. Leave at least 30 minutes between the two sessions in a pair.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Create self-test") { model.createExperiment(comparison, pairs: pairs) }
                .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func active(_ experiment: NOf1Experiment) -> some View {
        if let next = experiment.nextSession {
            VStack(alignment: .leading, spacing: 12) {
                Text(experiment.title).font(.title2).bold()
                Text("Pair \(next.pair + 1) of \(experiment.schedule.count) · Session \(next.position + 1)")
                    .foregroundStyle(.secondary)
                switch stage {
                case .idle:
                    Button("Start session") {
                        model.startExperimentSession()
                        stage = .listening
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Abandon this self-test", role: .destructive) { model.abandonExperiment() }
                case .listening:
                    let remaining = max(Self.listeningSeconds - model.elapsed, 0)
                    Text("Listen and work as usual. The reaction-time game starts in \(Int(remaining / 60) + 1) min.")
                    ProgressView(value: min(model.elapsed / Self.listeningSeconds, 1))
                    HStack {
                        Button("Start the game now") { stage = .task }
                        Button("Cancel session") {
                            model.stop()
                            stage = .idle
                        }
                    }
                    .onChange(of: remaining <= 0) { _, done in if done { stage = .task } }
                case .task:
                    ReactionTaskView { result in
                        model.recordExperimentResult(result)
                        stage = .idle
                    }
                }
            }
        }
    }

    private func result(_ experiment: NOf1Experiment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(experiment.title).font(.headline)
            if let analysis = experiment.analysis() {
                Text(analysis.message)
                Text("Mean difference \(Int(analysis.meanDifferenceMs.rounded())) ms (95% interval \(Int(analysis.ciLowMs.rounded())) to \(Int(analysis.ciHighMs.rounded())) ms), p = \(String(format: "%.3f", analysis.pValue)), \(analysis.pairs) pairs. A positive difference means \(experiment.labelA) was faster.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Not enough complete pairs to analyse.").foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Palette.relax.opacity(0.3)))
    }
}

/// Three-minute psychomotor-vigilance-style task. The stimulus appears once every
/// 2–10 s (far below any flashing threshold) and the user presses Space or clicks.
@MainActor
struct ReactionTaskView: View {
    let onFinish: (ReactionTimeResult) -> Void

    private enum Phase { case ready, waiting, stimulus }
    private static let missTimeout: TimeInterval = 3

    @State private var phase: Phase = .ready
    @State private var waits: [Double] = []
    @State private var index = 0
    @State private var shownAt: Date?
    @State private var reactionTimes: [Double] = []
    @State private var premature = 0
    @State private var endAt = Date()
    @State private var pending: Task<Void, Never>?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(phase == .stimulus ? Palette.focus : Palette.neutral)
                    .frame(height: 220)
                Text(label).font(.title).bold()
            }
            .contentShape(Rectangle())
            .onTapGesture { respond() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { respond() }
            if phase != .ready {
                Text("Responses: \(reactionTimes.count) · Too early: \(premature)").foregroundStyle(.secondary)
            }
        }
        .focusable()
        .focused($focused)
        .onKeyPress(.space) {
            respond()
            return .handled
        }
        .onAppear { focused = true }
        .onDisappear { pending?.cancel() }
    }

    private var label: String {
        switch phase {
        case .ready: return "Press Space to begin"
        case .waiting: return "Wait…"
        case .stimulus: return "Now! Press Space"
        }
    }

    private func respond() {
        switch phase {
        case .ready:
            var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
            waits = ReactionTimeTask.makeSchedule(using: &rng)
            endAt = Date().addingTimeInterval(ReactionTimeTask.defaultDurationSeconds)
            nextTrial()
        case .waiting:
            premature += 1
        case .stimulus:
            if let shownAt { reactionTimes.append(Date().timeIntervalSince(shownAt) * 1000) }
            nextTrial()
        }
    }

    private func nextTrial() {
        pending?.cancel()
        guard index < waits.count, Date() < endAt else {
            phase = .ready
            onFinish(ReactionTimeTask.score(reactionTimesMs: reactionTimes, prematurePresses: premature))
            return
        }
        phase = .waiting
        shownAt = nil
        let wait = waits[index]
        index += 1
        pending = Task { @MainActor in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            phase = .stimulus
            let shown = Date()
            shownAt = shown
            // A missed stimulus is scored as a 3 s response (a lapse).
            try? await Task.sleep(for: .seconds(Self.missTimeout))
            guard !Task.isCancelled, phase == .stimulus, shownAt == shown else { return }
            reactionTimes.append(Self.missTimeout * 1000)
            nextTrial()
        }
    }
}
