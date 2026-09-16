import FirebaseAnalytics

// ponytail: thin wrapper over Firebase Analytics; swap the body if a second
// destination (Amplitude, self-hosted) is ever needed.
enum Track {
    static func log(_ name: String, _ params: [String: Any] = [:]) {
        Analytics.logEvent(name, parameters: params.isEmpty ? nil : params)
    }

    static func screen(_ name: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: String(name.prefix(100)),
            AnalyticsParameterScreenClass: "SwiftUIScreen"
        ])
    }
}
