import Foundation
import SwiftData

/// A lipid panel blood test reading. All values canonical mg/dL.
@Model
final class LipidReading {
    var date: Date
    var totalMgdl: Double?
    var ldlMgdl: Double?
    var hdlMgdl: Double?
    var trigMgdl: Double?
    /// True when LDL was derived via Friedewald rather than lab-measured.
    var ldlCalculated: Bool
    var fasting: Bool
    var note: String?

    init(
        date: Date = .now,
        totalMgdl: Double? = nil,
        ldlMgdl: Double? = nil,
        hdlMgdl: Double? = nil,
        trigMgdl: Double? = nil,
        ldlCalculated: Bool = false,
        fasting: Bool = true,
        note: String? = nil
    ) {
        self.date = date
        self.totalMgdl = totalMgdl
        self.ldlMgdl = ldlMgdl
        self.hdlMgdl = hdlMgdl
        self.trigMgdl = trigMgdl
        self.ldlCalculated = ldlCalculated
        self.fasting = fasting
        self.note = note
    }

    var score: Int? {
        LipidMath.lipidScore(total: totalMgdl, ldl: ldlMgdl, hdl: hdlMgdl, triglycerides: trigMgdl)
    }
}

/// A logged food diary entry (denormalized nutrition snapshot at log time).
@Model
final class FoodEntry {
    var date: Date
    /// Local date key yyyy-MM-dd for grouping and daily totals.
    var dateKey: String
    var mealTypeRaw: String
    var foodId: String?
    var name: String
    var brand: String?
    var servingDescription: String
    var quantity: Double
    var caloriesKcal: Double
    var cholesterolMg: Double
    var satFatG: Double
    var totalFatG: Double
    var sodiumMg: Double?
    var fiberG: Double?
    var sourceRaw: String

    init(
        date: Date = .now,
        dateKey: String,
        mealType: MealType,
        foodId: String?,
        name: String,
        brand: String?,
        servingDescription: String,
        quantity: Double,
        caloriesKcal: Double,
        cholesterolMg: Double,
        satFatG: Double,
        totalFatG: Double,
        sodiumMg: Double? = nil,
        fiberG: Double? = nil,
        source: FoodSource
    ) {
        self.date = date
        self.dateKey = dateKey
        self.mealTypeRaw = mealType.rawValue
        self.foodId = foodId
        self.name = name
        self.brand = brand
        self.servingDescription = servingDescription
        self.quantity = quantity
        self.caloriesKcal = caloriesKcal
        self.cholesterolMg = cholesterolMg
        self.satFatG = satFatG
        self.totalFatG = totalFatG
        self.sodiumMg = sodiumMg
        self.fiberG = fiberG
        self.sourceRaw = source.rawValue
    }

    var mealType: MealType { MealType(rawValue: mealTypeRaw) ?? .snack }

    static func dateKey(for date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

@Model
final class Medication {
    var name: String
    var dosage: String
    /// Dose times as "HH:mm" strings.
    var times: [String]
    var reminderEnabled: Bool
    var notes: String?
    var active: Bool
    var colorIndex: Int
    @Relationship(deleteRule: .cascade, inverse: \MedDoseLog.medication)
    var doseLogs: [MedDoseLog] = []

    init(
        name: String,
        dosage: String,
        times: [String] = ["08:00"],
        reminderEnabled: Bool = true,
        notes: String? = nil,
        active: Bool = true,
        colorIndex: Int = 0
    ) {
        self.name = name
        self.dosage = dosage
        self.times = times
        self.reminderEnabled = reminderEnabled
        self.notes = notes
        self.active = active
        self.colorIndex = colorIndex
    }
}

@Model
final class MedDoseLog {
    var dateKey: String
    var timeSlot: String
    var statusRaw: String
    var date: Date
    var medication: Medication?

    init(dateKey: String, timeSlot: String, status: DoseStatus, date: Date = .now, medication: Medication?) {
        self.dateKey = dateKey
        self.timeSlot = timeSlot
        self.statusRaw = status.rawValue
        self.date = date
        self.medication = medication
    }

    var status: DoseStatus { DoseStatus(rawValue: statusRaw) ?? .taken }
}

/// Favorite / recent food snapshot for one serving, for quick re-logging.
@Model
final class FavoriteFood {
    @Attribute(.unique) var foodKey: String
    var name: String
    var brand: String?
    var servingDescription: String
    var caloriesKcal: Double
    var cholesterolMg: Double
    var satFatG: Double
    var totalFatG: Double
    var sourceRaw: String
    var pinned: Bool
    var lastUsed: Date

    init(
        foodKey: String,
        name: String,
        brand: String?,
        servingDescription: String,
        caloriesKcal: Double,
        cholesterolMg: Double,
        satFatG: Double,
        totalFatG: Double,
        source: FoodSource,
        pinned: Bool = false,
        lastUsed: Date = .now
    ) {
        self.foodKey = foodKey
        self.name = name
        self.brand = brand
        self.servingDescription = servingDescription
        self.caloriesKcal = caloriesKcal
        self.cholesterolMg = cholesterolMg
        self.satFatG = satFatG
        self.totalFatG = totalFatG
        self.sourceRaw = source.rawValue
        self.pinned = pinned
        self.lastUsed = lastUsed
    }
}
