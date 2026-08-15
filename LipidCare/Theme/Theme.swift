import SwiftUI

/// LipidCare design tokens — identical palette to the Android app (see DESIGN.md).
enum Theme {
    // Brand
    static let crimson = Color(red: 0.910, green: 0.259, blue: 0.353)      // #E8425A
    static let crimsonDark = Color(red: 0.690, green: 0.137, blue: 0.259)  // #B02342
    static let rose = Color(red: 0.698, green: 0.227, blue: 0.471)         // #B23A78
    static let teal = Color(red: 0.055, green: 0.620, blue: 0.553)         // #0E9E8D
    static let indigo = Color(red: 0.424, green: 0.388, blue: 1.0)         // #6C63FF

    // Risk spectrum
    static let riskGood = Color(red: 0.180, green: 0.722, blue: 0.447)     // #2EB872
    static let riskOk = Color(red: 0.486, green: 0.702, blue: 0.259)       // #7CB342
    static let riskWarn = Color(red: 0.961, green: 0.651, blue: 0.137)     // #F5A623
    static let riskBad = Color(red: 0.937, green: 0.424, blue: 0.227)      // #EF6C3A
    static let riskSevere = Color(red: 0.898, green: 0.282, blue: 0.302)   // #E5484D

    // Metric identities
    static let metricLdl = Color(red: 0.949, green: 0.463, blue: 0.180)    // #F2762E
    static let metricNonHdl = Color(red: 0.722, green: 0.361, blue: 0.780) // #B85CC7

    static let heroGradient = LinearGradient(
        colors: [crimson, rose, crimsonDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let onboardingGradient = LinearGradient(
        colors: [crimson, rose, teal],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card background adapting to light/dark.
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.118, green: 0.094, blue: 0.102) : Color.white
    }
}

extension View {
    /// Standard LipidCare card chrome.
    func lipidCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}
