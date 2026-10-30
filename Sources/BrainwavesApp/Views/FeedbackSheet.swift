// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import BrainwavesCore
import SwiftUI

struct FeedbackSheet: View {
    let record: SessionRecord
    @Environment(AppModel.self) private var model
    @State private var primary = 3
    @State private var enjoyment = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How was that session?").font(.title2).bold()
            rating(record.mode == .focus ? "How focused did you feel?" : "How calm did you feel?", value: $primary)
            rating("How much did you enjoy the sound?", value: $enjoyment)
            Text(record.overridden
                 ? "You adjusted the sound manually, so this rating is saved but not used for learning."
                 : "Your rating stays on this Mac and helps choose future variations.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("Skip") { model.skipFeedback() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { model.submitFeedback(SessionFeedback(primary: primary, enjoyment: enjoyment)) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func rating(_ question: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
            Picker(question, selection: value) {
                ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityLabel(question)
            HStack {
                Text("Not at all").font(.caption2)
                Spacer()
                Text("Very").font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }
}
