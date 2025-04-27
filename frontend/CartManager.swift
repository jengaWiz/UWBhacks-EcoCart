import SwiftUI

class CartManager: ObservableObject {
    @Published var cartItems: [EcoCartItem] = []

    func addToCart(item: EcoCartItem) {
        if !cartItems.contains(where: { $0.name == item.name }) {
            cartItems.append(item)
        }
    }

    func removeFromCart(item: EcoCartItem) {
        cartItems.removeAll { $0.id == item.id }
    }

    func calculateAverageScore() -> Double {
        guard !cartItems.isEmpty else { return 0.0 }
        let total = cartItems.map { $0.score }.reduce(0, +)
        return total / Double(cartItems.count)
    }
}


struct EcoCartItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let imageName: String
    let description: String
    let score: Double
}
