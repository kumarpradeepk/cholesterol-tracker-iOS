import Foundation
import UserNotifications

/// Schedules local notifications for the daily log reminder and medication doses.
/// Mirrors the Android ReminderScheduler.
enum ReminderService {

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // MARK: Daily log reminder

    private static let dailyLogId = "daily-log-reminder"

    static func scheduleDailyLog(time: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyLogId])
        guard let components = timeComponents(time) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to log 📝"
        content.body = "Add today's meals and check your cholesterol budget."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: dailyLogId, content: content, trigger: trigger))
    }

    static func cancelDailyLog() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyLogId])
    }

    // MARK: Medication reminders

    private static func medIdentifier(_ medicationName: String, slot: Int) -> String {
        "med-\(medicationName.lowercased().replacingOccurrences(of: " ", with: "-"))-\(slot)"
    }

    static func scheduleMedication(name: String, dosage: String, times: [String]) {
        cancelMedication(name: name)
        let center = UNUserNotificationCenter.current()
        for (index, time) in times.enumerated() {
            guard let components = timeComponents(time) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Medication reminder 💊"
            content.body = "\(name)\(dosage.isEmpty ? "" : " • \(dosage)") — scheduled for \(time)."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(
                identifier: medIdentifier(name, slot: index),
                content: content,
                trigger: trigger
            ))
        }
    }

    static func cancelMedication(name: String, slotCount: Int = 6) {
        let ids = (0..<slotCount).map { medIdentifier(name, slot: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func timeComponents(_ hhmm: String) -> DateComponents? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }
}
