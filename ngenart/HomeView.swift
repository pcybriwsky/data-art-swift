import SwiftUI
struct HomeView: View {
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""    

let artPieces: [ArtPiece] = [
    ArtPiece(
        title: "Odometer",
        subtitle: "See how far you've walked",
        imageURL: "https://images.unsplash.com/photo-1723843038784-ba892b252323?ixid=M3w4OTk0OHwwfDF8cmFuZG9tfHx8fHx8fHx8MTcyNTU2MDA1NXw&ixlib=rb-4.0.3",
        destinationView: AnyView(GenArtView()),
        description: "null" 
    ),
    ArtPiece(
        title: "Step Count",
        subtitle: "Second piece",
        imageURL: "https://images.unsplash.com/photo-1722345901893-0c12056b464e?ixid=M3w4OTk0OHwwfDF8cmFuZG9tfHx8fHx8fHx8MTcyNTU1OTY2Nnw&ixlib=rb-4.0.3",
        destinationView: AnyView(StepArtView()),
        description: ""
    ),
    ArtPiece(
        title: "Placeholder",
        subtitle: "See more data",
        imageURL: "https://images.unsplash.com/photo-1722345901893-0c12056b464e?ixid=M3w4OTk0OHwwfDF8cmFuZG9tfHx8fHx8fHx8MTcyNTU1OTY2Nnw&ixlib=rb-4.0.3",
        destinationView: AnyView(GenArtView()),
        description: ""
    )
    // Add more art pieces here as you create them
]

// This is pretty good example of how to create a basic function for the app tbh -- should use this for a lot of other stuff
private var greeting: String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 6..<12:
        return "Good morning, \(userName)"
    case 12..<17:
        return "Good afternoon, \(userName)"
    case 17..<24:
        return "Good evening, \(userName)"
    default:
        return "Go to sleep, \(userName)"
    }
}

@State private var showSettings = false

@State var geo: CGSize = .zero
var body: some View {
    NavigationView { // Always need this to wrap any navigation link.
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading) {
            }
            .frame(maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)
            .overlay(
                VStack(alignment: .leading, spacing:16) {
                    HStack(alignment: .top, spacing:0) {
                        Text(greeting)
                        // MARK: Add BodoniModa18pt-Italic file to Xcode, and reference it below:
                            .font(.custom("BodoniModa18pt-Italic", size: 24))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 50, alignment: .leading)
                            .clipped()
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 48) {
                            ForEach(Array(artPieces.enumerated()), id: \.element.id) { index, piece in
                                CardView(artPiece: piece)
                                    .frame(width: 329, height: 500)
                                    .scaleEffect(0.85)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 500)
                    VStack(alignment: .leading, spacing:0) {}
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .frame(height: 100, alignment: .topLeading)
                        .overlay(alignment: .bottom) { 
                            Button(action: {
                                showSettings.toggle()
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 32, weight: .regular))
                                    .foregroundStyle(Color(hex: 0x0a0a0a))
                                    .frame(width: 44, height: 44)
                            }
                        }
                }
                    .padding(16)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color(hex: 0xfffef7))
                    .padding(1)
                    .offset(y: 72)
                , alignment: .top)
            .ignoresSafeArea(.all, edges: [.bottom])
        }
        .frame(minWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height, alignment: .topLeading)
        .background(Color(hex: 0xfffef7).ignoresSafeArea())
        .ignoresSafeArea(.all, edges: [.bottom])
        .onAppear {
            userName = UserDefaults.standard.string(forKey: "userName") ?? ""
            // print("HomeView appeared")
            // print("Start year on HomeView load: \(UserManager.shared.startYear)")
            // print("Use imperial units on HomeView load: \(UserManager.shared.useImperialUnits)")
        }
        .onChange(of: showSettings) { newValue in
            if !newValue {
                userName = UserDefaults.standard.string(forKey: "userName") ?? ""
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    }
}

struct CardView: View {
    @StateObject private var motionManager = MotionManager()
    struct Rotation3DEffect: ViewModifier {
    let rotationX: Double
    let rotationY: Double
    let rotationZ: Double  

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(rotationY * 10), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(rotationX * 10), axis: (x: 0, y: 1, z: 0))
            .rotation3DEffect(.degrees(rotationZ * 10), axis: (x: 0, y: 0, z: 1))
    }
}



    let artPiece: ArtPiece
    
    @GestureState private var isTapped = false
    @State private var isEnlarged = false
    
    var body: some View {
        NavigationLink(destination: artPiece.destinationView) {
            ZStack {
                AsyncImage(url: URL(string: artPiece.imageURL)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                
                VStack(spacing: 8) {
                    Text(artPiece.title)
                        .font(.custom("BodoniModa18pt-Regular", size: 34))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(artPiece.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(
                    LinearGradient(gradient: Gradient(stops: [
                        .init(color: Color(hex: 0x0a0a0a), location: 0.268),
                        .init(color: Color(hex: 0x0a0a0a, alpha: 0), location: 1)
                    ]), startPoint: .bottom, endPoint: .top)
                )
            }
            .frame(width: 329, height: 500)
            .background(.white)
            .cornerRadius(16)
            .shadow(color: Color(hex: 0x0a0a0a, alpha: 0.57), radius: 4, x: 4, y: 5)
            .scaleEffect(isTapped || isEnlarged ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTapped || isEnlarged)
        }
        .buttonStyle(PlainButtonStyle()) // This prevents the default button style from interfering with our custom style
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isTapped) { _, isTapped, _ in
                    isTapped = true
                }
                .onEnded { _ in
                    if !isEnlarged {
                        hapticFeedback()
                    }
                }
        )
         .modifier(Rotation3DEffect(
            rotationX: motionManager.x * 0.1,
            rotationY: motionManager.y * 0.1,
            rotationZ: motionManager.z * 0.1
        ))
    }
    
    private func hapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

#Preview {
        HomeView()
}
