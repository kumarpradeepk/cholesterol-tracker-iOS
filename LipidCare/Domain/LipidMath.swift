import Foundation

/// All lipid values are stored canonically in mg/dL.
/// Conversion: cholesterol 1 mmol/L = 38.67 mg/dL, triglycerides 1 mmol/L = 88.57 mg/dL.
/// Classification thresholds follow NCEP ATP III guidelines (identical to the Android app).
enum LipidMath {

    static let cholesterolMgdlPerMmol = 38.67
    static let triglycerideMgdlPerMmol = 88.57

    // MARK: Unit conversion

    static func toDisplay(_ valueMgdl: Double, metric: MetricType, unit: UnitSystem) -> Double {
        switch unit {
        case .mgdl: return valueMgdl
        case .mmol:
            return metric.isTriglyceride
                ? valueMgdl / triglycerideMgdlPerMmol
                : valueMgdl / cholesterolMgdlPerMmol
        }
    }

    static func fromDisplay(_ displayValue: Double, metric: MetricType, unit: UnitSystem) -> Double {
        switch unit {
        case .mgdl: return displayValue
        case .mmol:
            return metric.isTriglyceride
                ? displayValue * triglycerideMgdlPerMmol
                : displayValue * cholesterolMgdlPerMmol
        }
    }

    static func format(_ valueMgdl: Double, metric: MetricType, unit: UnitSystem, withUnit: Bool = false) -> String {
        let v = toDisplay(valueMgdl, metric: metric, unit: unit)
        let text = unit == .mgdl ? String(Int(v.rounded())) : String(format: "%.2f", v)
        return withUnit ? "\(text) \(unit.label)" : text
    }

    /// Sensible display input range per metric, in the display unit, for validation.
    static func inputRange(metric: MetricType, unit: UnitSystem) -> ClosedRange<Double> {
        let mgdlRange: ClosedRange<Double>
        switch metric {
        case .total: mgdlRange = 50...500
        case .ldl: mgdlRange = 20...400
        case .hdl: mgdlRange = 10...150
        case .triglycerides: mgdlRange = 20...1500
        case .nonHdl: mgdlRange = 20...450
        }
        return toDisplay(mgdlRange.lowerBound, metric: metric, unit: unit)...toDisplay(mgdlRange.upperBound, metric: metric, unit: unit)
    }

    // MARK: Derived values (mg/dL)

    /// Friedewald equation. Not valid when triglycerides exceed 400 mg/dL.
    static func friedewaldLdl(total: Double, hdl: Double, triglycerides: Double) -> Double? {
        guard triglycerides <= 400 else { return nil }
        let ldl = total - hdl - triglycerides / 5.0
        return ldl > 0 ? ldl : nil
    }

    static func vldl(triglycerides: Double) -> Double { triglycerides / 5.0 }

    static func nonHdl(total: Double, hdl: Double) -> Double { total - hdl }

    static func tcHdlRatio(total: Double, hdl: Double) -> Double? { hdl > 0 ? total / hdl : nil }
    static func ldlHdlRatio(ldl: Double, hdl: Double) -> Double? { hdl > 0 ? ldl / hdl : nil }
    static func tgHdlRatio(triglycerides: Double, hdl: Double) -> Double? { hdl > 0 ? triglycerides / hdl : nil }

    // MARK: Classification (NCEP ATP III)

