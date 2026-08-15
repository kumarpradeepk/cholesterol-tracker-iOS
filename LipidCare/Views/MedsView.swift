import SwiftUI
import SwiftData

private let medColors: [Color] = [Theme.teal, Theme.indigo, Theme.riskWarn, Theme.riskSevere, Theme.riskGood]

struct MedsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Medication> { $0.active }, sort: \Medication.name) private var meds: [Medication]
    @Query private var allLogs: [MedDoseLog]

    @State private var showAdd = false
    @State private var medToEdit: Medication?

    private var todayKey: String { FoodEntry.dateKey() }
    private var todayLogs: [MedDoseLog] { allLogs.filter { $0.dateKey == todayKey } }
    private var weekLogs: [MedDoseLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now))!
        return allLogs.filter { $0.date >= cutoff }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if meds.isEmpty {
                        EmptyStateView(
                            emoji: "💊",
                            title: "No medications",
                            message: "Add statins, supplements or any heart medication to get dose reminders and track adherence."
                        )
                        .padding(.top, 60)
                    } else {
                        adherenceCard
                        Text("Today's doses").font(.title3.bold()).padding(.horizontal, 4)
                        ForEach(meds, id: \.persistentModelID) { med in
                            ForEach(med.times, id: \.self) { time in
                                DoseRowView(
                                    med: med,
                                    time: time,
                                    log: todayLogs.first { $0.medication === med && $0.timeSlot == time },
                                    todayKey: todayKey
                                )
                            }
                        }
                        Text("My medications").font(.title3.bold()).padding(.horizontal, 4)
                        ForEach(meds, id: \.persistentModelID) { med in
                            Button {
                                medToEdit = med
                            } label: {
                                medCard(med)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddMedicationView() }
            .sheet(item: $medToEdit) { med in AddMedicationView(existing: med) }
        }
    }

    private var adherenceCard: some View {
        let dosesPerDay = meds.reduce(0) { $0 + $1.times.count }
        let expected = dosesPerDay * 7
        let taken = weekLogs.filter { $0.status == .taken }.count
        let adherence = expected > 0 ? min(1, Double(taken) / Double(expected)) : 0

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("7-day adherence").font(.headline)
                Text("\(taken) of \(expected) scheduled doses taken")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(
                    adherence >= 0.9 ? "Excellent consistency 🎯" :
                    adherence >= 0.7 ? "Good — a few missed doses" :
                    "Statins work best when taken daily"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            ProgressRing(progress: adherence, size: 84) {
                Text("\(Int((adherence * 100).rounded()))%").font(.headline)
            }
        }
        .padding(18)
        .lipidCard()
    }

    private func medCard(_ med: Medication) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(medColors[med.colorIndex % medColors.count].opacity(0.15))
                    .frame(width: 40, height: 40)
                Text("💊")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(med.name).font(.subheadline.weight(.semibold))
                Text([
                    med.dosage.isEmpty ? nil : med.dosage,
                    med.times.map(prettyTime).joined(separator: " · "),
                    med.reminderEnabled ? "🔔 on" : "🔕 off"
                ].compactMap { $0 }.joined(separator: "  •  "))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "pencil").foregroundStyle(.tertiary)
        }
        .padding(14)
        .lipidCard(cornerRadius: 16)
    }
}

func prettyTime(_ hhmm: String) -> String {
    let parts = hhmm.split(separator: ":")
    guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]),
          let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now)
    else { return hhmm }
    return date.formatted(date: .omitted, time: .shortened)
}

private struct DoseRowView: View {
    @Environment(\.modelContext) private var context
    let med: Medication
    let time: String
    let log: MedDoseLog?
    let todayKey: String

    private var status: DoseStatus? { log?.status }

    var body: some View {
        HStack {
            Circle()
                .fill(medColors[med.colorIndex % medColors.count])
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(med.name)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(status == .skipped)
                Text("\(prettyTime(time))\(med.dosage.isEmpty ? "" : " • \(med.dosage)")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                setStatus(.skipped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(status == .skipped ? .primary : Color.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)

            Button {
                toggleTaken()
            } label: {
                ZStack {
                    Circle()
                        .fill(status == .taken ? Theme.riskGood : Color(.tertiarySystemFill))
                        .frame(width: 34, height: 34)
                    Image(systemName: "checkmark")
                        .font(.subheadline.bold())
                        .foregroundStyle(status == .taken ? .white : .secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            status == .taken ? Theme.riskGood.opacity(0.10) : Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .animation(.snappy, value: status)
    }

    private func toggleTaken() {
        if let log {
            if log.status == .taken {
                context.delete(log)
            } else {
                log.statusRaw = DoseStatus.taken.rawValue
                log.date = .now
            }
        } else {
            context.insert(MedDoseLog(dateKey: todayKey, timeSlot: time, status: .taken, medication: med))
        }
    }

    private func setStatus(_ newStatus: DoseStatus) {
        if let log {
            log.statusRaw = newStatus.rawValue
            log.date = .now
        } else {
            context.insert(MedDoseLog(dateKey: todayKey, timeSlot: time, status: newStatus, medication: med))
        }
    }
}
