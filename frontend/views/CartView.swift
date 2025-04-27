import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager

    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [Color("Cream"), Color("LeafGreen")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                
                Text("Your Cart")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                if cartManager.cartItems.isEmpty {
                    Spacer()

                    VStack(spacing: 16) {
                        Text("🛒 Your cart is empty")
                            .font(.title2)
                            .fontWeight(.semibold)

                        NavigationLink(destination: DashboardView()) {
                            Text("Search Items")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color("EarthBrown"))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                    }

                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(cartManager.cartItems) { item in
                                CartItemCardView(item: item)
                                    .environmentObject(cartManager)
                            }
                        }
                        .padding(.top)
                    }
                    

                    VStack {
                        Text("Overall Score:")
                            .font(.headline)

                        Text(String(format: "%.1f/10", cartManager.calculateAverageScore()))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 8)
                    .padding()
                }
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(true)
    }
}



struct CartItemCardView: View {
    let item: EcoCartItem
    @EnvironmentObject var cartManager: CartManager

    var body: some View {
        HStack(spacing: 16) {
            if let url = URL(string: item.imageName) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Color.gray
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(String(format: "Eco-Score: %.1f/10", item.score))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                cartManager.removeFromCart(item: item)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 10)
    }
}
