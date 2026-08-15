import SwiftUI
import SwiftData

@main
struct LipidCareApp: App {
    @State private var settings = UserSettings.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .preferredColorScheme(settings.themeMode.colorScheme)
                .tint(Theme.crimson)
        }
        .modelContainer(for: [
            LipidReading.self,
            FoodEntry.self,
            Medication.self,
            MedDoseLog.self,
            FavoriteFood.self
        ])
    }
}

struct RootView: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        if settings.onboardingDone {
            MainTabView()
                .transition(.opacity)
        } else {
            OnboardingView()
                .transition(.opacity)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "heart.fill") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }
            DietView()
                .tabItem { Label("Diet", systemImage: "fork.knife") }
            MedsView()
                .tabItem { Label("Meds", systemImage: "pills.fill") }
            SettingsView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
    }
}
