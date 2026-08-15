import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(UserSettings.self) private var settings
    @Query(sort: \LipidReading.date, order: .reverse) private var readings: [LipidReading]
    @Query private var allFoodEntries: [FoodEntry]

    @State private var showAddReading = false

    private var latest: LipidReading? { readings.first }
    private var todayEntries: [FoodEntry] {
        let key = FoodEntry.dateKey()
        return allFoodEntries.filter { $0.dateKey == key }
    }
    private var weekEntries: [FoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now))!
        return allFoodEntries.filter { $0.date >= cutoff }
    }
    private var insights: [Insight] {
        let weekChol = weekEntries.isEmpty ? nil : weekEntries.reduce(0) { $0 + $1.cholesterolMg } / 7.0
        let weekSatFat = weekEntries.isEmpty ? nil : weekEntries.reduce(0) { $0 + $1.satFatG } / 7.0
        return InsightsEngine.generate(
            readings: readings,
            weeklyCholesterolAvgMg: weekChol,
            weeklySatFatAvgG: weekSatFat,
            settings: settings
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    greeting
                    heroCard
                    if latest != nil { metricChips }
                    dietCard
                    if !insights.isEmpty {
                        Text("Insights").font(.title3.bold()).padding(.horizontal, 4)
                        insightsRow
                    }
                    learnTeaser
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("LipidCare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddReading = true
                    } label: {
                        Label("Log panel", systemImage: "plus.circle.fill")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .sheet(isPresented: $showAddReading) {
                AddReadingView()
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hello\(settings.name.isEmpty ? "" : ", \(settings.name)") 👋")
                .font(.title2.bold())
            Text("Here's your heart health at a glance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var heroCard: some View {
        NavigationLink {
            HistoryView()
        } label: {
            Group {
                if let latest, let score = latest.score {
                    HStack(spacing: 16) {
                        ScoreGauge(score: score, label: "Lipid Score", size: 150)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LipidMath.scoreBand(score).label)
                                .font(.title3.bold())
                            Text("Last test \(latest.date.formatted(date: .abbreviated, time: .omitted))\(latest.fasting ? " • Fasting" : "")")
                                .font(.caption)
                                .opacity(0.85)
                            Text("Tap to view history →")
                                .font(.caption.weight(.medium))
                                .opacity(0.9)
                        }
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("🩸").font(.system(size: 40))
                        Text("No readings yet").font(.headline)
                        Text("Log your first lipid panel to see your Lipid Score")
                            .font(.subheadline)
                            .opacity(0.9)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Theme.crimson.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var metricChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if let r = latest {
                    metricChip(.total, r.totalMgdl)
                    metricChip(.ldl, r.ldlMgdl)
                    metricChip(.hdl, r.hdlMgdl)
                    metricChip(.triglycerides, r.trigMgdl)
                }
            }
        }
    }

    @ViewBuilder
    private func metricChip(_ metric: MetricType, _ value: Double?) -> some View {
        if let value {
            VStack(alignment: .leading, spacing: 6) {
                MetricLabel(metric: metric)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(LipidMath.format(value, metric: metric, unit: settings.unit))
                        .font(.title2.bold())
                        .contentTransition(.numericText())
                    Text(settings.unit.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                RiskChip(band: LipidMath.classify(metric, valueMgdl: value, sex: settings.sex), compact: true)
            }
            .padding(14)
            .lipidCard(cornerRadius: 18)
        }
    }

    private var dietCard: some View {
        let chol = todayEntries.reduce(0) { $0 + $1.cholesterolMg }
        let satFat = todayEntries.reduce(0) { $0 + $1.satFatG }
        let budget = settings.dailyCholesterolBudgetMg

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's diet").font(.headline)
                Text("\(Int(chol.rounded())) of \(Int(budget.rounded())) mg cholesterol")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Int(satFat.rounded())) g saturated fat of \(Int(settings.dailySatFatBudgetG.rounded())) g budget")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Log meals in the Diet tab", systemImage: "fork.knife")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.crimson)
            }
            Spacer()
            ProgressRing(progress: budget > 0 ? chol / budget : 0, size: 88) {
                VStack(spacing: 0) {
                    Text("\(Int(((budget > 0 ? chol / budget : 0) * 100).rounded()))%")
                        .font(.headline)
                    Text("of budget")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .lipidCard()
    }

    private var insightsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(insight.emoji)
                            Text(insight.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(insight.tone.color)
                        }
                        Text(insight.body)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(width: 270, alignment: .topLeading)
                    .background(insight.tone.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    private var learnTeaser: some View {
        NavigationLink {
            LearnView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .foregroundStyle(Theme.teal)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Understanding your numbers")
                        .font(.subheadline.weight(.semibold))
                    Text("What LDL, HDL and triglycerides actually mean — and 7 more guides")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Theme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
