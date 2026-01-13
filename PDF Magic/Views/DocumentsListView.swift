
import SwiftUI
import UIKit

struct DocumentsListView: View {
    @StateObject private var viewModel = DocumentsListViewModel()
    @State private var showCreatePDF = false
    
    var body: some View {
        List {
            if viewModel.documents.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Нет документов")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Добавьте ваш первый PDF документ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(viewModel.documents, id: \.id) { document in
                    DocumentRowView(document: document, viewModel: viewModel)
                }
            }
        }
        .navigationTitle("Документы")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCreatePDF = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreatePDF) {
            NavigationView {
                CreatePDFView()
            }
        }
        .onAppear {
            viewModel.loadDocuments()
        }
    }
}

struct DocumentRowView: View {
    let document: DocumentEntity
    let viewModel: DocumentsListViewModel
    @State private var showPDFReader = false
    @State private var showMergeView = false
    
    var body: some View {
        NavigationLink(destination: pdfReaderView) {
            HStack(spacing: 12) {
                Group {
                    if let thumbnailData = document.thumbnail,
                       !thumbnailData.isEmpty,
                       let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    } else {
                        Image(systemName: "doc.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.blue.opacity(0.1))
                    }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .clipped()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.name ?? "Без названия")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    HStack(spacing: 8) {
                        Text("PDF")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                        
                        if let createdAt = document.createdAt {
                            Text(createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .contextMenu {
            if viewModel.documents.count >= 2 {
                Button(action: {
                    showMergeView = true
                }) {
                    Label("Объединить", systemImage: "doc.on.doc")
                }
            }
            
            Button(action: {
                viewModel.shareDocument(document)
            }) {
                Label("Поделиться", systemImage: "square.and.arrow.up")
            }
            
            Button(role: .destructive, action: {
                viewModel.deleteDocument(document)
            }) {
                Label("Удалить", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showMergeView) {
            NavigationView {
                MergePDFView(firstDocument: document, viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    private var pdfReaderView: some View {
        if let fileName = document.fileURL {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                PDFReaderView(pdfURL: fileURL, isNewDocument: false)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Файл не найден")
                        .font(.headline)
                    
                    Text("Файл \(document.name ?? "документ") был удален или перемещен.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
}

#Preview {
    NavigationView {
        DocumentsListView()
    }
}
