import SwiftUI
import Combine

struct DDayView: View {
    @EnvironmentObject var store: CalendarStore
    private let timer = Timer.publish(every: 120, on: .main, in: .common).autoconnect()

    private func color(for dday: Int) -> Color {
        if dday <= 3 && dday >= 0 { return .red }
        if dday <= 7 && dday >= 0 { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("이번 달 일정 (위젯 표시 선택)")
                    .font(.title2).bold()
                Spacer()
                Button("새로고침") { store.loadMonthEvents() }
            }

            Text("체크한 일정만 위젯에 표시됩니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(store.monthEvents) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isSelected ? Color.accentColor : Color.secondary)
                        .onTapGesture { store.toggleSelection(item) }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).lineLimit(1)
                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    Text(item.ddayText)
                        .fontWeight(.bold)
                        .foregroundStyle(color(for: item.dday))
                }
                .contentShape(Rectangle())
                .onTapGesture { store.toggleSelection(item) }
            }
            .listStyle(.inset)
        }
        .padding(20)
        .onAppear { store.loadMonthEvents() }
        .onReceive(timer) { _ in store.loadMonthEvents() }
    }
}
