
import Foundation
import CoreData
import SwiftUI
import PDFKit

class PDFReaderViewModel: ObservableObject {
    @Published var currentPageIndex: Int?
    @Published var totalPages: Int = 0
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var saveError: String?
    
    private let pdfService = PDFService.shared
    private let persistenceController = PersistenceController.shared
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pageChanged(_:)),
            name: NSNotification.Name("PDFPageChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadPDF(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("PDF file does not exist at path: \(url.path)")
            return
        }
        
        guard let document = PDFDocument(url: url) else {
            print("Failed to load PDF document from URL: \(url)")
            return
        }
        
        totalPages = document.pageCount
        currentPageIndex = 0
    }
    
    func rotateCurrentPage(pdfURL: URL) {
        guard let pageIndex = currentPageIndex else { return }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("PDFRotatePage"),
            object: nil,
            userInfo: ["pageIndex": pageIndex]
        )
    }
    
    func deletePage(at index: Int, from pdfURL: URL) {
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            print("PDF file does not exist at path: \(pdfURL.path)")
            return
        }
        
        guard pdfService.deletePage(at: index, from: pdfURL) else {
            print("Failed to delete page at index: \(index)")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let document = PDFDocument(url: pdfURL) {
                self.totalPages = document.pageCount
                if index >= self.totalPages {
                    self.currentPageIndex = max(0, self.totalPages - 1)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PDFReloadRequired"),
                    object: nil
                )
            }
        }
    }
    
    func saveDocument(pdfURL: URL) {
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            print("PDF file does not exist at path: \(pdfURL.path)")
            saveError = "Файл не найден"
            return
        }
        
        guard !isSaving else { return }
        
        isSaving = true
        saveError = nil
        saveSuccess = false
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let context = self.persistenceController.viewContext
            
            let thumbnailData = self.pdfService.generateThumbnail(from: pdfURL)
            
            let document = DocumentEntity(context: context)
            document.id = UUID()
            document.name = pdfURL.lastPathComponent
            document.fileURL = pdfURL.lastPathComponent
            document.createdAt = Date()
            document.thumbnail = thumbnailData
            
            do {
                try context.save()
                
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.saveSuccess = true
                    
                    NotificationCenter.default.post(name: NSNotification.Name("DocumentsListUpdated"), object: nil)
                }
            } catch {
                print("Failed to save document: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.saveError = "Не удалось сохранить документ: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @objc private func pageChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let pageIndex = userInfo["pageIndex"] as? Int,
           let total = userInfo["totalPages"] as? Int {
            currentPageIndex = pageIndex
            totalPages = total
        }
    }
}

