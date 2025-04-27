import SwiftUI

struct LandingView: View {
    @Binding var showLanding: Bool

    var body: some View {
        NavigationView {
            ZStack {
               
                LinearGradient(
                    gradient: Gradient(colors: [Color("Cream"), Color("LeafGreen")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                
                VStack {
                    Text("EcoCart")
                        .font(Font.custom("Quicksand-Bold", size: 48))
                        .foregroundColor(Color("EarthBrown"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 70)

                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .top)

                
                Image("EcoCartSymbol")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
                    .padding(.bottom, 130)

               
                VStack {
                    Spacer()
                    Button(action: {
                        showLanding = false 
                    }) {
                        Text("Get Started")
                            .font(Font.custom("Quicksand-SemiBold", size: 18))
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 40)
                            .background(Color("EarthBrown"))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 70)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
