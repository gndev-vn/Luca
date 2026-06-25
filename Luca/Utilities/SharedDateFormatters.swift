import Foundation

/// Shared DateFormatter instances to avoid creating new ones on every SwiftUI re-render.
/// DateFormatter initialization is expensive due to ObjC bridging and locale lookup.
enum SharedDateFormatters {
    /// "d" format for day number display
    static let dayNumber: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    /// "dd/MM/yyyy" with Vietnamese locale
    static let ddMMyyyy: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()

    /// Medium date style with Vietnamese locale
    static let mediumDateVi: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "vi")
        return f
    }()

    /// Full date style
    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()
}
