
import Foundation
import SwiftUI
import CoreData
import UniformTypeIdentifiers

class CreatePDFViewModel: ObservableObject {
    @Published var selectedImages: [UIImage] = []
    @Published var selectedFileURLs: [URL] = []
    @Published var isCreatingPDF = false
    @Published var createdPDFURL: URL?
    @Published var createdPDFURLs: [URL] = []
    @Published var errorMessage: String?
    
    private let pdfService = PDFService.shared
    private let persistenceController = PersistenceController.shared
    
    func addImages(_ images: [UIImage]) {
        selectedImages.append(contentsOf: images)
    }
    
    func addFileURLs(_ urls: [URL]) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var copiedURLs: [URL] = []
        
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource: \(url)")
                continue
            }
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            guard fileManager.fileExists(atPath: url.path) else {
                print("File does not exist: \(url.path)")
                continue
            }
            
            let fileName = url.lastPathComponent
            let destinationURL = documentsDirectory.appendingPathComponent(fileName)
            
            var finalDestinationURL = destinationURL
            if fileManager.fileExists(atPath: destinationURL.path) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let timestamp = dateFormatter.string(from: Date())
                let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
                let fileExtension = url.pathExtension
                finalDestinationURL = documentsDirectory.appendingPathComponent("\(nameWithoutExtension)_\(timestamp).\(fileExtension)")
            }
            
            do {
                try fileManager.copyItem(at: url, to: finalDestinationURL)
                copiedURLs.append(finalDestinationURL)
            } catch {
                print("Failed to copy file: \(error.localizedDescription)")
            }
        }
        
        selectedFileURLs.append(contentsOf: copiedURLs)
    }
    
    func removeImage(at index: Int) {
        guard index >= 0 && index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    func removeFileURL(at index: Int) {
        guard index >= 0 && index < selectedFileURLs.count else { return }
        
        let urlToRemove = selectedFileURLs[index]
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if urlToRemove.path.hasPrefix(documentsDirectory.path) {
            let fileName = urlToRemove.lastPathComponent
            let context = persistenceController.viewContext
            let request: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "fileURL == %@", fileName)
            
            do {
                let existingDocuments = try context.fetch(request)
                if existingDocuments.isEmpty {
                    try? FileManager.default.removeItem(at: urlToRemove)
                }
            } catch {
                print("CreatePDFViewModel: Failed to check if file is saved in CoreData: \(error.localizedDescription)")
            }
        }
        
        selectedFileURLs.remove(at: index)
    }
    
    func createPDF() {
        guard !selectedImages.isEmpty || !selectedFileURLs.isEmpty else {
            errorMessage = "Выберите изображения или файлы для создания PDF"
            return
        }
        
        for fileURL in selectedFileURLs {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                errorMessage = "Файл не найден: \(fileURL.lastPathComponent)"
                return
            }
        }
        
        isCreatingPDF = true
        errorMessage = nil
        createdPDFURLs.removeAll()
        
        for image in selectedImages {
            if let pdfURL = pdfService.createPDF(from: [image]) {
                if FileManager.default.fileExists(atPath: pdfURL.path) {
                    print("CreatePDFViewModel: Created PDF from image: \(pdfURL.lastPathComponent)")
                    createdPDFURLs.append(pdfURL)
                    savePDFToCoreData(pdfURL: pdfURL)
                    
                    if !FileManager.default.fileExists(atPath: pdfURL.path) {
                        print("CreatePDFViewModel: ERROR - PDF file was deleted after saving to CoreData: \(pdfURL.path)")
                    }
                } else {
                    print("CreatePDFViewModel: ERROR - Created PDF file does not exist: \(pdfURL.path)")
                }
            }
        }
        
        for fileURL in selectedFileURLs {
            let fileExtension = fileURL.pathExtension.lowercased()
            
            if fileExtension == "pdf" {
                if let copiedPDFURL = copyPDFFile(fileURL) {
                    if FileManager.default.fileExists(atPath: copiedPDFURL.path) {
                        print("CreatePDFViewModel: Copied PDF file: \(copiedPDFURL.lastPathComponent)")
                        createdPDFURLs.append(copiedPDFURL)
                        savePDFToCoreData(pdfURL: copiedPDFURL)
                        
                        if !FileManager.default.fileExists(atPath: copiedPDFURL.path) {
                            print("CreatePDFViewModel: ERROR - Copied PDF file was deleted after saving to CoreData: \(copiedPDFURL.path)")
                        }
                    } else {
                        print("CreatePDFViewModel: ERROR - Copied PDF file does not exist: \(copiedPDFURL.path)")
                    }
                }
            } else if pdfService.isImageFile(fileExtension) {
                if let image = UIImage(contentsOfFile: fileURL.path),
                   let pdfURL = pdfService.createPDF(from: [image]) {
                    if FileManager.default.fileExists(atPath: pdfURL.path) {
                        print("CreatePDFViewModel: Created PDF from image file: \(pdfURL.lastPathComponent)")
                        createdPDFURLs.append(pdfURL)
                        savePDFToCoreData(pdfURL: pdfURL)
                        
                        if !FileManager.default.fileExists(atPath: pdfURL.path) {
                            print("CreatePDFViewModel: ERROR - PDF file was deleted after saving to CoreData: \(pdfURL.path)")
                        }
                    } else {
                        print("CreatePDFViewModel: ERROR - Created PDF file does not exist: \(pdfURL.path)")
                    }
                }
            }
        }
        
        isCreatingPDF = false
        
        if createdPDFURLs.isEmpty {
            errorMessage = "Не удалось создать PDF документы"
        } else {
            if createdPDFURLs.count == 1 {
                createdPDFURL = createdPDFURLs.first
            }
            NotificationCenter.default.post(name: NSNotification.Name("DocumentsListUpdated"), object: nil)
        }
    }
    
    private func copyPDFFile(_ sourceURL: URL) -> URL? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let randomSuffix = Int.random(in: 1000...9999)
        let fileName = "PDF_\(timestamp)_\(randomSuffix).pdf"
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Failed to copy PDF file: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func savePDFToCoreData(pdfURL: URL) {
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            print("CreatePDFViewModel: ERROR - Cannot save to CoreData, file does not exist: \(pdfURL.path)")
            return
        }
        
        let context = persistenceController.viewContext
        
        let thumbnailData = pdfService.generateThumbnail(from: pdfURL)
        
        let fileName = pdfURL.lastPathComponent
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        guard pdfURL.path.hasPrefix(documentsDirectory.path) else {
            print("CreatePDFViewModel: ERROR - File is not in Documents directory: \(pdfURL.path)")
            return
        }
        
        let document = DocumentEntity(context: context)
        document.id = UUID()
        document.name = fileName
        document.fileURL = fileName
        document.createdAt = Date()
        document.thumbnail = thumbnailData
        
        do {
            try context.save()
            print("CreatePDFViewModel: PDF saved to CoreData: \(fileName) (stored as relative path)")
            
            if !FileManager.default.fileExists(atPath: pdfURL.path) {
                print("CreatePDFViewModel: WARNING - File was deleted after saving to CoreData: \(pdfURL.path)")
            }
        } catch {
            print("CreatePDFViewModel: Failed to save PDF to CoreData: \(error.localizedDescription)")
        }
    }
    
    func clearSelection() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let context = persistenceController.viewContext
        
        let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        var savedFilePaths: Set<String> = []
        do {
            let savedDocuments = try context.fetch(fetchRequest)
            savedFilePaths = Set(savedDocuments.compactMap { $0.fileURL })
            print("CreatePDFViewModel: Found \(savedFilePaths.count) saved documents in CoreData")
        } catch {
            print("CreatePDFViewModel: Failed to fetch saved documents: \(error.localizedDescription)")
        }
        
        for url in selectedFileURLs {
            if url.path.hasPrefix(documentsDirectory.path) {
                let isCreatedPDF = createdPDFURLs.contains { $0.path == url.path }
                
                let fileName = url.lastPathComponent
                let isSavedInCoreData = savedFilePaths.contains(fileName)
                
                let isPDFFile = url.lastPathComponent.hasPrefix("PDF_") && url.pathExtension.lowercased() == "pdf"
                
                if !isCreatedPDF && !isSavedInCoreData && !isPDFFile {
                    print("CreatePDFViewModel: Deleting temporary file: \(url.lastPathComponent)")
                    try? FileManager.default.removeItem(at: url)
                } else {
                    print("CreatePDFViewModel: NOT deleting file (isCreatedPDF: \(isCreatedPDF), isSavedInCoreData: \(isSavedInCoreData), isPDFFile: \(isPDFFile)): \(url.lastPathComponent)")
                }
            }
        }
        
        selectedImages.removeAll()
        selectedFileURLs.removeAll()
        createdPDFURL = nil
        errorMessage = nil
    }
}

