import Foundation

/// Curated offline food database with USDA-derived nutrition values.
/// Used as a fallback when FatSecret API credentials are not configured,
/// and blended into search results for instant matches.
/// Identical dataset to the Android app.
enum BuiltInFoods {

    private static func food(
        _ slug: String, _ name: String, _ serving: String, _ grams: Double?,
        kcal: Double, chol: Double, satFat: Double, fat: Double,
        sodium: Double? = nil, fiber: Double? = nil
    ) -> FoodItem {
        let primary = FoodServing(
            servingDescription: serving, metricGrams: grams, calories: kcal,
            cholesterolMg: chol, saturatedFatG: satFat, totalFatG: fat,
            sodiumMg: sodium, fiberG: fiber
        )
        var servings = [primary]
        if let grams, grams > 0, abs(grams - 100) > 1 {
            let f = 100.0 / grams
            servings.append(FoodServing(
                servingDescription: "100 g", metricGrams: 100, calories: kcal * f,
                cholesterolMg: chol * f, saturatedFatG: satFat * f, totalFatG: fat * f,
                sodiumMg: sodium.map { $0 * f }, fiberG: fiber.map { $0 * f }
            ))
        }
        return FoodItem(id: "builtin:\(slug)", name: name, source: .builtIn, servings: servings)
    }

