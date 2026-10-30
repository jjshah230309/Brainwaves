// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import BrainwavesCore
import Foundation
import Observation

/// App state on the main actor. Owns the audio engine and the local store.
@Observable
@MainActor
final class AppModel {
    private(set) var parameters: SessionParameters
    private(set) var isPlaying = false
    private(set) var elapsed: TimeInterval = 0
    private(set) var sessionStart: Date?
    private(set) var currentArm: PresetVariant = .base
    private(set) var overridden = false
    private(set) var outputLevelDB: Double = -120
    /// The timer option shown in the picker (minutes; nil = no timer).
    private(set) var timerChoice: Int?
    var userData: UserData
    var pendingFeedback: SessionRecord?
    var errorMessage: String?
    var showIntro: Bool
    /// When true, the running session belongs to the self-test and is not used for personalisation.
    private(set) var isExperimentSession = false

    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let audio = AudioEngine()
    @ObservationIgnored private var tickTimer: Timer?
    @ObservationIgnored private var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
    @ObservationIgnored private var activeRecord: SessionRecord?

    init(store: LocalStore = JSONFileStore(directory: JSONFileStore.defaultDirectory())) {
        self.store = store
        var loaded = UserData()
        var loadError: String?
        do {
            loaded = try store.load()
        } catch StoreError.unsupportedSchema(let version) {
            loadError = "Your data was saved by a newer version of Brainwaves (schema \(version)). It has not been changed."
        } catch {
            loadError = "Could not read saved data: \(error.localizedDescription)"
        }
        userData = loaded
        parameters = ModePreset.parameters(for: loaded.settings.lastMode, seed: 1)
        timerChoice = parameters.durationSeconds.map { Int($0 / 60) }
        showIntro = !loaded.settings.hasSeenIntro
        errorMessage = loadError
        audio.onRestart = { [weak self] in self?.isPlaying = self?.audio.isRunning ?? false }
    }

    var mode: Mode { parameters.mode }

    // MARK: - Modes and parameters

    func select(_ mode: Mode) {
        let keepGain = parameters.masterGain
        var p = ModePreset.parameters(for: mode, seed: rng.next())
        p.masterGain = keepGain
        overridden = false
        userData.settings.lastMode = mode
        timerChoice = p.durationSeconds.map { Int($0 / 60) }
        apply(p.clamped(), markOverridden: false)
        save()
    }

    /// A binding-friendly setter for any numeric parameter. Manual changes mark
    /// the session as overridden, so it is not used as a personalisation reward.
    func set<Value>(_ keyPath: WritableKeyPath<SessionParameters, Value>, _ value: Value) {
        var p = parameters
        p[keyPath: keyPath] = value
        let volumeOnly = (keyPath as AnyKeyPath) == (\SessionParameters.masterGain as AnyKeyPath)
        apply(p.clamped(), markOverridden: !volumeOnly)
    }

    func setTimer(minutes: Int?) {
        timerChoice = minutes
        var p = parameters
        p.durationSeconds = minutes.map { Double($0) * 60 + elapsed }
        apply(p.clamped(), markOverridden: false)
    }

    var remainingSeconds: TimeInterval? {
        parameters.durationSeconds.map { max($0 - elapsed, 0) }
    }

    private func apply(_ p: SessionParameters, markOverridden: Bool) {
        parameters = p
        if markOverridden { overridden = true }
        audio.update(p)
    }

    // MARK: - Transport

    func togglePlay() {
        isPlaying ? stop() : play()
    }

    func play() {
        guard !isPlaying else { return }
        var p = parameters
        if !overridden, userData.settings.personalizationEnabled {
            let eligible = PresetVariant.eligible(amTextureAllowed: userData.settings.amTextureAllowed)
            currentArm = userData.bandit.choose(mode: p.mode, eligible: eligible, using: &rng)
            var base = ModePreset.parameters(for: p.mode, seed: rng.next())
            base.masterGain = p.masterGain
            base.durationSeconds = p.durationSeconds
            p = currentArm.apply(to: base)
        } else {
            currentArm = .base
            p.seed = rng.next()
        }
        start(p, experiment: false)
    }

    func start(_ p: SessionParameters, experiment: Bool) {
        if isPlaying { stopAudioOnly() }
        isExperimentSession = experiment
        let clamped = p.clamped()
        parameters = clamped
        do {
            try audio.start(parameters: clamped)
        } catch {
            errorMessage = "Audio could not start: \(error.localizedDescription)"
            return
        }
        isPlaying = true
        elapsed = 0
        let now = Date()
        sessionStart = now
        activeRecord = SessionRecord(mode: clamped.mode, arm: currentArm, start: now, durationSeconds: 0,
                                     overridden: overridden || experiment)
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    func stop() {
        guard isPlaying else { return }
        // Fade quickly instead of cutting off.
        var p = parameters
        p.masterGain = 0
        audio.update(p)
        tickTimer?.invalidate()
        tickTimer = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            MainActor.assumeIsolated { self?.finishSession() }
        }
    }

    private func stopAudioOnly() {
        tickTimer?.invalidate()
        tickTimer = nil
        audio.stop()
        isPlaying = false
    }

    private func tick() {
        guard let start = sessionStart else { return }
        elapsed = Date().timeIntervalSince(start)
        let reading = audio.readMeter()
        if reading.seconds > 0 {
            userData.exposure.accumulate(rms: reading.rms, seconds: reading.seconds)
            outputLevelDB = reading.rms > 0 ? 20 * log10(reading.rms) : -120
        }
        if audio.renderer?.isFinished == true {
            tickTimer?.invalidate()
            tickTimer = nil
            finishSession()
        }
    }

