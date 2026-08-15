import SwiftUI
import SwiftData
import Charts

private enum TimeRange: String, CaseIterable, Identifiable {
    case m1 = "1M", m3 = "3M", m6 = "6M", y1 = "1Y", all = "All"
    var id: String { rawValue }
    var months: Int? {
        switch self {
        case .m1: return 1
        case .m3: return 3
        case .m6: return 6
        case .y1: return 12
        case .all: return nil
        }
    }
}

struct TrendsView: View {
    @Environment(UserSettings.self) private var settings
    @Query(sort: \LipidReading.date) private var readings: [LipidReading]

    @State private var metric: MetricType = .ldl
    @State private var range: TimeRange = .m6
    @State private var selectedDate: Date?

    private var filtered: [(date: Date, value: Double)] {
        let cutoff = range.months.flatMap {
            Calendar.current.date(byAdding: .month, value: -$0, to: .now)
        } ?? .distantPast
        return readings
            .filter { $0.date >= cutoff }
            .compactMap { reading in
                let mgdl: Double?
                switch metric {
                case .total: mgdl = reading.totalMgdl
                case .ldl: mgdl = reading.ldlMgdl
                case .hdl: mgdl = reading.hdlMgdl
                case .triglycerides: mgdl = reading.trigMgdl
                case .nonHdl:
                    if let t = reading.totalMgdl, let h = reading.hdlMgdl {
                        mgdl = LipidMath.nonHdl(total: t, hdl: h)
                    } else { mgdl = nil }
                }
                return mgdl.map { (reading.date, LipidMath.toDisplay($0, metric: metric, unit: settings.unit)) }
            }
    }

    /// The "good zone" band in display units.
    private var goodZone: ClosedRange<Double> {
        let mgdl: ClosedRange<Double>
        switch metric {
        case .total: mgdl = 0...200
        case .ldl: mgdl = 0...100
        case .hdl: mgdl = 60...150
        case .triglycerides: mgdl = 0...150
        case .nonHdl: mgdl = 0...130
        }
        return LipidMath.toDisplay(mgdl.lowerBound, metric: metric, unit: settings.unit)...LipidMath.toDisplay(mgdl.upperBound, metric: metric, unit: settings.unit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    metricSelector
                    Picker("Range", selection: $range) {
                        ForEach(TimeRange.allCases) { r in Text(r.rawValue).tag(r) }
                    }
                    .pickerStyle(.segmented)

                    if filtered.count < 2 {
                        EmptyStateView(
                            emoji: "📈",
                            title: "Not enough data",
                            message: "Log at least two readings with \(metric.fullName) in this period to see a trend."
                        )
                    } else {
                        chartCard
                        statsCard
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trends")
        }
    }

    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MetricType.allCases) { m in
                    Button {
                        withAnimation(.snappy) { metric = m }
                    } label: {
                        Text(m.shortName)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                metric == m ? m.color.opacity(0.18) : Color(.secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(metric == m ? m.color : .primary)
                    }
                }
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(metric.fullName).font(.headline)
                Spacer()
                Text(settings.unit.label).font(.caption).foregroundStyle(.secondary)
            }

            Chart {
                RectangleMark(
                    xStart: .value("Start", filtered.first!.date),
                    xEnd: .value("End", filtered.last!.date),
                    yStart: .value("Zone low", goodZone.lowerBound),
                    yEnd: .value("Zone high", goodZone.upperBound)
                )
                .foregroundStyle(Theme.riskGood.opacity(0.10))

                if metric == .ldl {
                    RuleMark(y: .value("Target", LipidMath.toDisplay(settings.ldlTargetMgdl, metric: .ldl, unit: settings.unit)))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                        .foregroundStyle(metric.color.opacity(0.7))
                        .annotation(position: .topTrailing) {
                            Text("Target")
                                .font(.caption2)
                                .foregroundStyle(metric.color)
                        }
                }

                ForEach(filtered, id: \.date) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(metric.color)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    AreaMark(x: .value("Date", point.date), y: .value("Value", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [metric.color.opacity(0.22), metric.color.opacity(0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    PointMark(x: .value("Date", point.date), y: .value("Value", point.value))
                        .foregroundStyle(metric.color)
                        .symbolSize(50)
                }

                if let selectedDate,
                   let nearest = filtered.min(by: {
                       abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
                   }) {
                    RuleMark(x: .value("Selected", nearest.date))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.secondary)
                    PointMark(x: .value("Date", nearest.date), y: .value("Value", nearest.value))
                        .symbolSize(140)
                        .foregroundStyle(metric.color.opacity(0.3))
                    PointMark(x: .value("Date", nearest.date), y: .value("Value", nearest.value))
                        .foregroundStyle(metric.color)
                        .annotation(position: .top) {
                            VStack(spacing: 0) {
                                Text(formatValue(nearest.value)).font(.caption.bold())
                                Text(nearest.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                            }
                            .padding(6)
                            .background(metric.color, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                        }
                }
            }
            .frame(height: 240)
            .chartXSelection(value: $selectedDate)
            .animation(.easeOut(duration: 0.5), value: metric)

            Text("Shaded area = \(metric == .hdl ? "protective" : "optimal") zone. Touch the chart to inspect a reading.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .lipidCard()
    }

    private var statsCard: some View {
        let values = filtered.map(\.value)
        let latest = values.last ?? 0
        let first = values.first ?? 0
        let change = latest - first
        let changeGood = metric == .hdl ? change >= 0 : change <= 0
        let latestMgdl = LipidMath.fromDisplay(latest, metric: metric, unit: settings.unit)

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Latest").font(.caption).foregroundStyle(.secondary)
                    Text(formatValue(latest) + " " + settings.unit.label)
                        .font(.title3.bold())
                }
                Spacer()
                RiskChip(band: LipidMath.classify(metric, valueMgdl: latestMgdl, sex: settings.sex))
            }
            HStack {
                stat("Average", formatValue(values.reduce(0, +) / Double(values.count)))
                Spacer()
                stat("Lowest", formatValue(values.min() ?? 0))
                Spacer()
                stat("Highest", formatValue(values.max() ?? 0))
                Spacer()
                stat(
                    "Change",
                    (change > 0 ? "+" : "") + formatValue(change),
                    color: changeGood ? Theme.riskGood : Theme.riskSevere
                )
            }
        }
        .padding(16)
        .lipidCard()
    }

    private func stat(_ label: String, _ value: String, color: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(color)
        }
    }

    private func formatValue(_ v: Double) -> String {
        settings.unit == .mgdl ? String(Int(v.rounded())) : String(format: "%.1f", v)
    }
}
