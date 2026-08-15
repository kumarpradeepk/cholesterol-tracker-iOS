import SwiftUI
import SwiftData
import Charts

struct DietView: View {
    @Environment(UserSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var allEntries: [FoodEntry]
    @Query(sort: \FavoriteFood.lastUsed, order: .reverse) private var favorites: [FavoriteFood]

    @State private var date = Calendar.current.startOfDay(for: .now)
    @State private var searchMeal: MealType?
    @State private var entryToDelete: FoodEntry?

    private var dateKey: String { FoodEntry.dateKey(for: date) }
    private var entries: [FoodEntry] { allEntries.filter { $0.dateKey == dateKey } }
    private var weekEntries: [FoodEntry] {
        let start = Calendar.current.date(byAdding: .day, value: -6, to: date)!
        return allEntries.filter { $0.date >= start && $0.date < Calendar.current.date(byAdding: .day, value: 1, to: date)! }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    dateNavigator
                    summaryCard
                    if !favorites.isEmpty { quickAddRow }
                    ForEach(MealType.allCases) { meal in
                        mealSection(meal)
                    }
                    weeklyChartCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Food diary")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $searchMeal) { meal in
                FoodSearchView(meal: meal, dateKey: dateKey)
            }
            .confirmationDialog(
                "Remove \(entryToDelete?.name ?? "entry")?",
                isPresented: Binding(get: { entryToDelete != nil }, set: { if !$0 { entryToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let entry = entryToDelete { context.delete(entry) }
                    entryToDelete = nil
                }
            }
        }
    }

    private var dateNavigator: some View {
        HStack {
            Button {
                withAnimation { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! }
            } label: { Image(systemName: "chevron.left") }

            Spacer()
            Text(friendlyDay)
                .font(.headline)
            Spacer()

            Button {
                withAnimation { date = Calendar.current.date(byAdding: .day, value: 1, to: date)! }
            } label: { Image(systemName: "chevron.right") }
            .disabled(Calendar.current.isDateInToday(date))
        }
        .padding(.horizontal, 4)
    }

    private var friendlyDay: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var summaryCard: some View {
        let chol = entries.reduce(0) { $0 + $1.cholesterolMg }
        let satFat = entries.reduce(0) { $0 + $1.satFatG }
        let kcal = entries.reduce(0) { $0 + $1.caloriesKcal }

        return HStack {
            Spacer()
            ProgressRing(progress: settings.dailyCholesterolBudgetMg > 0 ? chol / settings.dailyCholesterolBudgetMg : 0, size: 94) {
                VStack(spacing: 0) {
                    Text("\(Int(chol.rounded()))").font(.title3.bold())
                    Text("mg chol").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            ProgressRing(
                progress: settings.dailySatFatBudgetG > 0 ? satFat / settings.dailySatFatBudgetG : 0,
                color: Theme.riskWarn,
                size: 94
            ) {
                VStack(spacing: 0) {
                    Text("\(Int(satFat.rounded()))").font(.title3.bold())
                    Text("g sat fat").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(spacing: 0) {
                Text("\(Int(kcal.rounded()))").font(.title2.bold())
                Text("kcal").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 18)
        .lipidCard()
    }

    private var quickAddRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick add").font(.title3.bold()).padding(.horizontal, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(favorites.prefix(12), id: \.foodKey) { fav in
                        Button {
                            quickLog(fav)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fav.name)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text("\(Int(fav.cholesterolMg.rounded())) mg chol")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .frame(width: 140, alignment: .leading)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func quickLog(_ fav: FavoriteFood) {
        withAnimation {
            context.insert(FoodEntry(
                dateKey: dateKey,
                mealType: .forCurrentTime,
                foodId: fav.foodKey,
                name: fav.name,
                brand: fav.brand,
                servingDescription: fav.servingDescription,
                quantity: 1,
                caloriesKcal: fav.caloriesKcal,
                cholesterolMg: fav.cholesterolMg,
                satFatG: fav.satFatG,
                totalFatG: fav.totalFatG,
                source: FoodSource(rawValue: fav.sourceRaw) ?? .custom
            ))
            fav.lastUsed = .now
        }
    }

    private func mealSection(_ meal: MealType) -> some View {
        let mealEntries = entries.filter { $0.mealTypeRaw == meal.rawValue }
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(meal.emoji)
                Text(meal.label).font(.subheadline.weight(.semibold))
                if !mealEntries.isEmpty {
                    Text("\(Int(mealEntries.reduce(0) { $0 + $1.cholesterolMg }.rounded())) mg chol")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    searchMeal = meal
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.crimson)
                }
            }
            if mealEntries.isEmpty {
                Text("Nothing logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(mealEntries, id: \.persistentModelID) { entry in
                    Button {
                        entryToDelete = entry
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(entry.name).font(.subheadline).lineLimit(1)
                                Text("\(entry.quantity != 1 ? String(format: "%.1f × ", entry.quantity) : "")\(entry.servingDescription)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(Int(entry.cholesterolMg.rounded())) mg")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(entry.cholesterolMg > 100 ? Theme.riskSevere : .primary)
                                Text("\(Int(entry.caloriesKcal.rounded())) kcal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .lipidCard(cornerRadius: 18)
    }

    private var weeklyChartCard: some View {
        let days: [(label: String, day: Date, total: Double)] = (0...6).map { offset in
            let day = Calendar.current.date(byAdding: .day, value: offset - 6, to: date)!
            let key = FoodEntry.dateKey(for: day)
            let total = weekEntries.filter { $0.dateKey == key }.reduce(0) { $0 + $1.cholesterolMg }
            return (day.formatted(.dateTime.weekday(.abbreviated)), day, total)
        }
        let budget = settings.dailyCholesterolBudgetMg

        return VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 days — dietary cholesterol").font(.headline)
            Chart {
                ForEach(days, id: \.day) { item in
                    BarMark(x: .value("Day", item.label), y: .value("mg", item.total))
                        .foregroundStyle(item.total > budget ? Theme.riskSevere : Theme.teal)
                        .cornerRadius(5)
                }
                RuleMark(y: .value("Budget", budget))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .foregroundStyle(Theme.riskSevere.opacity(0.8))
            }
            .frame(height: 160)
            Text("Dashed line = your \(Int(budget.rounded())) mg daily budget")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .lipidCard()
    }
}
