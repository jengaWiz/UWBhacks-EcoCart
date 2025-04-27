import SwiftUI

@main
struct Eco_CartApp: App {
    @State private var showLanding = true
    @StateObject var cartManager = CartManager()
    var body: some Scene {
        WindowGroup {
            if showLanding {
                LandingView(showLanding: $showLanding)
                    .environmentObject(cartManager)
            } else {
                MainTabView()
                    .environmentObject(cartManager)
            }
        }
    }
}
    
