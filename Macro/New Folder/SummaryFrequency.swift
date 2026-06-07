//
//  SummaryFrequency.swift
//  Macro
//
//  Created by Ghala Alsalem on 04/06/2026.
//


import Foundation
import UserNotifications

// MARK: - Summary Frequency
// How often the user wants their summary refreshed and to be notified.
// Persisted in UserDefaults so it survives launches.
enum SummaryFrequency: String, CaseIterable {
    case daily, weekly, biweekly, monthly

    static var current: SummaryFrequency {
        get {
            let saved = UserDefaults.standard.string(forKey: "summaryFrequency")
            return SummaryFrequency(rawValue: saved ?? "") ?? .weekly
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "summaryFrequency")
        }
    }

    /// Localization key for the display name (e.g. "Daily" / "يومي").
    var nameKey: String { "freq.\(rawValue)" }

    /// Localization key for the in-sentence period phrase
    /// (e.g. "today" / "this week" / "this month").
    var phraseKey: String { "period.\(rawValue)" }

    /// The start of the comparison window, counting back from `now`.
    /// The summary's change figures compare against the snapshot taken at or
    /// before this moment.
    func periodStart(from now: Date = Date()) -> Date {
        let cal = Calendar.current
        switch self {
        case .daily:    return cal.startOfDay(for: now)
        case .weekly:   return cal.date(byAdding: .day, value: -7, to: now) ?? now
        case .biweekly: return cal.date(byAdding: .day, value: -14, to: now) ?? now
        case .monthly:  return cal.date(byAdding: .month, value: -1, to: now) ?? now
        }
    }

    /// When the next summary is due (for the "Next summary: …" footer).
    func nextDate(from now: Date = Date()) -> Date {
        let cal = Calendar.current
        switch self {
        case .daily:    return cal.date(byAdding: .day, value: 1, to: now) ?? now
        case .weekly:   return cal.date(byAdding: .day, value: 7, to: now) ?? now
        case .biweekly: return cal.date(byAdding: .day, value: 14, to: now) ?? now
        case .monthly:  return cal.date(byAdding: .month, value: 1, to: now) ?? now
        }
    }
}

// MARK: - Notification Scheduler
// Schedules the local "Your summary is ready!" notification matching the
// chosen frequency. Asks for permission the first time; replaces any
// previously scheduled summary notification when the frequency changes.
enum SummaryNotificationScheduler {

    private static let identifier = "summary.ready.notification"

    /// Request permission (if needed) and (re)schedule for the frequency.
    /// `title`/`body` are passed in already localized so the notification
    /// matches the app's current language.
    static func schedule(frequency: SummaryFrequency, title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            // Replace any existing scheduled summary notification.
            center.removePendingNotificationRequests(withIdentifiers: [identifier])

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger: UNNotificationTrigger
            switch frequency {
            case .daily:
                // Every day at 9:00 AM.
                var comps = DateComponents(); comps.hour = 9
                trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            case .weekly:
                // Every Sunday (start of the Saudi work week) at 9:00 AM.
                var comps = DateComponents(); comps.weekday = 1; comps.hour = 9
                trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            case .biweekly:
                // Calendar triggers can't express "every 14 days", so use a
                // repeating 14-day interval starting from now.
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 14 * 24 * 60 * 60, repeats: true)
            case .monthly:
                // The 1st of every month at 9:00 AM.
                var comps = DateComponents(); comps.day = 1; comps.hour = 9
                trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            }

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }
}