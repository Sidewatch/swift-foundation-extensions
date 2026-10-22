//
//  RecencyFormatter.swift
//  FoundationExtensions
//
//  A moment written for a list of recent things: "3 hr ago", "Yesterday at 14:05", "22 Oct".
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A moment written the way a list of recent things reads best, in the locale's own words:
///
/// - under a minute ago: "now"
/// - earlier today: "12 min ago", "3 hr ago"
/// - yesterday: "Yesterday at 14:05"
/// - within the past week: "Mon 14:05"
/// - earlier this year: "22 Oct"; before that "27 May 2025"
///
/// A moment ahead of `now` (a clock that ran fast) is written as its time today, else its
/// date — never "in 5 min". ``full(_:)`` is the whole thing, for a detail view: "Thursday 22
/// October 2026 at 09:15:30 British Summer Time".
///
/// Make one per list and reuse it: it holds the formatters, which are slow to make.
public struct RecencyFormatter {
    private let calendar: Calendar
    private let relative: RelativeDateTimeFormatter
    private let yesterday: DateFormatter
    private let weekday: DateFormatter
    private let dayMonth: DateFormatter
    private let dayMonthYear: DateFormatter
    private let time: DateFormatter
    private let whole: DateFormatter

    /// Wording in `locale`, days counted in `calendar` (its time zone decides what "today" is).
    public init(calendar: Calendar = .current, locale: Locale = .current) {
        var calendar = calendar
        calendar.locale = locale
        self.calendar = calendar
        relative = RelativeDateTimeFormatter()
        relative.calendar = calendar
        relative.locale = locale
        relative.unitsStyle = .abbreviated
        relative.dateTimeStyle = .named
        func make(template: String? = nil, date: DateFormatter.Style = .none, time: DateFormatter.Style = .none) -> DateFormatter {
            let f = DateFormatter()
            f.calendar = calendar
            f.locale = locale
            f.timeZone = calendar.timeZone
            if let template { f.setLocalizedDateFormatFromTemplate(template) } else { (f.dateStyle, f.timeStyle) = (date, time) }
            return f
        }
        yesterday = make(date: .medium, time: .short)
        yesterday.doesRelativeDateFormatting = true
        weekday = make(template: "EEE jj:mm")
        dayMonth = make(template: "d MMM")
        dayMonthYear = make(template: "d MMM yyyy")
        time = make(time: .short)
        whole = make(date: .full, time: .long)
    }

    /// `date` as a list shows it, seen from `now`.
    public func string(for date: Date, now: Date = Date()) -> String {
        let today = calendar.startOfDay(for: now)
        if date > now {
            return date < (calendar.date(byAdding: .day, value: 1, to: today) ?? now) ? time.string(from: date) : dated(date, now: now)
        }
        if date >= today {
            return now.timeIntervalSince(date) < 60
                ? relative.localizedString(fromTimeInterval: 0) : relative.localizedString(for: date, relativeTo: now)
        }
        if let start = calendar.date(byAdding: .day, value: -1, to: today), date >= start { return yesterday.string(from: date) }
        if let start = calendar.date(byAdding: .day, value: -6, to: today), date >= start { return weekday.string(from: date) }
        return dated(date, now: now)
    }

    /// `date` in full, with seconds and the time zone.
    public func full(_ date: Date) -> String { whole.string(from: date) }

    /// The day and month, and the year when it is not this one.
    private func dated(_ date: Date, now: Date) -> String {
        calendar.component(.year, from: date) == calendar.component(.year, from: now)
            ? dayMonth.string(from: date) : dayMonthYear.string(from: date)
    }
}
