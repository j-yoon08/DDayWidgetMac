import WidgetKit
import SwiftUI
import EventKit

struct WidgetEventItem: Codable {
    let id: String
    let title: String
    let date: Date
    let isSelected: Bool

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

struct DDayEntry: TimelineEntry {
    let date: Date
    let items: [WidgetEventItem]
}

struct Provider: TimelineProvider {
    private let appGroup = "group.markwise.DDayWidgeMac"

    private var sharedJSONURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("selected_events.json")
    }

    func placeholder(in context: Context) -> DDayEntry {
        DDayEntry(date: .now, items: [
            WidgetEventItem(id: "1", title: "정보보안기사 시험", date: .now, isSelected: true),
            WidgetEventItem(id: "2", title: "팀 프로젝트 발표", date: .now.addingTimeInterval(86400), isSelected: true)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (DDayEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DDayEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> DDayEntry {
        if let url = sharedJSONURL,
           let data = try? Data(contentsOf: url),
           let fileItems = try? JSONDecoder().decode([WidgetEventItem].self, from: data) {
            let selected = fileItems.filter { $0.isSelected }.sorted { $0.date < $1.date }
            if !selected.isEmpty { return DDayEntry(date: .now, items: selected) }
        }

        // fallback: 현재 달 이벤트 직접 조회
        let store = EKEventStore()
        let now = Date()
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let monthEnd = cal.date(byAdding: DateComponents(month: 1, second: -1), to: monthStart) ?? now
        let predicate = store.predicateForEvents(withStart: monthStart, end: monthEnd, calendars: nil)
        let fallback = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .prefix(10)
            .map {
                WidgetEventItem(
                    id: $0.eventIdentifier,
                    title: ($0.title?.isEmpty == false ? $0.title! : "(제목 없음)"),
                    date: $0.startDate,
                    isSelected: true
                )
            }

        return DDayEntry(date: .now, items: fallback)
    }
}

struct DDayWidgetMacWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    private func color(for dday: Int) -> Color {
        if dday <= 3 && dday >= 0 { return .red }
        if dday <= 7 && dday >= 0 { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 8 : 8) {
            if entry.items.isEmpty {
                Spacer()
                Text("일정 없음")
                    .font(.headline)
                Spacer()
            } else {
                let first = entry.items[0]
                Text(first.title)
                    .font(family == .systemLarge ? .title3.weight(.bold) : .headline)
                    .lineLimit(1)
                    .padding(.bottom, family == .systemLarge ? -4 : -1)

                Text(first.ddayText)
                    .font(.system(size: family == .systemSmall ? 30 : (family == .systemLarge ? 64 : 38), weight: .black))
                    .foregroundStyle(color(for: first.dday))
                    .padding(.top, family == .systemLarge ? -10 : -2)

                if family != .systemSmall {
                    Divider()
                    let extraCount = family == .systemLarge ? 8 : 2
                    ForEach(Array(entry.items.dropFirst().prefix(extraCount).enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.title).lineLimit(1)
                            Spacer()
                            Text(item.ddayText)
                                .fontWeight(.semibold)
                                .foregroundStyle(color(for: item.dday))
                        }
                        .font(family == .systemLarge ? .callout : .caption)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(family == .systemLarge ? 12 : 16)
        .padding(.top, family == .systemLarge ? 3 : 2)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct DDayWidgetMacWidget: Widget {
    let kind: String = "DDayWidgetMacWidgetV19"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DDayWidgetMacWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("캘린더 D-DAY")
        .description("앱에서 선택한 이번 달 일정을 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct DDayWidgetMacLargeWidget: Widget {
    let kind: String = "DDayWidgetMacWidgetLargeV18"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DDayWidgetMacWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("캘린더 D-DAY (Large)")
        .description("앱에서 선택한 이번 달 일정을 더 많이 표시합니다.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
