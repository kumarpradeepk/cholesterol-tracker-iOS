import SwiftUI
import SwiftData

struct AddReadingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(UserSettings.self) private var settings

    /// When set, the view edits an existing reading.
    var existing: LipidReading? = nil

    @State private var date = Date()
    @State private var totalText = ""
    @State private var ldlText = ""
    @State private var hdlText = ""
    @State private var trigText = ""
    @State private var fasting = true
    @State private var note = ""
    @State private var validationError: String?
    @State private var loaded = false

    private func parse(_ text: String, _ metric: MetricType) -> Double? {
        guard let value = Double(text.replacingOccurrences(of: ",", with: ".")) else { return nil }
        return LipidMath.fromDisplay(value, metric: metric, unit: settings.unit)
    }

    private var totalMgdl: Double? { parse(totalText, .total) }
    private var ldlMgdl: Double? { parse(ldlText, .ldl) }
    private var hdlMgdl: Double? { parse(hdlText, .hdl) }
    private var trigMgdl: Double? { parse(trigText, .triglycerides) }

    private var autoLdl: Double? {
        guard ldlText.isEmpty, let total = totalMgdl, let hdl = hdlMgdl, let trig = trigMgdl else { return nil }
        return LipidMath.friedewaldLdl(total: total, hdl: hdl, triglycerides: trig)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date & time", selection: $date)
                    Toggle(isOn: $fasting) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fasting test")
                            Text("9–12 hours without food before the draw")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Lipid panel (\(settings.unit.label))") {
                    metricField("Total cholesterol", text: $totalText, metric: .total, value: totalMgdl)
                    metricField("LDL — leave empty to auto-calculate", text: $ldlText, metric: .ldl, value: ldlMgdl)
                    if let autoLdl {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("LDL (calculated)").font(.caption).foregroundStyle(.secondary)
                                Text("\(LipidMath.format(autoLdl, metric: .ldl, unit: settings.unit, withUnit: true)) via Friedewald")
                                    .font(.subheadline.weight(.medium))
                            }
                            Spacer()
                            RiskChip(band: LipidMath.classify(.ldl, valueMgdl: autoLdl, sex: settings.sex), compact: true)
                        }
                        .listRowBackground(MetricType.ldl.color.opacity(0.08))
                    }
                    metricField("HDL", text: $hdlText, metric: .hdl, value: hdlMgdl)
                    metricField("Triglycerides", text: $trigText, metric: .triglycerides, value: trigMgdl)
                }

                Section("Note") {
                    TextField("Lab, medication changes…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let validationError {
                    Text(validationError).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle(existing == nil ? "Log lipid panel" : "Edit reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold()
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    @ViewBuilder
    private func metricField(_ label: String, text: Binding<String>, metric: MetricType, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(label, text: text)
                .keyboardType(.decimalPad)
            if let value {
                RiskChip(band: LipidMath.classify(metric, valueMgdl: value, sex: settings.sex), compact: true)
            }
        }
    }

    private func loadExisting() {
        guard let existing, !loaded else { return }
        loaded = true
        date = existing.date
        fasting = existing.fasting
        note = existing.note ?? ""
        func display(_ v: Double?, _ m: MetricType) -> String {
            guard let v else { return "" }
            return settings.unit == .mgdl
                ? String(Int(v.rounded()))
                : String(format: "%.2f", LipidMath.toDisplay(v, metric: m, unit: settings.unit))
        }
        totalText = display(existing.totalMgdl, .total)
        ldlText = existing.ldlCalculated ? "" : display(existing.ldlMgdl, .ldl)
        hdlText = display(existing.hdlMgdl, .hdl)
        trigText = display(existing.trigMgdl, .triglycerides)
    }

    private func save() {
        guard totalMgdl != nil || ldlMgdl != nil || hdlMgdl != nil || trigMgdl != nil else {
            validationError = "Enter at least one value."
            return
        }
        func outOfRange(_ v: Double?, _ m: MetricType) -> Bool {
            guard let v else { return false }
            return !LipidMath.inputRange(metric: m, unit: settings.unit)
                .contains(LipidMath.toDisplay(v, metric: m, unit: settings.unit))
        }
        if outOfRange(totalMgdl, .total) || outOfRange(ldlMgdl, .ldl) ||
            outOfRange(hdlMgdl, .hdl) || outOfRange(trigMgdl, .triglycerides) {
            validationError = "One or more values look out of range — please double-check."
            return
        }
        validationError = nil

        let ldlValue = ldlMgdl ?? autoLdl
        let calculated = ldlMgdl == nil && autoLdl != nil
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing {
            existing.date = date
            existing.totalMgdl = totalMgdl
            existing.ldlMgdl = ldlValue
            existing.hdlMgdl = hdlMgdl
            existing.trigMgdl = trigMgdl
            existing.ldlCalculated = calculated
            existing.fasting = fasting
            existing.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            context.insert(LipidReading(
                date: date,
                totalMgdl: totalMgdl,
                ldlMgdl: ldlValue,
                hdlMgdl: hdlMgdl,
                trigMgdl: trigMgdl,
                ldlCalculated: calculated,
                fasting: fasting,
                note: trimmedNote.isEmpty ? nil : trimmedNote
            ))
        }
        dismiss()
    }
}
