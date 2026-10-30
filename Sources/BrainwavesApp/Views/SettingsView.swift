// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import AppKit
import BrainwavesCore
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    var body: some View {
        TabView {
            HearingSettings().tabItem { Label("Hearing", systemImage: "ear") }
            PersonalizationSettings().tabItem { Label("Personalisation", systemImage: "slider.horizontal.3") }
            PrivacySettings().tabItem { Label("Privacy", systemImage: "lock.shield") }
            AboutSettings().tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 380)
    }
}

private struct HearingSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let exposure = model.userData.exposure
        Form {
            Picker("Listening profile", selection: Binding(
                get: { exposure.profile }, set: { value in model.updateExposure { $0.profile = value } })) {
                Text("Adult (80 dB, 40 h/week)").tag(ExposureMeter.Profile.adult)
                Text("Sensitive or child (75 dB, 40 h/week)").tag(ExposureMeter.Profile.sensitive)
            }
            LabeledSlider(title: "Your system volume", value: exposure.systemVolume, range: 0...1,
                          format: { "\(Int($0 * 100))%" }) { value in model.updateExposure { $0.systemVolume = value } }
            LabeledSlider(title: "Headphone loudness at full scale", value: exposure.calibrationOffsetDB, range: 80...120,
                          step: 1, format: { "\(Int($0)) dB" }) { value in model.updateExposure { $0.calibrationOffsetDB = value } }
            LabeledContent("This week's estimated dose", value: "\(Int(exposure.doseFraction * 100))%")
            Text(UserFacingCopy.exposureEstimateNote).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }
}

private struct PersonalizationSettings: View {
    @Environment(AppModel.self) private var model
    @State private var confirmReset = false

    var body: some View {
        Form {
            Toggle("Learn from my ratings", isOn: Binding(
                get: { model.userData.settings.personalizationEnabled },
                set: { value in model.updateSettings { $0.personalizationEnabled = value } }))
            Toggle("Allow pulse texture", isOn: Binding(
                get: { model.userData.settings.amTextureAllowed },
                set: { value in model.updateSettings { $0.amTextureAllowed = value } }))
            .disabled(!AmplitudeModulator.isCompiledIn)
            Toggle("Show experimental layers", isOn: Binding(
                get: { model.userData.settings.experimentalUnlocked },
                set: { value in model.updateSettings { $0.experimentalUnlocked = value } }))
            Button("Reset learning…") { confirmReset = true }
            Text("Learning happens only on this Mac. Experimental layers are never chosen automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .confirmationDialog("Reset everything Brainwaves has learned about your preferences?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) { model.resetLearning() }
        }
    }
}

private struct PrivacySettings: View {
    @Environment(AppModel.self) private var model
    @State private var confirmDelete = false

    var body: some View {
        Form {
            Text(UserFacingCopy.privacyPromise)
            LabeledContent("Sessions stored", value: "\(model.userData.sessions.count)")
            Button("Export my data…") { export() }
            Button("Delete all data…", role: .destructive) { confirmDelete = true }
        }
        .padding()
        .confirmationDialog("Delete all Brainwaves data from this Mac? This cannot be undone.", isPresented: $confirmDelete) {
            Button("Delete all data", role: .destructive) { model.deleteAllData() }
        }
    }

    private func export() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "brainwaves-data.json"
        if panel.runModal() == .OK, let url = panel.url {
            model.exportData(to: url)
        }
    }
}

private struct AboutSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Brainwaves").font(.title2).bold()
            Text(UserFacingCopy.disclaimer)
            Text(UserFacingCopy.experimentalAdvisory).font(.caption).foregroundStyle(.secondary)
            Text("Free and open source under the MIT licence.").font(.caption)
        }
        .padding()
    }
}
