
import SwiftUI

struct PreviewImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .navigationTitle("Превью изображения")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBlur()
    }
}

#Preview {
    NavigationView {
        PreviewImageView(image: UIImage(systemName: "photo")!)
    }
}

