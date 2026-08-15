import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(UserSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \LipidReading.date, order: .reverse) private var readings: [LipidReading]

    @State private var selected: LipidReading?
    @State private var shareURL: URL?

    var body: some View {
        Group {
            if readings.isEmpty {
                EmptyStateView(
                    emoji: "🩸",
                    title: "No readings yet",
                    message: "Your lipid panel history will appear here after your first log."
                )
            } else {
                List {
                    ForEach(readings, id: \.persistentModelID) { reading in
                        Button {
                            selected = reading
                        } label: {
                            ReadingRow(reading: reading, unit: settings.unit, sex: settings.sex)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        for index in offsets { context.delete(readings[index]) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    shareURL = ExportService.pdfReport(readings: readings, settings: settings)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(readings.isEmpty)
            }
        }
        .sheet(item: $selected) { reading in
            ReadingDetailSheet(reading: reading)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: Binding(get: { shareURL != nil }, set: { if !$0 { shareURL = nil } })) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }
}

private struct ReadingRow: View {
    let reading: LipidReading
    let unit: UnitSystem
    let sex: Sex

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(reading.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if reading.fasting {
                    Text("Fasting").font(.caption2).foregroundStyle(.secondary)
                }
                if let score = reading.score {
                    RiskChip(band: LipidMath.scoreBand(score), compact: true)
                }
            }
            HStack {
                cell(.total, reading.totalMgdl)
                Spacer()
                cell(.ldl, reading.ldlMgdl)
                Spacer()
                cell(.hdl, reading.hdlMgdl)
                Spacer()
                cell(.triglycerides, reading.trigMgdl)
            }
        }
        .padding(.vertical, 4)
    }

    private func cell(_ metric: MetricType, _ value: Double?) -> some View {
        VStack(spacing: 2) {
            MetricLabel(metric: metric)
            Text(value.map { LipidMath.format($0, metric: metric, unit: unit) } ?? "—")
                .font(.headline)
        }
    }
}

struct ReadingDetailSheet: View {
    @Environment(UserSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let reading: LipidReading

    @State private var showEdit = false
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row(.total, reading.totalMgdl)
                    row(.ldl, reading.ldlMgdl, suffix: reading.ldlCalculated ? " (calculated)" : "")
                    row(.hdl, reading.hdlMgdl)
                    row(.triglycerides, reading.trigMgdl)
                }
                Section("Derived values") {
                    if let total = reading.totalMgdl, let hdl = reading.hdlMgdl {
                        derived("Non-HDL cholesterol",
                                LipidMath.format(LipidMath.nonHdl(total: total, hdl: hdl), metric: .nonHdl, unit: settings.unit, withUnit: true))
                        if let ratio = LipidMath.tcHdlRatio(total: total, hdl: hdl) {
                            derivedWithBand("Total/HDL ratio", String(format: "%.1f", ratio), LipidMath.classifyTcHdlRatio(ratio))
                        }
                    }
                    if let ldl = reading.ldlMgdl, let hdl = reading.hdlMgdl,
                       let ratio = LipidMath.ldlHdlRatio(ldl: ldl, hdl: hdl) {
                        derivedWithBand("LDL/HDL ratio", String(format: "%.1f", ratio), LipidMath.classifyLdlHdlRatio(ratio))
                    }
                    if let tg = reading.trigMgdl, let hdl = reading.hdlMgdl,
                       let ratio = LipidMath.tgHdlRatio(triglycerides: tg, hdl: hdl) {
                        derivedWithBand("TG/HDL ratio", String(format: "%.1f", ratio), LipidMath.classifyTgHdlRatio(ratio))
                    }
                    if let tg = reading.trigMgdl, tg <= 400 {
                        derived("VLDL (estimated)",
                                LipidMath.format(LipidMath.vldl(triglycerides: tg), metric: .triglycerides, unit: settings.unit, withUnit: true))
                    }
                }
                if let note = reading.note {
                    Section("Note") { Text(note) }
                }
            }
            .navigationTitle(reading.date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Edit", systemImage: "pencil") { showEdit = true }
                        Button("Delete", systemImage: "trash", role: .destructive) { confirmDelete = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                AddReadingView(existing: reading)
            }
            .confirmationDialog("Delete this reading?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    context.delete(reading)
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ metric: MetricType, _ value: Double?, suffix: String = "") -> some View {
        if let value {
            HStack {
                Text(metric.fullName + suffix)
                Spacer()
                Text(LipidMath.format(value, metric: metric, unit: settings.unit, withUnit: true))
                    .font(.subheadline.weight(.semibold))
                RiskChip(band: LipidMath.classify(metric, valueMgdl: value, sex: settings.sex), compact: true)
            }
        }
    }

    private func derived(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold))
        }
    }

    private func derivedWithBand(_ label: String, _ value: String, _ band: RiskBand) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(band.level.color)
            RiskChip(band: band, compact: true)
        }
    }
}

/// UIKit share sheet bridge.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
