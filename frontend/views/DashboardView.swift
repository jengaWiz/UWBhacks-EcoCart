import SwiftUI

struct DashboardView: View {
    @State private var query: String = ""
    @State private var recommendedItems: [FoodItem] = []
    @State private var allItems: [FoodItem] = []
    @State private var isLoading = true
    @State private var scrollOffset: CGFloat = 0

    var filteredItems: [FoodItem] {
        if query.isEmpty {
            return recommendedItems
        } else {
            return allItems.filter { $0.name.lowercased().contains(query.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("Cream"), Color("LeafGreen")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading...")
                } else {
                    VStack(spacing: 0) {
                        // Search Bar
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                TextField("Search", text: $query)
                                    .textFieldStyle(PlainTextFieldStyle())
                                if !query.isEmpty {
                                    Button(action: { query = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                            .padding(.top, 8)

                            HStack {
                                Text(query.isEmpty ? "Recommended for You" : "Search Results")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(Color("EarthBrown"))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }

                        // Scroll Items
                        ScrollViewReader { proxy in
                            ScrollView(showsIndicators: false) {
                                GeometryReader { geo -> Color in
                                    DispatchQueue.main.async {
                                        self.scrollOffset = geo.frame(in: .global).minY
                                    }
                                    return Color.clear
                                }
                                .frame(height: 0)

                                LazyVStack(spacing: 16) {
                                    if filteredItems.isEmpty {
                                        VStack(spacing: 8) {
                                            Text("No matches found")
                                                .font(.headline)
                                                .foregroundColor(Color("EarthBrown"))
                                                .padding(.top, 50)

                                            Text("Try searching for something else!")
                                                .font(.subheadline)
                                                .foregroundColor(.gray.opacity(0.8))
                                        }
                                        .padding()
                                    } else {
                                        ForEach(filteredItems) { item in
                                            NavigationLink(destination: ProductDetailView(foodItem: item)) {
                                                FoodItemCardView(item: item)
                                            }
                                            .buttonStyle(PressableCardStyle())
                                        }
                                    }
                                }

                                .padding(.top, 12)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("EcoCartSymbol")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)

                        Text("EcoCart")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundColor(Color("EarthBrown"))
                    }
                }
            }

            .onAppear {
                fetchRecommendations()
                fetchAllItems()
            }
        }
    }

    func fetchRecommendations() {
        NetworkManager.shared.fetchRecommendations { result in
            switch result {
            case .success(let items):
                self.recommendedItems = items
                self.isLoading = false
            case .failure(let error):
                print("Failed to load recommendations: \(error)")
            }
        }
    }

    func fetchAllItems() {
        NetworkManager.shared.fetchAllItems { result in
            switch result {
            case .success(let items):
                self.allItems = items
            case .failure(let error):
                print("Failed to load all items: \(error)")
            }
        }
    }
}
