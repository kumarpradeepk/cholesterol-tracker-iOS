import SwiftUI

private struct OnboardPage {
    let emoji: String
    let title: String
    let body: String
}

private let pages: [OnboardPage] = [
    OnboardPage(
        emoji: "❤️", title: "Welcome to LipidCare",
        body: "Your personal cholesterol companion. Track lipid panels, understand your numbers, and watch your progress over time."
    ),
    OnboardPage(
        emoji: "🍽️", title: "Know your food",
        body: "Search a global nutrition database to see the cholesterol and saturated fat in every meal, and stay inside your daily budget."
    ),
    OnboardPage(
        emoji: "📊", title: "See the trend, not the noise",
        body: "Beautiful charts with target bands, a composite Lipid Score, medication reminders and doctor-ready reports."
    )
]

struct OnboardingView: View {
    @Environment(UserSettings.self) private var settings
    @State private var page = 0
    @State private var name = ""
    @State private var birthYearText = ""
    @State private var sex: Sex = .unspecified
    @State private var unit: UnitSystem = .mgdl
    @State private var riskFactors: Set<RiskFactorOption> = []

    private var lastPage: Int { pages.count } // profile page index

    var body: some View {
        ZStack {
            Theme.onboardingGradient.ignoresSafeArea()

            VStack {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        IntroPageView(page: item).tag(index)
                    }
                    profilePage.tag(lastPage)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0...lastPage, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(page == i ? 1 : 0.45))
                            .frame(width: page == i ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: page)
                    }
                }
                .padding(.bottom, 14)

                HStack {
                    if page < lastPage {
                        Button("Skip") {
                            withAnimation { page = lastPage }
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Button {
                        if page < lastPage {
                            withAnimation { page += 1 }
                        } else {
                            finish()
                        }
                    } label: {
                        Text(page == lastPage ? "Start tracking" : "Next")
                            .font(.headline)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Color.white, in: Capsule())
                            .foregroundStyle(Theme.crimson)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }

    private func finish() {
        settings.name = name.trimmingCharacters(in: .whitespaces)
        settings.sex = sex
        settings.unit = unit
        settings.riskFactors = riskFactors
        if let year = Int(birthYearText),
           (1900...Calendar.current.component(.year, from: .now)).contains(year) {
            settings.birthYear = year
        }
        withAnimation { settings.onboardingDone = true }
    }

    private var profilePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About you")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("Used to personalize your targets. You can change everything later in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))

                Group {
                    TextField("Name (optional)", text: $name)
                    TextField("Birth year", text: $birthYearText)
                        .keyboardType(.numberPad)
                }
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)

                Text("Sex (affects HDL targets)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Picker("Sex", selection: $sex) {
                    Text("Male").tag(Sex.male)
                    Text("Female").tag(Sex.female)
                    Text("Skip").tag(Sex.unspecified)
                }
                .pickerStyle(.segmented)

                Text("Preferred units")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Picker("Units", selection: $unit) {
                    Text("mg/dL").tag(UnitSystem.mgdl)
                    Text("mmol/L").tag(UnitSystem.mmol)
                }
                .pickerStyle(.segmented)

                Text("Any of these apply to you?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                FlowLayout(spacing: 8) {
                    ForEach(RiskFactorOption.allCases) { factor in
                        let selected = riskFactors.contains(factor)
                        Button {
                            if selected { riskFactors.remove(factor) } else { riskFactors.insert(factor) }
                        } label: {
                            Text(factor.label)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selected ? Color.white : Color.white.opacity(0.14), in: Capsule())
                                .foregroundStyle(selected ? Theme.crimson : .white)
                        }
                    }
                }

                Text("LipidCare provides information, not medical advice. Always consult your doctor about your results.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, 26)
            .padding(.top, 30)
        }
    }
}

private struct IntroPageView: View {
    let page: OnboardPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 120, height: 120)
                Text(page.emoji).font(.system(size: 56))
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)

            Text(page.title)
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(page.body)
                .font(.body)
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 36)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) { appeared = true }
        }
    }
}

/// Simple flow layout for wrapping chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
