import Foundation

enum AppConstants {
    static let appGroupID = "group.com.uvindexalert.shared"
    static let latitudeKey = "shared_latitude"
    static let longitudeKey = "shared_longitude"
    static let uvIndexKey = "shared_uv_index"
    static let lastCheckedKey = "shared_last_checked"
    static let thresholdKey = "shared_threshold"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
}
