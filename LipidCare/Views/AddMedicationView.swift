import SwiftUI
import SwiftData

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var existing: Medication? = nil

    @State private var name = ""
    @State private var dosage = ""
    @State private var times: [String] = ["08:00"]
    @State private var reminderEnabled = true
    @State private var notes = ""
    @State private var loaded = false
    @State private var newTime = Date()
    @State private var showTimePicker = false
    @State private var confirmArchive = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Medication name (e.g. Atorvastatin)", text: $name)
                    TextField("Dosage (e.g. 20 mg)", text: $dosage)
                }

                Section("Dose times") {
                    ForEach(times, id: \.self) { time in
                        HStack {
                            Text(prettyTime(time))
                            Spacer()
                            if times.count > 1 {
                                Button {
                                    times.removeAll { $0 == time }
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if times.count < 4 {
                        if showTimePicker {
                            DatePicker("New time", selection: $newTime, displayedComponents: .hourAndMinute)
                            Button("Add this time") {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                let value = formatter.string(from: newTime)
                                if !times.contains(value) { times = (times + [value]).sorted() }
                                showTimePicker = false
                            }
                        } else {
                            Button {
                                showTimePicker = true
                            } label: {
                                Label("Add time", systemImage: "plus")
                            }
                        }
                    }
                }

                Section {
                    Toggle(isOn: $reminderEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dose reminders")
                            Text("Notification at each dose time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    TextField("Notes (take with food…)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let error {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }

                if existing != nil {
                    Section {
                        Button("Stop tracking this medication", role: .destructive) {
                            confirmArchive = true
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add medication" : "Edit medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold()
                }
            }
            .onAppear(perform: load)
            .confirmationDialog(
                "Stop tracking \(name)? Reminders will be cancelled; dose history is kept.",
                isPresented: $confirmArchive,
                titleVisibility: .visible
            ) {
                Button("Stop tracking", role: .destructive) { archive() }
            }
        }
    }

    private func load() {
        guard let existing, !loaded else { return }
        loaded = true
        name = existing.name
        dosage = existing.dosage
        times = existing.times
        reminderEnabled = existing.reminderEnabled
        notes = existing.notes ?? ""
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            error = "Enter the medication name."
            return
        }
        error = nil
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing {
            ReminderService.cancelMedication(name: existing.name)
            existing.name = trimmedName
            existing.dosage = dosage.trimmingCharacters(in: .whitespaces)
            existing.times = times
            existing.reminderEnabled = reminderEnabled
            existing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        } else {
            context.insert(Medication(
                name: trimmedName,
                dosage: dosage.trimmingCharacters(in: .whitespaces),
                times: times,
                reminderEnabled: reminderEnabled,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                colorIndex: abs(trimmedName.hashValue) % 5
            ))
        }

        if reminderEnabled {
            Task {
                let granted = await ReminderService.requestAuthorization()
                if granted {
                    ReminderService.scheduleMedication(
                        name: trimmedName,
                        dosage: dosage.trimmingCharacters(in: .whitespaces),
                        times: times
                    )
                }
            }
        }
        dismiss()
    }

    private func archive() {
        if let existing {
            existing.active = false
            ReminderService.cancelMedication(name: existing.name)
        }
        dismiss()
    }
}
