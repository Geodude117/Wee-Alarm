import Foundation

enum AppLinks {
    static let support = URL(string: "https://geodude117.github.io/Portfolio/wee-alarm/")!
    static let privacyPolicy = URL(string: "https://geodude117.github.io/Portfolio/wee-alarm/privacy/")!

    static var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
