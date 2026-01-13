
import SwiftUI
import PDFKit

struct PreviewFileView: View {
    let fileURL: URL
    @Environment(\.presentationMode) var presentationMode
    @State private var loadedImage: UIImage?
    @State private var loadError: String?
    @State private var hasAppeared = false
    
    private var fileExtension: String {
        fileURL.pathExtension.lowercased()
    }
    
    private var isPDF: Bool {
        fileExtension == "pdf"
    }
    
    private var isImage: Bool {
        isImageFile(fileExtension)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            contentView
        }
        .navigationTitle(fileURL.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBlur()
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            
            if isImage && loadedImage == nil && loadError == nil {
                loadImage()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if let error = loadError {
            errorView(message: error)
        } else if isPDF {
            pdfContentView
        } else if isImage {
            imageContentView
        } else {
            unsupportedFormatView
        }
    }
    
    @ViewBuilder
    private var pdfContentView: some View {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            PDFKitView(url: fileURL)
        } else {
            errorView(message: "Файл не найден")
        }
    }
    
    @ViewBuilder
    private var imageContentView: some View {
        if let image = loadedImage {
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        } else if loadError == nil {
            VStack {
                ProgressView()
                Text("Загрузка...")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    @ViewBuilder
    private var unsupportedFormatView: some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Формат файла не поддерживается для просмотра")
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    private func loadImage() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            DispatchQueue.main.async {
                loadError = "Файл не найден"
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                DispatchQueue.main.async {
                    loadedImage = image
                }
            } else {
                DispatchQueue.main.async {
                    loadError = "Не удалось загрузить изображение"
                }
            }
        }
    }
    
    private func isImageFile(_ fileExtension: String) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        return imageExtensions.contains(fileExtension)
    }
    
}

#Preview {
    NavigationView {
        PreviewFileView(fileURL: URL(fileURLWithPath: "/path/to/file.pdf"))
    }
}

