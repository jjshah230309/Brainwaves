// SPDX-License-Identifier: MIT
import XCTest
@testable import BrainwavesCore

final class SafetyTests: XCTestCase {
    func testAllUserFacingCopyPassesClaimsPolicy() {
        for text in UserFacingCopy.allStrings {
            XCTAssertEqual(ClaimsPolicy.violations(in: text), [], "Banned claim in: \(text)")
        }
    }

    func testClaimsPolicyDetectsBannedPhrasesOnWordBoundaries() {
        XCTAssertEqual(ClaimsPolicy.violations(in: "Clinically PROVEN focus"), ["clinically proven"])
        XCTAssertTrue(ClaimsPolicy.violations(in: "It cures insomnia").contains("cures"))
        XCTAssertEqual(ClaimsPolicy.violations(in: "Your data is secure and accurate"), [])
    }

    func testEveryEvidenceCardHasSources() {
        for card in UserFacingCopy.evidenceCards {
            XCTAssertFalse(card.sources.isEmpty, card.id)
        }
    }

    func testCopyNeverNamesCompetitors() {
        for text in UserFacingCopy.allStrings + UserFacingCopy.evidenceCards.flatMap(\.sources) {
            XCTAssertFalse(text.lowercased().contains("brain.fm"), text)
        }
    }

    func testAllowedTimeFollowsThreeDecibelExchange() {
        let hour = 3_600.0
        XCTAssertEqual(ExposureMeter.allowedSeconds(levelDB: 80, referenceDB: 80), 40 * hour, accuracy: 1e-6)
        XCTAssertEqual(ExposureMeter.allowedSeconds(levelDB: 83, referenceDB: 80), 20 * hour, accuracy: 1e-6)
        XCTAssertEqual(ExposureMeter.allowedSeconds(levelDB: 75, referenceDB: 75), 40 * hour, accuracy: 1e-6)
    }

    func testDoseAccumulatesAndStatusChanges() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var meter = ExposureMeter(profile: .adult, calibrationOffsetDB: 100, systemVolume: 1, now: now)
        // RMS 0.1 → −20 dBFS → estimated 80 dB → 40 h allowance.
        XCTAssertEqual(meter.estimatedLevelDB(rms: 0.1), 80, accuracy: 1e-9)
        meter.accumulate(rms: 0.1, seconds: 32 * 3_600, now: now)
        XCTAssertEqual(meter.doseFraction, 0.8, accuracy: 1e-9)
        XCTAssertEqual(meter.status, .approaching)
        meter.accumulate(rms: 0.1, seconds: 8 * 3_600, now: now)
        XCTAssertEqual(meter.status, .exceeded)
        meter.accumulate(rms: 0, seconds: 1_000, now: now)
        XCTAssertEqual(meter.doseFraction, 1, accuracy: 1e-9)
    }

    func testDoseResetsWeekly() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var meter = ExposureMeter(now: now)
        meter.accumulate(rms: 0.1, seconds: 3_600, now: now)
        XCTAssertGreaterThan(meter.doseFraction, 0)
        meter.accumulate(rms: 0.1, seconds: 0, now: now.addingTimeInterval(8 * 86_400))
        XCTAssertEqual(meter.doseFraction, 0)
    }

    func testSensitiveProfileIsStricter() {
        let now = Date()
        var adult = ExposureMeter(profile: .adult, now: now)
        var sensitive = ExposureMeter(profile: .sensitive, now: now)
        adult.accumulate(rms: 0.1, seconds: 3_600, now: now)
        sensitive.accumulate(rms: 0.1, seconds: 3_600, now: now)
        XCTAssertGreaterThan(sensitive.doseFraction, adult.doseFraction * 3)
    }
}

final class StorageTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("bw-tests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testRoundTripExportAndDelete() throws {
        let store = JSONFileStore(directory: directory)
        XCTAssertEqual(try store.load(), UserData())
        var data = UserData()
        data.settings.amTextureAllowed = true
        data.append(SessionRecord(mode: .relax, arm: .darker, start: Date(timeIntervalSince1970: 1_000),
                                  durationSeconds: 900, overridden: false,
                                  feedback: SessionFeedback(primary: 4, enjoyment: 5)))
        data.bandit.update(mode: .relax, arm: .darker, reward: 0.9)
        try store.save(data)
        XCTAssertEqual(try store.load(), data)
        XCTAssertFalse(try store.exportData().isEmpty)

        let attributes = try FileManager.default.attributesOfItem(atPath: store.fileURL.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)

        try store.deleteAll()
        XCTAssertEqual(try store.load(), UserData())
    }

    func testRefusesNewerSchema() throws {
        let store = JSONFileStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(#"{"schemaVersion": 99}"#.utf8).write(to: store.fileURL)
        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(error as? StoreError, .unsupportedSchema(99))
        }
    }

    func testSessionHistoryIsCapped() {
        var data = UserData()
        for i in 0..<(UserData.maxSessions + 20) {
            data.append(SessionRecord(mode: .focus, arm: .base, start: Date(timeIntervalSince1970: Double(i)),
                                      durationSeconds: 60, overridden: false))
        }
        XCTAssertEqual(data.sessions.count, UserData.maxSessions)
        XCTAssertEqual(data.sessions.first?.start, Date(timeIntervalSince1970: 20))
    }
}
