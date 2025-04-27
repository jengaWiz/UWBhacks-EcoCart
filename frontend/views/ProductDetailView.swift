import SwiftUI

struct ProductDetailView: View {
    let foodItem: FoodItem

    @EnvironmentObject var cartManager: CartManager
    @State private var sustainability: SustainabilityResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isAddedToCart = false

    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [Color("Cream"), Color("LeafGreen")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                if isLoading {
                    ProgressView("Loading sustainability...")
                        .padding(.top, 100)
                    Spacer()
                } else if let sustainability = sustainability {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            if let imageLink = sustainability.image_link, let url = URL(string: imageLink) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .shadow(radius: 5)
                                    } else if phase.error != nil {
                                        Color.red.frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                    } else {
                                        ProgressView()
                                            .frame(height: 200)
                                    }
                                }
                                .padding(.horizontal)
                            }

                        
                            VStack(alignment: .leading, spacing: 20) {
                                Text(sustainability.name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)

                                Text("Overall Eco-Score: \(String(format: "%.1f/10", sustainability.eco_score))")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorForScore(sustainability.eco_score))

                                Text("Sustainability Label: \(sustainability.label)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Divider()

                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Eco-Score Summary")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("EarthBrown"))

                                    VStack(alignment: .leading, spacing: 8) {
                                        bulletPoint(title: "Total Carbon Footprint", value: "\(String(format: "%.2f", sustainability.total_emissions)) kg CO₂e/kg", color: colorForScore(sustainability.eco_score))
                                        bulletPoint(title: "Agriculture Emissions", value: "~0.43 kg CO₂e/kg", color: .secondary)
                                        bulletPoint(title: "Transport Emissions", value: "~0.25 kg CO₂e/kg", color: .secondary)
                                        bulletPoint(title: "Packaging Emissions", value: "~0.14 kg CO₂e/kg", color: .secondary)
                                    }
                                    .padding(.top, 8)
                                }

                                Divider()

                                VStack(alignment: .leading, spacing: 12) {
                                    formatRationaleText(sustainability.rationale)
                                        .lineSpacing(6)
                                        .padding(.top, 4)

                               }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .shadow(radius: 8)
                            .padding(.bottom, 100)
                        }
                    }
                } else if let error = errorMessage {
                    Text("⚠️ \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                }
            }
        }
        
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if sustainability != nil {
                Button(action: {
                    if !isAddedToCart {
                        let item = EcoCartItem(
                            name: foodItem.name,
                            imageName: foodItem.image_link ?? "",
                            description: "",
                            score: sustainability?.eco_score ?? 0.0
                        )
                        cartManager.addToCart(item: item)
                        isAddedToCart = true
                    }
                }) {
                    HStack {
                        if isAddedToCart {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Added")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        } else {
                            Text("Add to Cart")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isAddedToCart ? Color.green : Color("EarthBrown"))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .shadow(radius: 5)
                }
                .padding(.bottom, 12)
                .disabled(isAddedToCart)
            }
        }
        .onAppear {
            fetchSustainability()
        }
    }

    func fetchSustainability() {
        NetworkManager.shared.classifyItem(foodName: foodItem.name) { result in
            switch result {
            case .success(let data):
                self.sustainability = data
                self.isLoading = false
            case .failure(let error):
                print("❌ Failed to load sustainability: \(error)")
                self.errorMessage = "Failed to load sustainability info."
                self.isLoading = false
            }
        }
    }

    func colorForScore(_ score: Double) -> Color {
        if score >= 7.0 {
            return .green
        } else if score >= 4.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    func formatRationaleText(_ text: String) -> Text {
        var cleanedText = text.replacingOccurrences(of: #"(?m)^\d+\.\s?"#, with: "", options: .regularExpression)
        let sections = cleanedText.components(separatedBy: "\n\n")
        var formattedText = Text("")

        for section in sections {
            let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.lowercased().contains("eco-score summary") {
                formattedText = formattedText + Text("\n\(trimmed)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("EarthBrown"))
            } else if trimmed.lowercased().contains("recommendation") {
                formattedText = formattedText + Text("\n\n\(trimmed)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("EarthBrown"))
            } else {
                if trimmed.count > 400 {
                   
                    let sentences = trimmed.components(separatedBy: ". ")
                    var currentChunk = ""

                    for sentence in sentences {
                        if currentChunk.count + sentence.count < 250 {
                            currentChunk += sentence + ". "
                        } else {
                            formattedText = formattedText + Text("\n\n" + currentChunk.trimmingCharacters(in: .whitespaces))
                                .font(.body)
                                .foregroundColor(.secondary)
                            currentChunk = sentence + ". "
                        }
                    }

                    if !currentChunk.isEmpty {
                        formattedText = formattedText + Text("\n\n" + currentChunk.trimmingCharacters(in: .whitespaces))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                } else {
                    formattedText = formattedText + Text("\n\n\(trimmed)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }

        return formattedText
    }






    // MARK: - Bullet Point Helper
    func bulletPoint(title: String, value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.headline)
                .foregroundColor(color)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(color.opacity(0.8))
            }
        }
    }
}
