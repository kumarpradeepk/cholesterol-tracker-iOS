import Foundation

/// Rule-based personalized insights generated from readings, diet totals and the profile.
/// Deliberately conservative: informational nudges only, never medical advice.
enum InsightsEngine {

    static func generate(
        readings: [LipidReading],              // newest first
        weeklyCholesterolAvgMg: Double?,        // avg dietary cholesterol per day over last 7 days
        weeklySatFatAvgG: Double?,
        settings: UserSettings
    ) -> [Insight] {
        var insights: [Insight] = []
        let unit = settings.unit
        let latest = readings.first

        // 1. Retest reminder
        if let latest {
            let months = Calendar.current.dateComponents([.day], from: latest.date, to: .now).day.map { $0 / 30 } ?? 0
            if months >= 6 {
                insights.append(Insight(
                    title: "Time for a retest",
                    body: "Your last lipid panel was over \(months) months ago. Guidelines suggest testing every 4–6 months while actively managing cholesterol.",
                    tone: .warning, emoji: "🗓️"
                ))
            }
        } else {
            insights.append(Insight(
                title: "Log your first panel",
                body: "Add your latest blood test results to unlock trends, your Lipid Score and personalized insights.",
                tone: .neutral, emoji: "🩸"
            ))
        }

        // 2. Metric trend analysis vs previous reading
        if readings.count >= 2 {
            let current = readings[0]
            let previous = readings[1]
            if let insight = trendInsight(current.ldlMgdl, previous.ldlMgdl, .ldl, unit, lowerIsBetter: true) {
                insights.append(insight)
            }
            if let insight = trendInsight(current.hdlMgdl, previous.hdlMgdl, .hdl, unit, lowerIsBetter: false) {
                insights.append(insight)
            }
            if let insight = trendInsight(current.trigMgdl, previous.trigMgdl, .triglycerides, unit, lowerIsBetter: true) {
                insights.append(insight)
            }
        }

        // 3. Current status callouts
        if let latest {
            if let ldl = latest.ldlMgdl {
                let band = LipidMath.classify(.ldl, valueMgdl: ldl, sex: settings.sex)
                if band.level >= .bad {
                    let target = settings.isHighRisk ? 70.0 : 100.0
                    insights.append(Insight(
                        title: "LDL is \(band.label.lowercased())",
                        body: "Your LDL of \(LipidMath.format(ldl, metric: .ldl, unit: unit, withUnit: true)) is above the typical target of \(LipidMath.format(target, metric: .ldl, unit: unit, withUnit: true))\(settings.isHighRisk ? " for your risk profile" : ""). Consider discussing a management plan with your doctor.",
                        tone: .alert, emoji: "⚠️"
                    ))
                }
            }
            if let hdl = latest.hdlMgdl, let tg = latest.trigMgdl, hdl > 0 {
                let ratio = tg / hdl
                if ratio > 4 {
                    insights.append(Insight(
                        title: "TG/HDL ratio is elevated",
                        body: "A triglyceride-to-HDL ratio of \(String(format: "%.1f", ratio)) can indicate insulin resistance. Regular aerobic exercise and cutting refined carbohydrates often help.",
                        tone: .warning, emoji: "📈"
                    ))
                }
            }
            if let hdl = latest.hdlMgdl,
               LipidMath.classify(.hdl, valueMgdl: hdl, sex: settings.sex).level == .good {
                insights.append(Insight(
                    title: "Great HDL level",
                    body: "Your HDL of \(LipidMath.format(hdl, metric: .hdl, unit: unit, withUnit: true)) is in the protective range. Keep up the activity and healthy fats!",
                    tone: .positive, emoji: "💪"
                ))
            }
        }

        // 4. Diet insights
        if let avg = weeklyCholesterolAvgMg, avg > 0 {
            let budget = settings.dailyCholesterolBudgetMg
            if avg > budget * 1.1 {
                insights.append(Insight(
                    title: "Dietary cholesterol above budget",
                    body: "You averaged \(Int(avg.rounded())) mg of dietary cholesterol per day this week, above your \(Int(budget.rounded())) mg budget. Egg yolks, organ meats and shellfish are the usual suspects.",
                    tone: .warning, emoji: "🍳"
                ))
            } else if avg < budget * 0.8 {
                insights.append(Insight(
                    title: "Diet on track",
                    body: "Nice work — you averaged \(Int(avg.rounded())) mg of dietary cholesterol per day this week, comfortably within your \(Int(budget.rounded())) mg budget.",
                    tone: .positive, emoji: "🥗"
                ))
            }
        }
        if let avg = weeklySatFatAvgG, avg > settings.dailySatFatBudgetG * 1.15 {
            insights.append(Insight(
                title: "Watch saturated fat",
                body: "Saturated fat averaged \(Int(avg.rounded())) g/day this week (budget \(Int(settings.dailySatFatBudgetG.rounded())) g). Saturated fat raises LDL more than dietary cholesterol itself — try swapping butter and fatty red meat for olive oil, fish and legumes.",
                tone: .warning, emoji: "🧈"
            ))
        }

        // 5. Educational nudge fallback
        if insights.count < 2 {
            insights.append(Insight(
                title: "Soluble fiber helps",
                body: "5–10 g of soluble fiber a day (oats, beans, apples, psyllium) can lower LDL by up to 5%. Small changes compound.",
                tone: .neutral, emoji: "🌾"
            ))
        }
        return insights
    }

    private static func trendInsight(
        _ current: Double?, _ previous: Double?, _ metric: MetricType,
        _ unit: UnitSystem, lowerIsBetter: Bool
    ) -> Insight? {
        guard let current, let previous, previous > 0 else { return nil }
        let changePct = (current - previous) / previous * 100
        guard abs(changePct) >= 5 else { return nil }
        let improved = lowerIsBetter ? changePct < 0 : changePct > 0
        let direction = changePct < 0 ? "down" : "up"
        return Insight(
            title: "\(metric.shortName) is \(direction) \(Int(abs(changePct).rounded()))%",
            body: "\(metric.fullName) moved from \(LipidMath.format(previous, metric: metric, unit: unit, withUnit: true)) to \(LipidMath.format(current, metric: metric, unit: unit, withUnit: true)) since your previous test.\(improved ? " Whatever you're doing — it's working." : " Worth keeping an eye on.")",
            tone: improved ? .positive : .warning,
            emoji: improved ? "🎉" : "👀"
        )
    }
}
