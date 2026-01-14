
import SwiftUI

struct MergePDFView: View {
    let firstDocument: DocumentEntity
    let viewModel: DocumentsListViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedSecondDocument: DocumentEntity?
    @State private var isMerging = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("Первый документ")) {
                    DocumentInfoRow(document: firstDocument)
                }
                
                Section(header: Text("Выберите второй документ")) {
                    if viewModel.documents.count < 2 {
                        Text("Недостаточно документов для объединения")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.documents.filter { $0.id != firstDocument.id }, id: \.id) { document in
                            Button(action: {
                                selectedSecondDocument = document
                            }) {
                                HStack {
                                    DocumentInfoRow(document: document)
                                    
                                    Spacer()
                                    
                                    if selectedSecondDocument?.id == document.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            if let secondDocument = selectedSecondDocument {
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: {
                        mergeDocuments(first: firstDocument, second: secondDocument)
                    }) {
                        HStack {
                            if isMerging {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "doc.on.doc")
                            }
                            Text(isMerging ? "Объединение..." : "Объединить PDF")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(isMerging ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isMerging)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationTitle("Объединить PDF")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Успешно", isPresented: $showSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("PDF документы успешно объединены")
        }
    }
    
    private func mergeDocuments(first: DocumentEntity, second: DocumentEntity) {
        isMerging = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.viewModel.mergeDocuments(first: first, second: second)
            
            DispatchQueue.main.async {
                self.isMerging = false
                
                if result.success {
                    self.showSuccessAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    self.errorMessage = result.error ?? "Не удалось объединить документы. Проверьте, что файлы существуют и доступны."
                }
            }
        }
    }
}

struct DocumentInfoRow: View {
    let document: DocumentEntity
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumbnailData = document.thumbnail,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                    .clipped()
            } else {
                Image(systemName: "doc.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name ?? "Без названия")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if let createdAt = document.createdAt {
                    Text(createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        MergePDFView(
            firstDocument: DocumentEntity(),
            viewModel: DocumentsListViewModel()
        )
    }
}

