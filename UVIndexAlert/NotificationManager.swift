import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func sendUVAlert(uvIndex: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "UV Index Alert ☀️"
        content.body = String(
            format: "The UV index is %.1f right now. Don't forget sunscreen!",
            uvIndex
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "uv-alert-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
}
