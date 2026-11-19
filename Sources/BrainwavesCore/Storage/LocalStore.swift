// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

public struct UserSettings: Codable, Equatable, Sendable {
    public var personalizationEnabled = true
    /// The user has opted in to the AM pulse texture (off for new users).
    public var amTextureAllowed = false
    /// The user has read the advisory and unlocked the Experimental section.
    public var experimentalUnlocked = false
    public var hasSeenIntro = false
    public var lastMode: Mode = .focus

    public init() {}
}

public struct SessionRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var mode: Mode
    public var arm: PresetVariant
    public var start: Date
    public var durationSeconds: Double
    /// True if the user changed parameters manually; such sessions are not used as rewards.
    public var overridden: Bool
    public var feedback: SessionFeedback?

    public init(id: UUID = UUID(), mode: Mode, arm: PresetVariant, start: Date, durationSeconds: Double,
                overridden: Bool, feedback: SessionFeedback? = nil) {
        self.id = id
        self.mode = mode
        self.arm = arm
        self.start = start
        self.durationSeconds = durationSeconds
        self.overridden = overridden
        self.feedback = feedback
    }
}

/// Everything Brainwaves stores, kept in one JSON file (docs/design/architecture.md §5).
public struct UserData: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let maxSessions = 500

    public var schemaVersion = UserData.currentSchemaVersion
    public var settings = UserSettings()
    public private(set) var sessions: [SessionRecord] = []
    public var bandit = ThompsonBandit()
    public var experiments: [NOf1Experiment] = []
    public var exposure = ExposureMeter()

    public init() {}

    /// Adds a session, keeping only the most recent `maxSessions`.
    public mutating func append(_ record: SessionRecord) {
        sessions.append(record)
        if sessions.count > UserData.maxSessions {
            sessions.removeFirst(sessions.count - UserData.maxSessions)
        }
    }

    public mutating func updateSession(_ record: SessionRecord) {
        if let index = sessions.firstIndex(where: { $0.id == record.id }) {
            sessions[index] = record
        }
    }
}

public enum StoreError: Error, Equatable {
    case unsupportedSchema(Int)
}

public protocol LocalStore {
    func load() throws -> UserData
    func save(_ data: UserData) throws
    func exportData() throws -> Data
    func deleteAll() throws
}

/// Stores `UserData` as JSON with atomic writes and owner-only permissions.
public final class JSONFileStore: LocalStore {
    public let fileURL: URL

    public init(directory: URL) {
        fileURL = directory.appendingPathComponent("userdata.json")
    }

    /// ~/Library/Application Support/Brainwaves (or the XDG equivalent on Linux).
    public static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("Brainwaves", isDirectory: true)
    }

    public func load() throws -> UserData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return UserData() }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONFileStore.decoder()
        struct Header: Decodable { var schemaVersion: Int }
        let header = try decoder.decode(Header.self, from: data)
        guard header.schemaVersion <= UserData.currentSchemaVersion else {
            // Refuse rather than overwrite data written by a newer version.
            throw StoreError.unsupportedSchema(header.schemaVersion)
        }
        return try decoder.decode(UserData.self, from: data)
    }

    public func save(_ data: UserData) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let encoded = try JSONFileStore.encoder().encode(data)
        try encoded.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    public func exportData() throws -> Data {
        try JSONFileStore.encoder().encode(load())
    }

    public func deleteAll() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
