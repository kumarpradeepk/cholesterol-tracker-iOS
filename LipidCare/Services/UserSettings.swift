import Foundation
import Observation

/// App-wide user profile & preferences, persisted in UserDefaults and
/// observable by every view. Mirrors the Android DataStore preferences.
@Observable
final class UserSettings {
    static let shared = UserSettings()
    private let defaults = UserDefaults.standard

    var onboardingDone: Bool { didSet { defaults.set(onboardingDone, forKey: "onboardingDone") } }
    var name: String { didSet { defaults.set(name, forKey: "name") } }
    var sexRaw: String { didSet { defaults.set(sexRaw, forKey: "sex") } }
    var birthYear: Int { didSet { defaults.set(birthYear, forKey: "birthYear") } } // 0 = unset
    var unitRaw: String { didSet { defaults.set(unitRaw, forKey: "unitSystem") } }
    var themeRaw: String { didSet { defaults.set(themeRaw, forKey: "themeMode") } }
    var riskFactorsRaw: [String] { didSet { defaults.set(riskFactorsRaw, forKey: "riskFactors") } }
    var dailyCholesterolBudgetMg: Double { didSet { defaults.set(dailyCholesterolBudgetMg, forKey: "cholBudget") } }
    var dailySatFatBudgetG: Double { didSet { defaults.set(dailySatFatBudgetG, forKey: "satFatBudget") } }
    var ldlTargetMgdl: Double { didSet { defaults.set(ldlTargetMgdl, forKey: "ldlTarget") } }
    var dailyLogReminderEnabled: Bool { didSet { defaults.set(dailyLogReminderEnabled, forKey: "dailyReminderEnabled") } }
    var dailyLogReminderTime: String { didSet { defaults.set(dailyLogReminderTime, forKey: "dailyReminderTime") } }

    private init() {
        onboardingDone = defaults.bool(forKey: "onboardingDone")
        name = defaults.string(forKey: "name") ?? ""
        sexRaw = defaults.string(forKey: "sex") ?? Sex.unspecified.rawValue
        birthYear = defaults.integer(forKey: "birthYear")
        unitRaw = defaults.string(forKey: "unitSystem") ?? UnitSystem.mgdl.rawValue
        themeRaw = defaults.string(forKey: "themeMode") ?? ThemeMode.system.rawValue
        riskFactorsRaw = defaults.stringArray(forKey: "riskFactors") ?? []
        dailyCholesterolBudgetMg = defaults.object(forKey: "cholBudget") as? Double ?? 300
        dailySatFatBudgetG = defaults.object(forKey: "satFatBudget") as? Double ?? 13
        ldlTargetMgdl = defaults.object(forKey: "ldlTarget") as? Double ?? 100
        dailyLogReminderEnabled = defaults.bool(forKey: "dailyReminderEnabled")
        dailyLogReminderTime = defaults.string(forKey: "dailyReminderTime") ?? "20:00"
    }

    // Typed accessors
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
