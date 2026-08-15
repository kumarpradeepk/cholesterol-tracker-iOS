import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(UserSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \LipidReading.date, order: .reverse) private var readings: [LipidReading]

    @State private var showApiSheet = false
    @State private var showDeleteAll = false
    @State private var shareURL: URL?
    @State private var reminderTime = Date()
    @State private var credentialsConfigured = KeychainStore.hasCredentials

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $settings.name)
                    Picker("Sex", selection: $settings.sex) {
                        Text("Male").tag(Sex.male)
                        Text("Female").tag(Sex.female)
                        Text("Not set").tag(Sex.unspecified)
                    }
                    Stepper(value: $settings.birthYear, in: 0...2030) {
                        HStack {
                            Text("Birth year")
                            Spacer()
                            Text(settings.birthYear > 1900 ? String(settings.birthYear) : "Not set")
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink {
                        riskFactorsView
                    } label: {
                        HStack {
                            Text("Risk factors")
                            Spacer()
                            Text(settings.riskFactors.isEmpty ? "None" : "\(settings.riskFactors.count) selected")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Units & targets") {
                    Picker("Measurement units", selection: $settings.unit) {
                        Text("mg/dL").tag(UnitSystem.mgdl)
                        Text("mmol/L").tag(UnitSystem.mmol)
                    }
                    .pickerStyle(.segmented)
                    ldlTargetRow
                    budgetRow(
                        "Daily cholesterol budget",
                        value: $settings.dailyCholesterolBudgetMg,
                        range: 100...1000, step: 25, unitLabel: "mg"
                    )
                    budgetRow(
                        "Daily saturated fat budget",
                        value: $settings.dailySatFatBudgetG,
                        range: 5...60, step: 1, unitLabel: "g"
                    )
                }

                Section("Appearance") {
                    Picker("Theme", selection: $settings.themeMode) {
                        Text("System").tag(ThemeMode.system)
                        Text("Light").tag(ThemeMode.light)
                        Text("Dark").tag(ThemeMode.dark)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Reminders") {
                    Toggle(isOn: Binding(
                        get: { settings.dailyLogReminderEnabled },
                        set: { enabled in
                            settings.dailyLogReminderEnabled = enabled
                            if enabled {
                                Task {
                                    if await ReminderService.requestAuthorization() {
                                        ReminderService.scheduleDailyLog(time: settings.dailyLogReminderTime)
                                    }
                                }
                            } else {
                                ReminderService.cancelDailyLog()
                            }
                        }
                    )) {
                        Text("Daily food log reminder")
                    }
                    if settings.dailyLogReminderEnabled {
                        DatePicker("Reminder time", selection: Binding(
                            get: {
                                let parts = settings.dailyLogReminderTime.split(separator: ":")
                                let hour = Int(parts.first ?? "20") ?? 20
                                let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
                                return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
                            },
                            set: { date in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                settings.dailyLogReminderTime = formatter.string(from: date)
                                ReminderService.scheduleDailyLog(time: settings.dailyLogReminderTime)
                            }
                        ), displayedComponents: .hourAndMinute)
                    }
                    Text("Medication reminders are configured per medication in the Meds tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Food database (FatSecret)") {
                    Button {
                        showApiSheet = true
                    } label: {
                        HStack {
                            Text("API credentials")
                            Spacer()
                            Text(credentialsConfigured ? "Configured ✓" : "Not configured")
                                .foregroundStyle(credentialsConfigured ? Theme.riskGood : .secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    Text("Connect your FatSecret Platform API key to search a global database of foods with cholesterol data and scan product barcodes. Free keys at platform.fatsecret.com.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Data") {
                    Button("Export readings as CSV") {
                        shareURL = ExportService.csvFile(readings: readings)
                    }
                    .disabled(readings.isEmpty)
                    Button("Share PDF report") {
                        shareURL = ExportService.pdfReport(readings: readings, settings: settings)
                    }
                    .disabled(readings.isEmpty)
                    NavigationLink("Learn about cholesterol") { LearnView() }
                    Button("Delete all data", role: .destructive) {
                        showDeleteAll = true
                    }
                }

                Section {
                    Text("LipidCare v1.0 — Information in this app is educational and is not medical advice. Always consult a healthcare professional about your results and before changing treatment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("More")
            .sheet(isPresented: $showApiSheet, onDismiss: { credentialsConfigured = KeychainStore.hasCredentials }) {
                ApiCredentialsSheet()
            }
            .sheet(isPresented: Binding(get: { shareURL != nil }, set: { if !$0 { shareURL = nil } })) {
                if let shareURL { ShareSheet(items: [shareURL]) }
            }
            .confirmationDialog(
                "Delete all data? All readings, food entries, medications and dose history will be permanently erased.",
                isPresented: $showDeleteAll,
                titleVisibility: .visible
            ) {
                Button("Delete everything", role: .destructive) { deleteAll() }
            }
        }
    }

    private var ldlTargetRow: some View {
        @Bindable var settings = settings
        return Stepper(
            value: $settings.ldlTargetMgdl,
            in: 40...250,
            step: settings.unit == .mgdl ? 5 : 4
        ) {
            HStack {
                Text("LDL target")
                Spacer()
                Text(LipidMath.format(settings.ldlTargetMgdl, metric: .ldl, unit: settings.unit, withUnit: true))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func budgetRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unitLabel: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded())) \(unitLabel)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var riskFactorsView: some View {
        @Bindable var settings = settings
        return List(RiskFactorOption.allCases) { factor in
            Toggle(factor.label, isOn: Binding(
                get: { settings.riskFactors.contains(factor) },
                set: { on in
                    var set = settings.riskFactors
                    if on { set.insert(factor) } else { set.remove(factor) }
                    settings.riskFactors = set
                }
            ))
        }
        .navigationTitle("Risk factors")
    }

    private func deleteAll() {
        try? context.delete(model: LipidReading.self)
        try? context.delete(model: FoodEntry.self)
        try? context.delete(model: MedDoseLog.self)
        try? context.delete(model: Medication.self)
        try? context.delete(model: FavoriteFood.self)
    }
}

private struct ApiCredentialsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var clientId = KeychainStore.fatSecretClientId
    @State private var clientSecret = KeychainStore.fatSecretClientSecret

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Paste the Client ID and Client Secret from your FatSecret Platform application. They are stored in the iOS Keychain on this device only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("OAuth 2.0 credentials") {
                    TextField("Client ID", text: $clientId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Client Secret", text: $clientSecret)
                }
            }
            .navigationTitle("FatSecret API")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        KeychainStore.fatSecretClientId = clientId
                        KeychainStore.fatSecretClientSecret = clientSecret
                        Task { await FatSecretClient.shared.invalidateToken() }
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}