    private func finishSession() {
        audio.stop()
        isPlaying = false
        if var record = activeRecord {
            record.durationSeconds = elapsed
            activeRecord = nil
            userData.append(record)
            if !isExperimentSession && elapsed >= SessionFeedback.minimumSessionSeconds {
                pendingFeedback = record
            }
        }
        // `stop()` faded the engine only; `parameters` still holds the user's volume.
        sessionStart = nil
        elapsed = 0
        save()
    }

    // MARK: - Feedback and personalisation

    func submitFeedback(_ feedback: SessionFeedback) {
        guard var record = pendingFeedback else { return }
        record.feedback = feedback
        userData.updateSession(record)
        if !record.overridden && userData.settings.personalizationEnabled {
            userData.bandit.update(mode: record.mode, arm: record.arm, reward: feedback.reward)
        }
        pendingFeedback = nil
        save()
    }

    func skipFeedback() {
        pendingFeedback = nil
    }

    func resetLearning() {
        userData.bandit.reset()
        save()
    }

    // MARK: - Settings, privacy

    func updateSettings(_ change: (inout UserSettings) -> Void) {
        change(&userData.settings)
        if !userData.settings.amTextureAllowed && parameters.amTexture.enabled {
            set(\.amTexture.enabled, false)
        }
        if !userData.settings.experimentalUnlocked {
            var p = parameters
            p.binaural.enabled = false
            p.gamma.enabled = false
            apply(p, markOverridden: false)
        }
        save()
    }

    func updateExposure(_ change: (inout ExposureMeter) -> Void) {
        change(&userData.exposure)
        save()
    }

    func acknowledgeIntro() {
        userData.settings.hasSeenIntro = true
        showIntro = false
        save()
    }

    func exportData(to url: URL) {
        do {
            save()
            try store.exportData().write(to: url, options: .atomic)
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    func deleteAllData() {
        stopAudioOnly()
        do {
            try store.deleteAll()
            userData = UserData()
            parameters = ModePreset.parameters(for: .focus)
            showIntro = true
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Self-test

    var activeExperiment: NOf1Experiment? {
        userData.experiments.last.flatMap { $0.isComplete ? nil : $0 }
    }

    var completedExperiments: [NOf1Experiment] {
        userData.experiments.filter(\.isComplete)
    }

    func createExperiment(_ comparison: SelfTestComparison, pairs: Int) {
        let base = ModePreset.parameters(for: .focus, seed: rng.next())
        let (a, b) = comparison.parameters(base: base)
        let experiment = NOf1Experiment(title: comparison.title, labelA: comparison.labelA, labelB: comparison.labelB,
                                        parametersA: a, parametersB: b, pairs: pairs, using: &rng)
        userData.experiments.append(experiment)
        save()
    }

    func startExperimentSession() {
        guard let experiment = activeExperiment, let next = experiment.nextSession else { return }
        var p = experiment.parameters(for: next.condition)
        p.durationSeconds = nil
        p.masterGain = parameters.masterGain > 0 ? parameters.masterGain : VolumeCeiling.defaultMasterGain
        start(p, experiment: true)
    }

    func recordExperimentResult(_ result: ReactionTimeResult) {
        guard let index = userData.experiments.indices.last, !userData.experiments[index].isComplete else { return }
        userData.experiments[index].record(result)
        stop()
        save()
    }

    func abandonExperiment() {
        guard let index = userData.experiments.indices.last, !userData.experiments[index].isComplete else { return }
        userData.experiments.remove(at: index)
        if isPlaying && isExperimentSession { stop() }
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            try store.save(userData)
        } catch {
            errorMessage = "Could not save: \(error.localizedDescription)"
        }
    }
}

/// The comparisons offered by the self-test.
enum SelfTestComparison: String, CaseIterable, Identifiable {
    case texture, noise, binaural

    var id: String { rawValue }

    var title: String {
        switch self {
        case .texture: return "Pulse texture on vs off"
        case .noise: return "Pink noise vs no noise"
        case .binaural: return "Binaural beat on vs off (experimental)"
        }
    }

    var labelA: String {
        switch self {
        case .texture: return "Texture off"
        case .noise: return "No noise"
        case .binaural: return "Beat off"
        }
    }

    var labelB: String {
        switch self {
        case .texture: return "Texture on"
        case .noise: return "Pink noise"
        case .binaural: return "Beat on"
        }
    }

    func parameters(base: SessionParameters) -> (SessionParameters, SessionParameters) {
        var a = base, b = base
        switch self {
        case .texture:
            a.amTexture.enabled = false
            b.amTexture = AMTextureSettings(enabled: true, rateHz: 16, depth: 0.25)
        case .noise:
            a.noiseLevel = 0
            b.noiseColor = .pink
            b.noiseLevel = 0.2
        case .binaural:
            a.binaural.enabled = false
            b.binaural = BinauralSettings(enabled: true, carrierHz: 200, beatHz: 16, level: 0.063)
        }
        return (a.clamped(), b.clamped())
    }

    func isAvailable(settings: UserSettings) -> Bool {
        switch self {
        case .texture: return settings.amTextureAllowed && AmplitudeModulator.isCompiledIn
        case .noise: return true
        case .binaural: return settings.experimentalUnlocked
        }
    }
}
