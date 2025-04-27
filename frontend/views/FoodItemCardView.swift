import SwiftUI

struct FoodItemCardView: View {
    let item: FoodItem

    var body: some View {
        HStack(spacing: 16) {
            if let link = item.image_link, let url = URL(string: link) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        Color.gray
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
        .padding(.horizontal, 12)
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
