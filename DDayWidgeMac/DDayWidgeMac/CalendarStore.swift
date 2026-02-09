import Foundation
import Combine
import EventKit
import WidgetKit

struct EventItem: Identifiable, Codable {
    let id: String
    let title: String
    let date: Date
    var isSelected: Bool

    var dday: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: start, to: target).day ?? 0
    }

    var ddayText: String {
        if dday == 0 { return "D-DAY" }
        return dday > 0 ? "D-\(dday)" : "D+\(-dday)"
    }
}

final class CalendarStore: ObservableObject {
    @Published var monthEvents: [EventItem] = []

    private let store = EKEventStore()
    private let selectedIDsKey = "widget.selectedEventIDs"
    private let appGroup = "group.markwise.DDayWidgeMac"

    private var localDefaults: UserDefaults { .standard }

    private var sharedJSONURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("selected_events.json")
    }

    func requestAccessIfNeeded() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, _ in
                if granted {
                    DispatchQueue.main.async {
                        self.loadMonthEvents()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        } else {
            store.requestAccess(to: .event) { granted, _ in
                if granted {
                    DispatchQueue.main.async {
                        self.loadMonthEvents()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
    }

    func loadMonthEvents() {
        let now = Date()
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let monthEnd = cal.date(byAdding: DateComponents(month: 1, second: -1), to: monthStart) ?? now

        let predicate = store.predicateForEvents(withStart: monthStart, end: monthEnd, calendars: nil)
        let events = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        var selectedIDs = Set(localDefaults.stringArray(forKey: selectedIDsKey) ?? [])

        var mapped: [EventItem] = events.map { e in
            EventItem(
                id: e.eventIdentifier,
                title: e.title.isEmpty ? "(제목 없음)" : e.title,
                date: e.startDate,
                isSelected: selectedIDs.contains(e.eventIdentifier)
            )
        }

        if selectedIDs.isEmpty {
            let defaults = mapped.filter { $0.date >= now }.prefix(5).map { $0.id }
            selectedIDs = Set(defaults)
            mapped = mapped.map { item in
                var copy = item
                copy.isSelected = selectedIDs.contains(item.id)
                return copy
            }
            localDefaults.set(Array(selectedIDs), forKey: selectedIDsKey)
        }

        DispatchQueue.main.async {
            self.monthEvents = mapped
            self.persistWidgetPayload()
        }
    }

    func toggleSelection(_ item: EventItem) {
        var selectedIDs = Set(localDefaults.stringArray(forKey: selectedIDsKey) ?? [])
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }
        localDefaults.set(Array(selectedIDs), forKey: selectedIDsKey)

        monthEvents = monthEvents.map {
            var copy = $0
            copy.isSelected = selectedIDs.contains(copy.id)
            return copy
        }

        persistWidgetPayload()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func persistWidgetPayload() {
        let selected = monthEvents
            .filter { $0.isSelected }
            .sorted { $0.date < $1.date }

        guard let url = sharedJSONURL,
              let data = try? JSONEncoder().encode(selected) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
