import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    let baseURL = "http://127.0.0.1:8000"
    private init() {}

    func fetchAllItems(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/all_items") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            if let data = data {
                do {
                    let items = try JSONDecoder().decode([FoodItem].self, from: data)
                    DispatchQueue.main.async { completion(.success(items)) }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
        }.resume()
    }

    func fetchRecommendations(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/recommendations") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            if let data = data {
                do {
                    let items = try JSONDecoder().decode([FoodItem].self, from: data)
                    DispatchQueue.main.async { completion(.success(items)) }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
        }.resume()
    }

    func classifyItem(foodName: String, completion: @escaping (Result<SustainabilityResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/classify") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["food_name": foodName]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(NetworkError.noData)) }
                return
            }
            do {
                let result = try JSONDecoder().decode(SustainabilityResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(result)) }
            } catch {
                print("⚠️ Decoding Error: \(error.localizedDescription)")
                if let str = String(data: data, encoding: .utf8) {
                    print("⚠️ Server Response Was: \(str)")
                }
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }


    func generateRandomMeals(completion: @escaping (Result<[MealRecipe], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/generate_random_meals") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            do {
                let meals = try JSONDecoder().decode([MealRecipe].self, from: data)
                completion(.success(meals))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


    
    func generateCartMeals(cartItems: [String], completion: @escaping (Result<[MealRecipe], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/generate_cart_meals") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try? JSONEncoder().encode(cartItems)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(CartMealResult.self, from: data)
                completion(.success(decoded.meals.meals))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct MealResult: Codable {
    let meals: [MealRecipe]
}

struct CartMealResult: Codable {
    let used_cart_items: [String]
    let added_recommendations: [String]
    let final_ingredients_used: [String]
    let meals: MealResult
}

enum NetworkError: Error {
    case invalidURL
    case noData
}
