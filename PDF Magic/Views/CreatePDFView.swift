
import SwiftUI
import UniformTypeIdentifiers

struct CreatePDFView: View {
    @StateObject private var viewModel = CreatePDFViewModel()
    @State private var showImagePicker = false
    @State private var showFilePicker = false
    @State private var previewImageWrapper: ImageWrapper?
    @State private var previewFileURLWrapper: URLWrapper?
    @State private var showSuccessMessage = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerButtons
                selectedImagesSection
                selectedFilesSection
                errorMessage
                successMessage
                createButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Создать PDF")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            PHPickerView(isPresented: $showImagePicker) { images in
                viewModel.addImages(images)
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [
                .pdf,
                .image,
                UTType(filenameExtension: "heic") ?? .image
            ],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.addFileURLs(urls)
            case .failure(let error):
                viewModel.errorMessage = "Ошибка выбора файлов: \(error.localizedDescription)"
            }
        }
        .onChange(of: viewModel.createdPDFURL) { newValue in
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onChange(of: viewModel.createdPDFURLs) { newValue in
            if newValue.count > 1 {
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .sheet(item: $previewImageWrapper) { wrapper in
            NavigationView {
                PreviewImageView(image: wrapper.image)
            }
        }
        .sheet(item: $previewFileURLWrapper) { wrapper in
            NavigationView {
                PreviewFileView(fileURL: wrapper.url)
            }
        }
        .onDisappear {
            viewModel.clearSelection()
        }
    }
    
    @ViewBuilder
    private var headerButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                showImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Изображения")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                showFilePicker = true
            }) {
                HStack {
                    Image(systemName: "folder")
                    Text("Файлы")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var selectedImagesSection: some View {
        if !viewModel.selectedImages.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Выбранные изображения (\(viewModel.selectedImages.count))")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Button(action: {
                                    previewImageWrapper = ImageWrapper(image: image)
                                }) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                        .clipped()
                                }
                                
                                Button(action: {
                                    viewModel.removeImage(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private var selectedFilesSection: some View {
        if !viewModel.selectedFileURLs.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Выбранные файлы (\(viewModel.selectedFileURLs.count))")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(Array(viewModel.selectedFileURLs.enumerated()), id: \.offset) { index, url in
                    HStack {
                        Button(action: {
                            previewFileURLWrapper = URLWrapper(url: url)
                        }) {
                            HStack {
                                Image(systemName: url.pathExtension.lowercased() == "pdf" ? "doc.fill" : "photo.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            viewModel.removeFileURL(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private var errorMessage: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var successMessage: some View {
        if showSuccessMessage && viewModel.createdPDFURLs.count > 1 {
            Text("Создано PDF документов: \(viewModel.createdPDFURLs.count)")
                .foregroundColor(.green)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var createButton: some View {
        Button(action: {
            viewModel.createPDF()
        }) {
            if viewModel.isCreatingPDF {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(12)
            } else {
                Text("Создать PDF")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        (viewModel.selectedImages.isEmpty && viewModel.selectedFileURLs.isEmpty) ?
                        Color.gray : Color.blue
                    )
                    .cornerRadius(12)
            }
        }
        .disabled(viewModel.isCreatingPDF || (viewModel.selectedImages.isEmpty && viewModel.selectedFileURLs.isEmpty))
        .padding(.horizontal)
    }
}

#Preview {
    NavigationView {
        CreatePDFView()
    }
}

