import Foundation

struct MealRecipe: Identifiable, Codable {
    let id = UUID()
    let meal_name: String
    let description: String
    let ingredients: [String]
    let missing_items: [String]?
}