    static let all: [FoodItem] = [
        // Eggs & dairy
        food("egg-whole", "Egg, whole, large", "1 large egg", 50, kcal: 72, chol: 186, satFat: 1.6, fat: 5),
        food("egg-white", "Egg white", "1 large egg white", 33, kcal: 17, chol: 0, satFat: 0, fat: 0.1),
        food("quail-egg", "Quail egg", "1 egg", 9, kcal: 14, chol: 76, satFat: 0.3, fat: 1),
        food("omelette", "Omelette (2 eggs, butter)", "1 omelette", 120, kcal: 220, chol: 400, satFat: 4.5, fat: 15),
        food("butter", "Butter, salted", "1 tbsp", 14, kcal: 102, chol: 31, satFat: 7.2, fat: 11.5),
        food("ghee", "Ghee (clarified butter)", "1 tbsp", 13, kcal: 112, chol: 33, satFat: 8, fat: 12.7),
        food("whole-milk", "Milk, whole", "1 cup (244 ml)", 244, kcal: 149, chol: 24, satFat: 4.6, fat: 8),
        food("skim-milk", "Milk, skim", "1 cup (244 ml)", 244, kcal: 83, chol: 5, satFat: 0.3, fat: 0.2),
        food("cheddar", "Cheddar cheese", "1 slice (28 g)", 28, kcal: 113, chol: 28, satFat: 5.3, fat: 9.3),
        food("paneer", "Paneer", "100 g", 100, kcal: 265, chol: 90, satFat: 13, fat: 20),
        food("yogurt-whole", "Yogurt, plain, whole milk", "1 cup (245 g)", 245, kcal: 149, chol: 32, satFat: 5.1, fat: 8),
        food("ice-cream", "Ice cream, vanilla", "1/2 cup (66 g)", 66, kcal: 137, chol: 29, satFat: 4.5, fat: 7.3),
        food("mayo", "Mayonnaise", "1 tbsp", 14, kcal: 94, chol: 6, satFat: 1.6, fat: 10),

        // Meat & poultry
        food("chicken-breast", "Chicken breast, grilled, skinless", "100 g", 100, kcal: 165, chol: 85, satFat: 1, fat: 3.6),
        food("chicken-thigh", "Chicken thigh with skin, roasted", "100 g", 100, kcal: 229, chol: 93, satFat: 4.4, fat: 15.5),
        food("chicken-liver", "Chicken liver, cooked", "100 g", 100, kcal: 167, chol: 564, satFat: 1.6, fat: 4.8),
        food("beef-liver", "Beef liver, cooked", "100 g", 100, kcal: 175, chol: 396, satFat: 1.6, fat: 4.9),
        food("beef-steak", "Beef steak, lean, grilled", "100 g", 100, kcal: 217, chol: 90, satFat: 2.9, fat: 7.6),
        food("ground-beef", "Ground beef (80/20), cooked", "100 g", 100, kcal: 254, chol: 88, satFat: 6, fat: 15.4),
        food("pork-chop", "Pork chop, grilled", "100 g", 100, kcal: 196, chol: 80, satFat: 2.5, fat: 7),
        food("bacon", "Bacon, pan-fried", "3 slices (34 g)", 34, kcal: 161, chol: 36, satFat: 4.1, fat: 12.5, sodium: 581),
        food("lamb", "Lamb / mutton, lean, cooked", "100 g", 100, kcal: 258, chol: 97, satFat: 3.8, fat: 9),
        food("duck", "Duck with skin, roasted", "100 g", 100, kcal: 337, chol: 84, satFat: 11.5, fat: 28),
        food("turkey-breast", "Turkey breast, roasted", "100 g", 100, kcal: 135, chol: 60, satFat: 0.6, fat: 1.7),
        food("sausage", "Pork sausage links", "2 links (54 g)", 54, kcal: 180, chol: 44, satFat: 5.4, fat: 16),
        food("hot-dog", "Hot dog (beef frank)", "1 frank (57 g)", 57, kcal: 186, chol: 24, satFat: 6.1, fat: 16.8, sodium: 572),

        // Seafood
        food("shrimp", "Shrimp / prawns, cooked", "100 g", 100, kcal: 99, chol: 189, satFat: 0.3, fat: 1),
        food("salmon", "Salmon, Atlantic, cooked", "100 g", 100, kcal: 208, chol: 63, satFat: 3.1, fat: 13),
        food("tuna-water", "Tuna, canned in water", "100 g", 100, kcal: 116, chol: 30, satFat: 0.2, fat: 0.8),
        food("sardines", "Sardines, canned in oil", "100 g", 100, kcal: 208, chol: 142, satFat: 1.5, fat: 11.5),
        food("mackerel", "Mackerel, cooked", "100 g", 100, kcal: 262, chol: 75, satFat: 4.2, fat: 17.8),
        food("crab", "Crab, cooked", "100 g", 100, kcal: 97, chol: 100, satFat: 0.2, fat: 1.5),
        food("lobster", "Lobster, cooked", "100 g", 100, kcal: 89, chol: 146, satFat: 0.2, fat: 0.9),
        food("calamari", "Squid (calamari), fried", "100 g", 100, kcal: 175, chol: 260, satFat: 1.6, fat: 7.5),

        // Indian dishes
        food("butter-chicken", "Butter chicken", "1 cup (240 g)", 240, kcal: 430, chol: 105, satFat: 13, fat: 27),
        food("chicken-curry", "Chicken curry", "1 cup (235 g)", 235, kcal: 243, chol: 70, satFat: 3.5, fat: 11),
        food("mutton-curry", "Mutton curry", "1 cup (250 g)", 250, kcal: 320, chol: 90, satFat: 8, fat: 18),
        food("egg-curry", "Egg curry (2 eggs)", "1 cup (240 g)", 240, kcal: 300, chol: 380, satFat: 6, fat: 18),
        food("fish-curry", "Fish curry", "1 cup (240 g)", 240, kcal: 200, chol: 45, satFat: 2, fat: 9),
        food("prawn-masala", "Prawn masala", "1 cup (225 g)", 225, kcal: 240, chol: 190, satFat: 3, fat: 12),
        food("chicken-biryani", "Chicken biryani", "1 cup (200 g)", 200, kcal: 290, chol: 55, satFat: 3, fat: 9),
        food("dal", "Dal (lentil curry)", "1 cup (240 g)", 240, kcal: 198, chol: 0, satFat: 0.5, fat: 6, fiber: 8),
        food("chana-masala", "Chana masala", "1 cup (240 g)", 240, kcal: 210, chol: 0, satFat: 0.6, fat: 6, fiber: 9),
        food("idli", "Idli", "2 idlis (78 g)", 78, kcal: 116, chol: 0, satFat: 0.3, fat: 0.6),
        food("dosa", "Dosa, plain", "1 dosa (120 g)", 120, kcal: 168, chol: 3, satFat: 1.5, fat: 8),
        food("samosa", "Samosa, vegetable", "1 samosa (100 g)", 100, kcal: 262, chol: 0, satFat: 3.2, fat: 17),
        food("medu-vada", "Medu vada", "1 vada (58 g)", 58, kcal: 180, chol: 0, satFat: 1.6, fat: 9),
        food("roti", "Roti / chapati, plain", "1 roti (40 g)", 40, kcal: 104, chol: 0, satFat: 0.1, fat: 0.5, fiber: 2),
        food("poha", "Poha", "1 cup (180 g)", 180, kcal: 180, chol: 0, satFat: 0.5, fat: 5),
        food("upma", "Upma", "1 cup (200 g)", 200, kcal: 192, chol: 0, satFat: 1, fat: 7),

        // Fast food & snacks
        food("cheeseburger", "Cheeseburger, fast food", "1 burger", 114, kcal: 300, chol: 40, satFat: 6, fat: 13, sodium: 680),
        food("pizza-pepperoni", "Pizza, pepperoni", "1 slice (107 g)", 107, kcal: 298, chol: 22, satFat: 5, fat: 12, sodium: 683),
        food("fries", "French fries", "1 medium (117 g)", 117, kcal: 365, chol: 0, satFat: 2.3, fat: 17, sodium: 246),
        food("fried-chicken", "Fried chicken drumstick", "1 drumstick (72 g)", 72, kcal: 176, chol: 62, satFat: 2.7, fat: 11),
        food("croissant", "Croissant, butter", "1 croissant (57 g)", 57, kcal: 231, chol: 38, satFat: 6.6, fat: 12),
        food("donut", "Doughnut, glazed", "1 doughnut (60 g)", 60, kcal: 240, chol: 14, satFat: 3.5, fat: 14),
        food("choc-chip-cookies", "Chocolate chip cookies", "2 cookies (32 g)", 32, kcal: 156, chol: 18, satFat: 3.8, fat: 7.3),
        food("milk-chocolate", "Milk chocolate bar", "1 bar (44 g)", 44, kcal: 235, chol: 10, satFat: 8.1, fat: 13.5),
        food("cake", "Cake with frosting", "1 slice (109 g)", 109, kcal: 400, chol: 55, satFat: 5.5, fat: 14),

        // Heart-healthy staples (zero cholesterol)
        food("oatmeal", "Oatmeal, cooked", "1 cup (234 g)", 234, kcal: 166, chol: 0, satFat: 0.4, fat: 3.6, fiber: 4),
        food("avocado", "Avocado", "1/2 avocado (100 g)", 100, kcal: 160, chol: 0, satFat: 2.1, fat: 14.7, fiber: 6.7),
        food("almonds", "Almonds", "1 oz (28 g)", 28, kcal: 164, chol: 0, satFat: 1.1, fat: 14, fiber: 3.5),
        food("walnuts", "Walnuts", "1 oz (28 g)", 28, kcal: 185, chol: 0, satFat: 1.7, fat: 18.5, fiber: 1.9),
        food("olive-oil", "Olive oil", "1 tbsp (13.5 g)", 13.5, kcal: 119, chol: 0, satFat: 1.9, fat: 13.5),
        food("peanut-butter", "Peanut butter", "2 tbsp (32 g)", 32, kcal: 188, chol: 0, satFat: 3.3, fat: 16, fiber: 1.9),
        food("tofu", "Tofu, firm", "100 g", 100, kcal: 144, chol: 0, satFat: 1.1, fat: 8.7, fiber: 2.3),
        food("white-rice", "Rice, white, cooked", "1 cup (158 g)", 158, kcal: 205, chol: 0, satFat: 0.1, fat: 0.4),
        food("bread-wheat", "Bread, whole wheat", "1 slice (32 g)", 32, kcal: 81, chol: 0, satFat: 0.2, fat: 1.1, fiber: 1.9),
        food("apple", "Apple", "1 medium (182 g)", 182, kcal: 95, chol: 0, satFat: 0, fat: 0.3, fiber: 4.4),
        food("banana", "Banana", "1 medium (118 g)", 118, kcal: 105, chol: 0, satFat: 0.1, fat: 0.4, fiber: 3.1),
        food("broccoli", "Broccoli, cooked", "1 cup (156 g)", 156, kcal: 55, chol: 0, satFat: 0.1, fat: 0.6, fiber: 5.1),
        food("sweet-potato", "Sweet potato, baked", "1 medium (114 g)", 114, kcal: 103, chol: 0, satFat: 0, fat: 0.2, fiber: 3.8)
    ]

    private static let byId: [String: FoodItem] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func get(_ id: String) -> FoodItem? { byId[id] }

    static func search(_ query: String) -> [FoodSearchResult] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        func matchOffset(_ name: String) -> Int {
            let lower = name.lowercased()
            guard let range = lower.range(of: q) else { return Int.max }
            return lower.distance(from: lower.startIndex, to: range.lowerBound)
        }
        return all
            .filter { $0.name.lowercased().contains(q) }
            .sorted { matchOffset($0.name) < matchOffset($1.name) }
            .map { item in
                let s = item.servings[0]
                return FoodSearchResult(
                    id: item.id,
                    name: item.name,
                    brand: nil,
                    summary: "\(s.servingDescription) • \(Int(s.calories)) kcal • \(Int(s.cholesterolMg)) mg chol",
                    source: .builtIn
                )
            }
    }
}
