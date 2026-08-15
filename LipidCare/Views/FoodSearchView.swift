import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let meal: MealType
    let dateKey: String

    @State private var query = ""
    @State private var results: [FoodSearchResult] = []
    @State private var searching = false
    @State private var onlineError: String?
    @State private var selectedFood: FoodItem?
    @State private var loadingFood = false
    @State private var showScanner = false
    @State private var searchTask: Task<Void, Never>?

    private var onlineConfigured: Bool { FatSecretClient.shared.isConfigured }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                if !onlineConfigured {
                    Text("Offline food list active. Add your FatSecret API key in More → Food database to search millions of foods and scan barcodes.")
                        .font(.caption)
                        .foregroundStyle(Theme.indigo)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                }
                if let onlineError {
                    Text("Online search unavailable: \(onlineError)")
                        .font(.caption)
                        .foregroundStyle(Theme.riskSevere)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.riskSevere.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                }

                Group {
                    if searching {
                        ProgressView().padding(.top, 40)
                        Spacer()
                    } else if results.isEmpty && query.count >= 2 {
                        EmptyStateView(
                            emoji: "🔍", title: "No matches",
                            message: "Try a simpler term, like \"chicken\" instead of a full dish name."
                        )
                        Spacer()
                    } else if results.isEmpty {
                        EmptyStateView(
                            emoji: "🥗", title: "Search the food database",
                            message: "See cholesterol, saturated fat and calories for any food before you log it."
                        )
                        Spacer()
                    } else {
                        List(results) { result in
                            Button {
                                select(result.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(result.name)
                                            .font(.subheadline.weight(.semibold))
                                            .lineLimit(1)
                                        if result.source == .builtIn {
                                            Text("⚡ instant")
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(Theme.teal)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Theme.teal.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                    if let brand = result.brand {
                                        Text(brand).font(.caption2).foregroundStyle(Theme.indigo)
                                    }
                                    Text(result.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add to \(meal.label)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search foods — try \"egg\" or \"paneer\"")
            .onChange(of: query) { runSearch() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if onlineConfigured {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                        }
                    }
                }
            }
            .overlay {
                if loadingFood { ProgressView().controlSize(.large) }
            }
            .sheet(item: $selectedFood) { food in
                ServingPickerView(food: food, initialMeal: meal, dateKey: dateKey) {
                    dismiss()
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { foodItem in
                    showScanner = false
                    selectedFood = foodItem
                }
            }
        }
    }

    private func runSearch() {
        searchTask?.cancel()
        let q = query
        guard q.count >= 2 else {
            results = []
            searching = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            searching = true
            let outcome = await FoodRepository.search(q)
            guard !Task.isCancelled else { return }
            results = outcome.results
            onlineError = outcome.onlineError
            searching = false
        }
    }

    private func select(_ id: String) {
        loadingFood = true
        Task {
            defer { loadingFood = false }
            do {
                selectedFood = try await FoodRepository.getFood(id: id)
            } catch {
                onlineError = error.localizedDescription
            }
        }
    }
}

// MARK: - Serving picker

struct ServingPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let food: FoodItem
    let initialMeal: MealType
    let dateKey: String
    var onLogged: () -> Void

    @State private var servingIndex = 0
    @State private var quantity = 1.0
    @State private var meal: MealType

    init(food: FoodItem, initialMeal: MealType, dateKey: String, onLogged: @escaping () -> Void) {
        self.food = food
        self.initialMeal = initialMeal
        self.dateKey = dateKey
        self.onLogged = onLogged
        _meal = State(initialValue: initialMeal)
    }

    private var serving: FoodServing { food.servings[min(servingIndex, food.servings.count - 1)] }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if food.servings.count > 1 {
                        Picker("Serving", selection: $servingIndex) {
                            ForEach(Array(food.servings.enumerated()), id: \.offset) { index, s in
                                Text(s.servingDescription).tag(index)
                            }
                        }
                    } else {
                        LabeledContent("Serving", value: serving.servingDescription)
                    }
                    Stepper(value: $quantity, in: 0.5...20, step: 0.5) {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            Text(quantity == quantity.rounded() ? "\(Int(quantity))" : String(format: "%.1f", quantity))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Picker("Meal", selection: $meal) {
                        ForEach(MealType.allCases) { m in
                            Text("\(m.emoji) \(m.label)").tag(m)
                        }
                    }
                }

                Section("Nutrition for this portion") {
                    nutrientRow("Cholesterol", "\(Int((serving.cholesterolMg * quantity).rounded())) mg",
                                highlight: serving.cholesterolMg * quantity > 100)
                    nutrientRow("Saturated fat", String(format: "%.1f g", serving.saturatedFatG * quantity),
                                highlight: serving.saturatedFatG * quantity > 5)
                    nutrientRow("Total fat", String(format: "%.1f g", serving.totalFatG * quantity))
                    nutrientRow("Calories", "\(Int((serving.calories * quantity).rounded())) kcal")
                    if let sodium = serving.sodiumMg {
                        nutrientRow("Sodium", "\(Int((sodium * quantity).rounded())) mg")
                    }
                    if let fiber = serving.fiberG {
                        nutrientRow("Fiber", String(format: "%.1f g", fiber * quantity))
                    }
                }
            }
            .navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to diary") { log() }.bold()
                }
            }
        }
    }

    private func nutrientRow(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(highlight ? Theme.riskSevere : .primary)
        }
    }

    private func log() {
        context.insert(FoodEntry(
            dateKey: dateKey,
            mealType: meal,
            foodId: food.id,
            name: food.name,
            brand: food.brand,
            servingDescription: serving.servingDescription,
            quantity: quantity,
            caloriesKcal: serving.calories * quantity,
            cholesterolMg: serving.cholesterolMg * quantity,
            satFatG: serving.saturatedFatG * quantity,
            totalFatG: serving.totalFatG * quantity,
            sodiumMg: serving.sodiumMg.map { $0 * quantity },
            fiberG: serving.fiberG.map { $0 * quantity },
            source: food.source
        ))

        // Update favorites snapshot (per single serving) for quick re-logging
        let key = "\(food.source.rawValue):\(food.id)"
        let descriptor = FetchDescriptor<FavoriteFood>(predicate: #Predicate { $0.foodKey == key })
        if let favorite = try? context.fetch(descriptor).first {
            favorite.lastUsed = .now
        } else {
            context.insert(FavoriteFood(
                foodKey: key,
                name: food.name,
                brand: food.brand,
                servingDescription: serving.servingDescription,
                caloriesKcal: serving.calories,
                cholesterolMg: serving.cholesterolMg,
                satFatG: serving.saturatedFatG,
                totalFatG: serving.totalFatG,
                source: food.source
            ))
        }
        dismiss()
        onLogged()
    }
}
