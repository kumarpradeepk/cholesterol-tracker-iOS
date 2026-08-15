import SwiftUI

// MARK: - Core enums shared with the Android app (identical semantics)

enum UnitSystem: String, CaseIterable, Identifiable {
    case mgdl = "MG_DL"
    case mmol = "MMOL_L"
    var id: String { rawValue }
    var label: String { self == .mgdl ? "mg/dL" : "mmol/L" }
}

enum Sex: String, CaseIterable, Identifiable {
    case male = "MALE"
    case female = "FEMALE"
    case unspecified = "UNSPECIFIED"
    var id: String { rawValue }
}

enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "SYSTEM"
    case light = "LIGHT"
    case dark = "DARK"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum MetricType: String, CaseIterable, Identifiable {
    case total, ldl, hdl, triglycerides, nonHdl
    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .total: return "Total Cholesterol"
        case .ldl: return "LDL Cholesterol"
        case .hdl: return "HDL Cholesterol"
        case .triglycerides: return "Triglycerides"
        case .nonHdl: return "Non-HDL Cholesterol"
        }
    }
    var shortName: String {
        switch self {
        case .total: return "Total"
        case .ldl: return "LDL"
        case .hdl: return "HDL"
        case .triglycerides: return "TG"
        case .nonHdl: return "Non-HDL"
        }
    }
    var isTriglyceride: Bool { self == .triglycerides }

    var color: Color {
        switch self {
        case .total: return Theme.crimson
        case .ldl: return Theme.metricLdl
        case .hdl: return Theme.teal
        case .triglycerides: return Theme.indigo
        case .nonHdl: return Theme.metricNonHdl
        }
    }
}

enum RiskLevel: Int, Comparable {
    case good = 0, ok, warn, bad, severe
    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var color: Color {
        switch self {
        case .good: return Theme.riskGood
        case .ok: return Theme.riskOk
        case .warn: return Theme.riskWarn
        case .bad: return Theme.riskBad
        case .severe: return Theme.riskSevere
        }
    }
}

struct RiskBand: Equatable {
    let label: String
    let level: RiskLevel
}

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "BREAKFAST"
    case lunch = "LUNCH"
    case dinner = "DINNER"
    case snack = "SNACK"
    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
    var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snack: return "🍎"
        }
    }

    static var forCurrentTime: MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case ..<11: return .breakfast
        case ..<15: return .lunch
        case ..<20: return .snack
        default: return .dinner
        }
    }
}

enum FoodSource: String {
    case builtIn = "BUILT_IN"
    case fatSecret = "FATSECRET"
    case custom = "CUSTOM"
}

enum DoseStatus: String {
    case taken = "TAKEN"
    case skipped = "SKIPPED"
}

enum RiskFactorOption: String, CaseIterable, Identifiable {
    case smoker = "SMOKER"
    case diabetes = "DIABETES"
    case hypertension = "HYPERTENSION"
    case familyHistory = "FAMILY_HISTORY"
    case heartDisease = "HEART_DISEASE"
    case overweight = "OVERWEIGHT"
    var id: String { rawValue }

    var label: String {
        switch self {
        case .smoker: return "Smoker"
        case .diabetes: return "Diabetes"
        case .hypertension: return "High blood pressure"
        case .familyHistory: return "Family history of heart disease"
        case .heartDisease: return "Existing heart disease"
        case .overweight: return "Overweight"
        }
    }
}

// MARK: - Food value types

struct FoodServing: Hashable {
    let servingDescription: String
    let metricGrams: Double?
    let calories: Double
    let cholesterolMg: Double
    let saturatedFatG: Double
    let totalFatG: Double
    var sodiumMg: Double? = nil
    var fiberG: Double? = nil
}

struct FoodItem: Identifiable {
    let id: String
    let name: String
    var brand: String? = nil
    let source: FoodSource
    let servings: [FoodServing]
}

struct FoodSearchResult: Identifiable {
    let id: String
    let name: String
    let brand: String?
    let summary: String
    let source: FoodSource
}

// MARK: - Insights

enum InsightTone {
    case positive, neutral, warning, alert

    var color: Color {
        switch self {
        case .positive: return Theme.riskGood
        case .neutral: return Theme.indigo
        case .warning: return Theme.riskWarn
        case .alert: return Theme.riskSevere
        }
    }
}

struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let tone: InsightTone
    let emoji: String
}
