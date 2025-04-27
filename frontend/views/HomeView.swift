import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DashboardView()) {
                    Label("Search Food", systemImage: "magnifyingglass")
                }
                NavigationLink(destination: CartView()) {
                    Label("View Cart", systemImage: "cart")
                }
                NavigationLink(destination: MealPrepView()) {
                    Label("Meal Prep", systemImage: "leaf")
                }
               
            }
            .navigationTitle("EcoCart")
        }
    }
}
