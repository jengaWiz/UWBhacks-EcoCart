import Foundation

struct FoodItem: Codable, Identifiable {
    let id = UUID()
    let name: String
    let image_link: String?

    enum CodingKeys: CodingKey {
        case name, image_link
    }
}



struct SustainabilityResponse: Codable {
    let name: String
    let label: String
    let eco_score: Double
    let rationale: String
    let components: [String: Double]
    let total_emissions: Double
    let image_link: String?
}
