import SwiftUI
import BackgroundTasks

@main
struct UVIndexAlertApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static let backgroundTaskID = "com.uvindexalert.refresh"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskID,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        return true
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        let uvManager = UVManager()
        let locationManager = LocationManager()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        guard let location = locationManager.lastLocation else {
            task.setTaskCompleted(success: false)
            return
        }

        Task {
            do {
                let uv = try await uvManager.fetchUVIndex(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                if uv > UserSettings.shared.threshold {
                    await NotificationManager.shared.sendUVAlert(uvIndex: uv)
                }
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}
