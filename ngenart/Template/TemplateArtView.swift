import SwiftUI

struct TemplateArtView<Renderer: TemplateArtRenderer>: View {
    @StateObject var renderer: Renderer

    var body: some View {
        VStack(alignment: .leading) {
            Text(renderer.artPiece.title)
                .font(.custom("BodoniModa18pt-Italic", size: 24))
                .padding(8)
            
            Image(uiImage: renderer.renderArt(size: CGSize(width: 338, height: 158)))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 170)
                .background(Color(hex: 0xf6f6f6))
                .cornerRadius(8)
            
            Text(renderer.artPiece.description)
                .font(.system(size: 17))
                .padding(8)
            
            // TODO: Add more UI elements as needed
        }
        .padding(16)
        .background(Color(hex: 0xfffef7))
        .onAppear {
            // TODO: Implement any necessary setup or authorization here
            renderer.fetchData()
        }
    }
}
