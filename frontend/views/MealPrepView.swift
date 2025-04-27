// MARK: - MealPrepView + MealCardView
import SwiftUI

struct MealPrepView: View {
    @EnvironmentObject var cartManager: CartManager

    @State private var isLoading = false
    @State private var generatedMeals: [MealRecipe] = []
    @State private var showingMeals = false

    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [Color("Cream"), Color("LeafGreen")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Generating Meal Plan...")
                        .padding()
                } else if showingMeals {
                    
                    HStack {
                        Text("Meal Ideas")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color("EarthBrown"))

                        Spacer()

                        Button(action: {
                            generatedMeals = []
                            showingMeals = false
                        }) {
                            Text("Clear")
                                .font(.headline)
                                .foregroundColor(Color("EarthBrown"))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(generatedMeals) { meal in
                                MealCardView(meal: meal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                } else {
                    
                    Spacer().frame(height: 40)

                    HStack(spacing: 20) {
                        Button(action: {
                            generateRandomMeals()
                        }) {
                            Text("Random")
                                .fontWeight(.semibold)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 28)
                                .background(Color("LeafGreen"))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 4)
                        }

                        Button(action: {
                            generateCartMeals()
                        }) {
                            Text("Use Cart")
                                .fontWeight(.semibold)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 28)
                                .background(Color("EarthBrown"))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 4)
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Meal Prep")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color("EarthBrown"))

                        Text("AI-powered recipe guide")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Functions

    func generateRandomMeals() {
        isLoading = true
        NetworkManager.shared.generateRandomMeals { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let meals):
                    self.generatedMeals = meals
                    self.showingMeals = true
                case .failure(let error):
                    print("❌ Failed to generate random meals: \(error)")
                }
            }
        }
    }

    func generateCartMeals() {
        isLoading = true
        let cartItems = cartManager.cartItems.map { $0.name }
        NetworkManager.shared.generateCartMeals(cartItems: cartItems) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let meals):
                    self.generatedMeals = meals
                    self.showingMeals = true
                case .failure(let error):
                    print("❌ Failed to generate cart meals: \(error)")
                }
            }
        }
    }
}

// MARK: - Meal Card View
struct MealCardView: View {
    let meal: MealRecipe
    @EnvironmentObject var cartManager: CartManager

    var missingItems: [String] {
        let userCartNames = cartManager.cartItems.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        return meal.ingredients.filter { ingredient in
            let cleanIngredient = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return !userCartNames.contains(cleanIngredient)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(meal.meal_name)
                .font(.title3)
                .fontWeight(.bold)

            Text(meal.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Ingredients:")
                    .font(.headline)

                ForEach(meal.ingredients, id: \.self) { ingredient in
                    Text("• \(ingredient)")
                        .font(.body)
                }
            }

            if !missingItems.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Missing Items:")
                        .font(.headline)

                    ForEach(missingItems, id: \.self) { missingItem in
                        Text("• \(missingItem)")
                            .font(.body)
                    }

                    Button(action: {
                        addMissingItemsToCart(missingItems)
                    }) {
                        Text("Add Missing Items to Cart")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("EarthBrown"))
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 6)
        .padding(.horizontal)
    }

    func addMissingItemsToCart(_ items: [String]) {
        for itemName in items {
            let item = EcoCartItem(name: itemName, imageName: "", description: "", score: 0.0)
            if !cartManager.cartItems.contains(where: { $0.name == item.name }) {
                cartManager.addToCart(item: item)
            }
        }
    }
}
