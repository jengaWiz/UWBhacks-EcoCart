import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            MealPrepView()
                .tabItem {
                    Label("Meal Prep", systemImage: "leaf")
                }

            CartView()
                .tabItem {
                    Label("Cart", systemImage: "cart")
                }
        }
        .accentColor(Color("EarthBrown")) 
    }
}
