// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import BrainwavesCore
import SwiftUI

enum SidebarItem: Hashable {
    case mode(Mode)
    case experimental
    case selfTest
    case evidence
}

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: SidebarItem? = .mode(.focus)

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Modes") {
                    ForEach(Mode.allCases) { mode in
                        Label(mode.displayName, systemImage: icon(for: mode))
                            .tag(SidebarItem.mode(mode))
                    }
                }
                Section("Tools") {
                    Label("Self-test", systemImage: "chart.bar.xaxis").tag(SidebarItem.selfTest)
                    Label("Experimental", systemImage: "flask").tag(SidebarItem.experimental)
                    Label("Evidence", systemImage: "book").tag(SidebarItem.evidence)
                }
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190)
        } detail: {
            switch selection {
            case .mode(let mode)?:
                PlayerView(mode: mode)
            case .experimental?:
                ExperimentalView()
            case .selfTest?:
                SelfTestView()
            case .evidence?:
                EvidenceView()
            case nil:
                Text("Choose a mode").foregroundStyle(.secondary)
            }
        }
        .onChange(of: selection) { _, newValue in
            if case .mode(let mode)? = newValue, mode != model.mode, !model.isPlaying {
                model.select(mode)
            }
        }
        .onAppear { selection = .mode(model.mode) }
        .sheet(isPresented: Binding(get: { model.showIntro }, set: { model.showIntro = $0 })) {
            IntroView()
        }
        .sheet(item: Binding(get: { model.pendingFeedback }, set: { model.pendingFeedback = $0 })) { record in
            FeedbackSheet(record: record)
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private func icon(for mode: Mode) -> String {
        switch mode {
        case .focus: return "scope"
        case .relax: return "leaf"
        case .sleep: return "moon.stars"
        }
    }
}

struct IntroView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Welcome to Brainwaves").font(.title).bold()
            Text(UserFacingCopy.disclaimer)
            Divider()
            Label(UserFacingCopy.infantAdvisory, systemImage: "figure.and.child.holdinghands")
            Label(UserFacingCopy.alarmAdvisory, systemImage: "bell.badge")
            Label(UserFacingCopy.privacyPromise, systemImage: "lock.shield")
            HStack {
                Spacer()
                Button("I understand") { model.acknowledgeIntro() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
