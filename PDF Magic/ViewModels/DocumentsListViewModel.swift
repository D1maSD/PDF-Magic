
import Foundation
import CoreData
import SwiftUI

class DocumentsListViewModel: ObservableObject {
    @Published var documents: [DocumentEntity] = []
    
    private let persistenceController = PersistenceController.shared
    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(documentsListUpdated),
            name: NSNotification.Name("DocumentsListUpdated"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func documentsListUpdated() {
        loadDocuments()
    }
    
    func loadDocuments() {
        let request: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DocumentEntity.createdAt, ascending: false)]
        
        do {
            documents = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch documents: \(error.localizedDescription)")
            documents = []
        }
    }
    
    func deleteDocument(_ document: DocumentEntity) {
        if let fileName = document.fileURL {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        viewContext.delete(document)
        
        do {
            try viewContext.save()
            loadDocuments() 
        } catch {
            print("Failed to delete document: \(error.localizedDescription)")
        }
    }
    
    func mergeDocuments(first: DocumentEntity, second: DocumentEntity) -> (success: Bool, error: String?) {
        guard let firstName = first.fileURL,
              let secondName = second.fileURL else {
            print("DocumentsListViewModel: Failed to get file URLs")
            return (false, "Не удалось получить пути к файлам")
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let firstURL = documentsDirectory.appendingPathComponent(firstName)
        let secondURL = documentsDirectory.appendingPathComponent(secondName)
        
        print("DocumentsListViewModel: Merging PDFs:")
        print("  First: \(firstURL.path)")
        print("  Second: \(secondURL.path)")
        
        if !FileManager.default.fileExists(atPath: firstURL.path) {
            print("DocumentsListViewModel: First file does not exist")
            return (false, "Первый файл не найден: \(firstName)")
        }
        
        if !FileManager.default.fileExists(atPath: secondURL.path) {
            print("DocumentsListViewModel: Second file does not exist")
            return (false, "Второй файл не найден: \(secondName)")
        }
        
        let pdfService = PDFService.shared
        
        guard let mergedPDFURL = pdfService.mergePDFs(firstPDFURL: firstURL, secondPDFURL: secondURL) else {
            print("DocumentsListViewModel: Failed to merge PDFs")
            return (false, "Не удалось объединить PDF документы. Проверьте, что файлы не повреждены.")
        }
        
        print("DocumentsListViewModel: PDFs merged successfully to: \(mergedPDFURL.path)")
        
        guard let thumbnailData = pdfService.generateThumbnail(from: mergedPDFURL) else {
            print("DocumentsListViewModel: Failed to generate thumbnail")
            try? FileManager.default.removeItem(at: mergedPDFURL)
            return (false, "Не удалось создать миниатюру для объединенного документа")
        }
        
        let mergedDocument = DocumentEntity(context: viewContext)
        mergedDocument.id = UUID()
        mergedDocument.name = "Объединенный_\(mergedPDFURL.lastPathComponent)"
        mergedDocument.fileURL = mergedPDFURL.lastPathComponent
        mergedDocument.createdAt = Date()
        mergedDocument.thumbnail = thumbnailData
        
        do {
            try viewContext.save()
            print("DocumentsListViewModel: Merged document saved to CoreData")
            
            DispatchQueue.main.async { [weak self] in
                self?.loadDocuments()
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("DocumentsListUpdated"), object: nil)
            
            return (true, nil)
        } catch {
            print("DocumentsListViewModel: Failed to save merged document: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: mergedPDFURL)
            return (false, "Не удалось сохранить объединенный документ: \(error.localizedDescription)")
        }
    }
    
    func shareDocument(_ document: DocumentEntity) {
        print("Share document: \(document.name ?? "Unknown")")
    }
}
