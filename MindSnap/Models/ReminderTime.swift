import Foundation

struct ReminderTime: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var hour: Int
    var minute: Int

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        return Calendar.current.date(from: components)
            .map { formatter.string(from: $0) } ?? ""
    }

    init(hour: Int = 9, minute: Int = 0) {
        self.hour = hour
        self.minute = minute
    }

    init(date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        self.hour = components.hour ?? 9
        self.minute = components.minute ?? 0
    }
}
