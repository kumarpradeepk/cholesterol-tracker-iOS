import Foundation

struct FatSecretError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Client for the FatSecret Platform API (OAuth 2.0 client-credentials flow).
///
/// Configure credentials in Settings → Food database (FatSecret).
/// Keys at https://platform.fatsecret.com — allowlist your IPs (or "Allow all") for OAuth 2.0.
actor FatSecretClient {
    static let shared = FatSecretClient()

    private let tokenURL = URL(string: "https://oauth.fatsecret.com/connect/token")!
    private let apiURL = URL(string: "https://platform.fatsecret.com/rest/server.api")!

    private var cachedToken: String?
    private var tokenExpiry: Date = .distantPast

    nonisolated var isConfigured: Bool { KeychainStore.hasCredentials }

    // MARK: OAuth

    private func accessToken() async throws -> String {
        if let cachedToken, Date() < tokenExpiry.addingTimeInterval(-60) {
            return cachedToken
        }
        guard KeychainStore.hasCredentials else {
            throw FatSecretError(message: "FatSecret API credentials are not configured")
        }
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        let basic = Data("\(KeychainStore.fatSecretClientId):\(KeychainStore.fatSecretClientSecret)".utf8).base64EncodedString()
        request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("grant_type=client_credentials&scope=basic".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FatSecretError(message: "Authentication failed. Check your Client ID and Secret.")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else {
            throw FatSecretError(message: "No access token in response")
        }
        let expiresIn = (json["expires_in"] as? Double) ?? 86_400
        cachedToken = token
        tokenExpiry = Date().addingTimeInterval(expiresIn)
        return token
    }

    func invalidateToken() {
        cachedToken = nil
        tokenExpiry = .distantPast
    }

    private func api(_ params: [String: String]) async throws -> [String: Any] {
        let token = try await accessToken()
        var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: false)!
        var query = params
        query["format"] = "json"
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FatSecretError(message: "FatSecret request failed")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FatSecretError(message: "Unexpected response format")
        }
        if let error = json["error"] as? [String: Any] {
            throw FatSecretError(message: (error["message"] as? String) ?? "Unknown API error")
        }
        return json
    }

    // MARK: Endpoints

    func searchFoods(query: String, page: Int = 0) async throws -> [FoodSearchResult] {
        let root = try await api([
            "method": "foods.search",
            "search_expression": query,
            "page_number": String(page),
            "max_results": "30"
        ])
        guard let foods = root["foods"] as? [String: Any] else { return [] }
        return asList(foods["food"]).compactMap { item in
            guard let id = str(item, "food_id"), let name = str(item, "food_name") else { return nil }
            return FoodSearchResult(
                id: id,
                name: name,
                brand: str(item, "brand_name"),
                summary: str(item, "food_description") ?? "",
                source: .fatSecret
            )
        }
    }

    func getFood(id: String) async throws -> FoodItem {
        let root = try await api(["method": "food.get.v4", "food_id": id])
        guard let food = root["food"] as? [String: Any] else {
            throw FatSecretError(message: "Food not found")
        }
        let servingsNode = (food["servings"] as? [String: Any])?["serving"]
        let servings: [FoodServing] = asList(servingsNode).compactMap { s in
            FoodServing(
                servingDescription: str(s, "serving_description") ?? "1 serving",
                metricGrams: str(s, "metric_serving_unit") == "g" ? num(s, "metric_serving_amount") : nil,
                calories: num(s, "calories") ?? 0,
                cholesterolMg: num(s, "cholesterol") ?? 0,
                saturatedFatG: num(s, "saturated_fat") ?? 0,
                totalFatG: num(s, "fat") ?? 0,
                sodiumMg: num(s, "sodium"),
                fiberG: num(s, "fiber")
            )
        }
        guard !servings.isEmpty else {
            throw FatSecretError(message: "No nutrition data available for this food")
        }
        return FoodItem(
            id: str(food, "food_id") ?? id,
            name: str(food, "food_name") ?? "Unknown",
            brand: str(food, "brand_name"),
            source: .fatSecret,
            servings: servings
        )
    }

    /// Returns the FatSecret food_id for a barcode (padded to GTIN-13), or nil when unknown.
    func findFoodId(barcode: String) async throws -> String? {
        let digits = barcode.filter(\.isNumber)
        let gtin13 = String(String(repeating: "0", count: max(0, 13 - digits.count)) + digits).suffix(13)
        let root = try await api(["method": "food.find_id_for_barcode", "barcode": String(gtin13)])
        let id = (root["food_id"] as? [String: Any])?["value"] as? String
        guard let id, !id.isEmpty, id != "0" else { return nil }
        return id
    }

    // MARK: JSON helpers (FatSecret returns single objects where arrays are expected, numbers as strings)

    private func asList(_ node: Any?) -> [[String: Any]] {
        if let array = node as? [[String: Any]] { return array }
        if let single = node as? [String: Any] { return [single] }
        return []
    }
    private func str(_ dict: [String: Any], _ key: String) -> String? {
        if let s = dict[key] as? String { return s }
        if let n = dict[key] as? NSNumber { return n.stringValue }
        return nil
    }
    private func num(_ dict: [String: Any], _ key: String) -> Double? {
        str(dict, key).flatMap(Double.init)
    }
}

/// Search outcome: results plus whether the online DB was reachable.
struct FoodSearchOutcome {
    let results: [FoodSearchResult]
    let usedOnlineDatabase: Bool
    var onlineError: String? = nil
}

/// Blends the built-in offline database with FatSecret results.
enum FoodRepository {
    static func search(_ query: String) async -> FoodSearchOutcome {
        let local = BuiltInFoods.search(query)
        guard FatSecretClient.shared.isConfigured else {
            return FoodSearchOutcome(results: local, usedOnlineDatabase: false)
        }
        do {
            let remote = try await FatSecretClient.shared.searchFoods(query: query)
            let localNames = Set(local.map { $0.name.lowercased() })
            let merged = local + remote.filter { !localNames.contains($0.name.lowercased()) || $0.brand != nil }
            return FoodSearchOutcome(results: merged, usedOnlineDatabase: true)
        } catch {
            return FoodSearchOutcome(results: local, usedOnlineDatabase: false, onlineError: error.localizedDescription)
        }
    }

    static func getFood(id: String) async throws -> FoodItem {
        if id.hasPrefix("builtin:") {
            guard let item = BuiltInFoods.get(id) else {
                throw FatSecretError(message: "Unknown food")
            }
            return item
        }
        return try await FatSecretClient.shared.getFood(id: id)
    }

    static func findByBarcode(_ barcode: String) async throws -> FoodItem? {
        guard FatSecretClient.shared.isConfigured else { return nil }
        guard let id = try await FatSecretClient.shared.findFoodId(barcode: barcode) else { return nil }
        return try await FatSecretClient.shared.getFood(id: id)
    }
}
