import SwiftUI
import WidgetKit

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("uvThreshold") var threshold: Double = 3.0 {
        didSet {
            AppConstants.sharedDefaults?.set(threshold, forKey: AppConstants.thresholdKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