    static func classify(_ metric: MetricType, valueMgdl: Double, sex: Sex = .unspecified) -> RiskBand {
        switch metric {
        case .total:
            switch valueMgdl {
            case ..<200: return RiskBand(label: "Desirable", level: .good)
            case ..<240: return RiskBand(label: "Borderline high", level: .warn)
            default: return RiskBand(label: "High", level: .bad)
            }
        case .ldl:
            switch valueMgdl {
            case ..<100: return RiskBand(label: "Optimal", level: .good)
            case ..<130: return RiskBand(label: "Near optimal", level: .ok)
            case ..<160: return RiskBand(label: "Borderline high", level: .warn)
            case ..<190: return RiskBand(label: "High", level: .bad)
            default: return RiskBand(label: "Very high", level: .severe)
            }
        case .hdl:
            let lowThreshold: Double = sex == .female ? 50 : 40
            if valueMgdl >= 60 { return RiskBand(label: "Protective", level: .good) }
            if valueMgdl >= lowThreshold { return RiskBand(label: "Acceptable", level: .ok) }
            return RiskBand(label: "Low", level: .bad)
        case .triglycerides:
            switch valueMgdl {
            case ..<150: return RiskBand(label: "Normal", level: .good)
            case ..<200: return RiskBand(label: "Borderline high", level: .warn)
            case ..<500: return RiskBand(label: "High", level: .bad)
            default: return RiskBand(label: "Very high", level: .severe)
            }
        case .nonHdl:
            switch valueMgdl {
            case ..<130: return RiskBand(label: "Optimal", level: .good)
            case ..<160: return RiskBand(label: "Above optimal", level: .ok)
            case ..<190: return RiskBand(label: "Borderline high", level: .warn)
            case ..<220: return RiskBand(label: "High", level: .bad)
            default: return RiskBand(label: "Very high", level: .severe)
            }
        }
    }

    static func classifyTcHdlRatio(_ ratio: Double) -> RiskBand {
        if ratio < 3.5 { return RiskBand(label: "Excellent", level: .good) }
        if ratio <= 5.0 { return RiskBand(label: "Average", level: .warn) }
        return RiskBand(label: "High risk", level: .bad)
    }

    static func classifyLdlHdlRatio(_ ratio: Double) -> RiskBand {
        if ratio < 2.5 { return RiskBand(label: "Excellent", level: .good) }
        if ratio <= 3.5 { return RiskBand(label: "Average", level: .warn) }
        return RiskBand(label: "High risk", level: .bad)
    }

    /// TG/HDL computed on mg/dL values; a marker of insulin resistance.
    static func classifyTgHdlRatio(_ ratio: Double) -> RiskBand {
        if ratio < 2.0 { return RiskBand(label: "Ideal", level: .good) }
        if ratio <= 4.0 { return RiskBand(label: "Borderline", level: .warn) }
        return RiskBand(label: "High", level: .bad)
    }

    // MARK: Composite Lipid Score (0–100)

    private static func points(_ level: RiskLevel) -> Double {
        switch level {
        case .good: return 100
        case .ok: return 80
        case .warn: return 55
        case .bad: return 30
        case .severe: return 10
        }
    }

    /// Weighted composite of the four panel metrics (LDL 35%, TC 25%, HDL 20%, TG 20%).
    static func lipidScore(total: Double?, ldl: Double?, hdl: Double?, triglycerides: Double?, sex: Sex = .unspecified) -> Int? {
        var weighted = 0.0
        var totalWeight = 0.0
        func add(_ value: Double?, _ metric: MetricType, _ weight: Double) {
            guard let value else { return }
            weighted += points(classify(metric, valueMgdl: value, sex: sex).level) * weight
            totalWeight += weight
        }
        add(ldl, .ldl, 0.35)
        add(total, .total, 0.25)
        add(hdl, .hdl, 0.20)
        add(triglycerides, .triglycerides, 0.20)
        guard totalWeight > 0 else { return nil }
        return min(100, max(0, Int((weighted / totalWeight).rounded())))
    }

    static func scoreBand(_ score: Int) -> RiskBand {
        switch score {
        case 85...: return RiskBand(label: "Excellent", level: .good)
        case 70...: return RiskBand(label: "Good", level: .ok)
        case 50...: return RiskBand(label: "Fair", level: .warn)
        default: return RiskBand(label: "Needs attention", level: .bad)
        }
    }
}
