import Foundation
import Observation

/// App-wide user profile & preferences, persisted in UserDefaults and
/// observable by every view. Mirrors the Android DataStore preferences.
///
/// Properties are computed straight over UserDefaults with explicit
/// `access`/`withMutation` calls so SwiftUI observation works — the
/// `@Observable` macro cannot synthesize accessors for stored properties
/// that carry `didSet` observers.
@Observable
final class UserSettings {
    static let shared = UserSettings()
    private let defaults = UserDefaults.standard

    private init() {}

    var onboardingDone: Bool {
        get { access(keyPath: \.onboardingDone); return defaults.bool(forKey: "onboardingDone") }
        set { withMutation(keyPath: \.onboardingDone) { defaults.set(newValue, forKey: "onboardingDone") } }
    }
    var name: String {
        get { access(keyPath: \.name); return defaults.string(forKey: "name") ?? "" }
        set { withMutation(keyPath: \.name) { defaults.set(newValue, forKey: "name") } }
    }
    var sexRaw: String {
        get { access(keyPath: \.sexRaw); return defaults.string(forKey: "sex") ?? Sex.unspecified.rawValue }
        set { withMutation(keyPath: \.sexRaw) { defaults.set(newValue, forKey: "sex") } }
    }
    /// 0 = unset
    var birthYear: Int {
        get { access(keyPath: \.birthYear); return defaults.integer(forKey: "birthYear") }
        set { withMutation(keyPath: \.birthYear) { defaults.set(newValue, forKey: "birthYear") } }
    }
    var unitRaw: String {
        get { access(keyPath: \.unitRaw); return defaults.string(forKey: "unitSystem") ?? UnitSystem.mgdl.rawValue }
        set { withMutation(keyPath: \.unitRaw) { defaults.set(newValue, forKey: "unitSystem") } }
    }
    var themeRaw: String {
        get { access(keyPath: \.themeRaw); return defaults.string(forKey: "themeMode") ?? ThemeMode.system.rawValue }
        set { withMutation(keyPath: \.themeRaw) { defaults.set(newValue, forKey: "themeMode") } }
    }
    var riskFactorsRaw: [String] {
        get { access(keyPath: \.riskFactorsRaw); return defaults.stringArray(forKey: "riskFactors") ?? [] }
        set { withMutation(keyPath: \.riskFactorsRaw) { defaults.set(newValue, forKey: "riskFactors") } }
    }
    var dailyCholesterolBudgetMg: Double {
        get { access(keyPath: \.dailyCholesterolBudgetMg); return defaults.object(forKey: "cholBudget") as? Double ?? 300 }
        set { withMutation(keyPath: \.dailyCholesterolBudgetMg) { defaults.set(newValue, forKey: "cholBudget") } }
    }
    var dailySatFatBudgetG: Double {
        get { access(keyPath: \.dailySatFatBudgetG); return defaults.object(forKey: "satFatBudget") as? Double ?? 13 }
        set { withMutation(keyPath: \.dailySatFatBudgetG) { defaults.set(newValue, forKey: "satFatBudget") } }
    }
    var ldlTargetMgdl: Double {
        get { access(keyPath: \.ldlTargetMgdl); return defaults.object(forKey: "ldlTarget") as? Double ?? 100 }
        set { withMutation(keyPath: \.ldlTargetMgdl) { defaults.set(newValue, forKey: "ldlTarget") } }
    }
    var dailyLogReminderEnabled: Bool {
        get { access(keyPath: \.dailyLogReminderEnabled); return defaults.bool(forKey: "dailyReminderEnabled") }
        set { withMutation(keyPath: \.dailyLogReminderEnabled) { defaults.set(newValue, forKey: "dailyReminderEnabled") } }
    }
    var dailyLogReminderTime: String {
        get { access(keyPath: \.dailyLogReminderTime); return defaults.string(forKey: "dailyReminderTime") ?? "20:00" }
        set { withMutation(keyPath: \.dailyLogReminderTime) { defaults.set(newValue, forKey: "dailyReminderTime") } }
    }

    // MARK: Typed accessors

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .unspecified }
        set { sexRaw = newValue.rawValue }
    }
    var unit: UnitSystem {
        get { UnitSystem(rawValue: unitRaw) ?? .mgdl }
        set { unitRaw = newValue.rawValue }
    }
    var themeMode: ThemeMode {
        get { ThemeMode(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue }
    }
    var riskFactors: Set<RiskFactorOption> {
        get { Set(riskFactorsRaw.compactMap(RiskFactorOption.init(rawValue:))) }
        set { riskFactorsRaw = newValue.map(\.rawValue).sorted() }
    }
    var age: Int? {
        guard birthYear > 1900 else { return nil }
        return Calendar.current.component(.year, from: Date()) - birthYear
    }
    var isHighRisk: Bool {
        riskFactors.contains(.heartDisease) || riskFactors.contains(.diabetes)
    }
}
