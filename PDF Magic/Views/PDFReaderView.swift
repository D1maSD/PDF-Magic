
import SwiftUI
import PDFKit

struct PDFReaderView: View {
    let pdfURL: URL
    let isNewDocument: Bool
    
    @StateObject private var viewModel = PDFReaderViewModel()
    @State private var showDeletePageAlert = false
    @State private var pageToDelete: Int?
    @State private var showShareSheet = false
    @State private var showSaveAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            PDFKitView(url: pdfURL)
            
            HStack(spacing: 20) {
                Button(action: {
                    if let currentPage = viewModel.currentPageIndex {
                        pageToDelete = currentPage
                        showDeletePageAlert = true
                    }
                }) {
                    VStack {
                        Image(systemName: "trash")
                        Text("Удалить")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
                .disabled(viewModel.currentPageIndex == nil)
                
                Button(action: {
                    viewModel.rotateCurrentPage(pdfURL: pdfURL)
                }) {
                    VStack {
                        Image(systemName: "rotate.right")
                        Text("Повернуть")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
                .disabled(viewModel.currentPageIndex == nil)
                
                Spacer()
                
                Text("\(viewModel.currentPageIndex.map { $0 + 1 } ?? 0) / \(viewModel.totalPages)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showShareSheet = true
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Поделиться")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                if isNewDocument {
                    Button(action: {
                        viewModel.saveDocument(pdfURL: pdfURL)
                    }) {
                        VStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text(viewModel.isSaving ? "Сохранение..." : "Сохранить")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                    .disabled(viewModel.isSaving)
                } else if isNewDocument && viewModel.saveSuccess {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Сохранено")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 2)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBlur()
        .onAppear {
            viewModel.loadPDF(url: pdfURL)
        }
        .alert("Удалить страницу?", isPresented: $showDeletePageAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let pageIndex = pageToDelete {
                    viewModel.deletePage(at: pageIndex, from: pdfURL)
                }
            }
        } message: {
            Text("Страница \(pageToDelete.map { $0 + 1 } ?? 0) будет удалена из документа.")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [pdfURL])
        }
        .onChange(of: viewModel.saveSuccess) { success in
            if success {
                showSaveAlert = true
            }
        }
        .onChange(of: viewModel.saveError) { error in
            if error != nil {
                showSaveAlert = true
            }
        }
        .alert("Сохранение", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.saveError {
                Text(error)
            } else if viewModel.saveSuccess {
                Text("Документ успешно сохранен")
            }
        }
    }
}


struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}


