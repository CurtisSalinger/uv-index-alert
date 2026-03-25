import SwiftUI

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("uvThreshold") var threshold: Double = 3.0
}
