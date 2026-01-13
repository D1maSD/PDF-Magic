
import Foundation
import PDFKit
import UIKit

class PDFService {
    static let shared = PDFService()
    
    private init() {}
    
    
    func createPDF(from images: [UIImage]) -> URL? {
        guard !images.isEmpty else { return nil }
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let data = pdfRenderer.pdfData { context in
            for image in images {
                context.beginPage()
                
                let imageRect = calculateImageRect(for: image, in: context.pdfContextBounds)
                image.draw(in: imageRect)
            }
        }
        
        return savePDF(data: data, filename: generateFilename())
    }
    
    
    func createPDF(from fileURLs: [URL]) -> URL? {
        guard !fileURLs.isEmpty else {
            print("PDFService: createPDF(from fileURLs:) - fileURLs is empty")
            return nil
        }
        
        let pdfDocument = PDFDocument()
        var pageIndex = 0
        
        for fileURL in fileURLs {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("PDFService: File does not exist: \(fileURL.path)")
                continue
            }
            
            let fileExtension = fileURL.pathExtension.lowercased()
            
            if fileExtension == "pdf" {
                if let sourcePDF = PDFDocument(url: fileURL) {
                    print("PDFService: Loading PDF from \(fileURL.lastPathComponent), pages: \(sourcePDF.pageCount)")
                    for i in 0..<sourcePDF.pageCount {
                        if let page = sourcePDF.page(at: i) {
                            pdfDocument.insert(page, at: pageIndex)
                            pageIndex += 1
                        }
                    }
                } else {
                    print("PDFService: Failed to load PDF document from URL: \(fileURL.lastPathComponent)")
                }
            } else if isImageFile(fileExtension) {
                if let image = UIImage(contentsOfFile: fileURL.path) {
                    if let page = createPDFPage(from: image) {
                        pdfDocument.insert(page, at: pageIndex)
                        pageIndex += 1
                        print("PDFService: Added image page from \(fileURL.lastPathComponent)")
                    } else {
                        print("PDFService: Failed to create PDF page from image: \(fileURL.lastPathComponent)")
                    }
                } else {
                    print("PDFService: Failed to load image from file: \(fileURL.lastPathComponent)")
                }
            } else {
                print("PDFService: Unsupported file type: \(fileURL.lastPathComponent)")
            }
        }
        
        guard pageIndex > 0 else {
            print("PDFService: No pages were added to the PDF document")
            return nil
        }
        
        let outputURL = getDocumentsDirectory().appendingPathComponent(generateFilename())
        print("PDFService: Writing PDF document with \(pageIndex) pages to: \(outputURL.lastPathComponent)")
        
        if pdfDocument.write(to: outputURL) {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                print("PDFService: PDF document written successfully to: \(outputURL.path)")
                return outputURL
            } else {
                print("PDFService: PDF document write reported success but file does not exist at: \(outputURL.path)")
                return nil
            }
        } else {
            print("PDFService: Failed to write PDF document to: \(outputURL.path)")
            return nil
        }
    }
    
    
    func generateThumbnail(from pdfURL: URL, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }
        
        let pageRect = firstPage.bounds(for: .mediaBox)
        
        let widthScale = size.width / pageRect.width
        let heightScale = size.height / pageRect.height
        let scale = min(widthScale, heightScale)
        
        let scaledWidth = pageRect.width * scale
        let scaledHeight = pageRect.height * scale
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            cgContext.setFillColor(UIColor.systemGray6.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            cgContext.saveGState()
            
            let xOffset = (size.width - scaledWidth) / 2
            let yOffset = (size.height - scaledHeight) / 2
            
            cgContext.translateBy(x: xOffset, y: yOffset)
            
            cgContext.scaleBy(x: scale, y: scale)
            
            cgContext.translateBy(x: 0, y: pageRect.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)
            
            firstPage.draw(with: .mediaBox, to: cgContext)
            
            cgContext.restoreGState()
        }
        
        return image.pngData()
    }
    
    
    func deletePage(at index: Int, from pdfURL: URL) -> Bool {
        guard let pdfDocument = PDFDocument(url: pdfURL),
              index >= 0,
              index < pdfDocument.pageCount else {
            return false
        }
        
        pdfDocument.removePage(at: index)
        
        return pdfDocument.write(to: pdfURL)
    }
    
    
    func mergePDFs(firstPDFURL: URL, secondPDFURL: URL) -> URL? {
        guard FileManager.default.fileExists(atPath: firstPDFURL.path) else {
            print("First PDF file does not exist: \(firstPDFURL.path)")
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: secondPDFURL.path) else {
            print("Second PDF file does not exist: \(secondPDFURL.path)")
            return nil
        }
        
        guard let firstPDF = PDFDocument(url: firstPDFURL) else {
            print("Failed to load first PDF from: \(firstPDFURL.path)")
            return nil
        }
        
        guard let secondPDF = PDFDocument(url: secondPDFURL) else {
            print("Failed to load second PDF from: \(secondPDFURL.path)")
            return nil
        }
        
        guard firstPDF.pageCount > 0 else {
            print("First PDF has no pages")
            return nil
        }
        
        guard secondPDF.pageCount > 0 else {
            print("Second PDF has no pages")
            return nil
        }
        
        let mergedPDF = PDFDocument()
        var pageIndex = 0
        
        for i in 0..<firstPDF.pageCount {
            if let page = firstPDF.page(at: i) {
                mergedPDF.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }
        
        for i in 0..<secondPDF.pageCount {
            if let page = secondPDF.page(at: i) {
                mergedPDF.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }
        
        guard pageIndex > 0 else {
            print("No pages were added to merged PDF")
            return nil
        }
        
        let outputURL = getDocumentsDirectory().appendingPathComponent(generateFilename())
        
        guard mergedPDF.write(to: outputURL) else {
            print("Failed to write merged PDF to: \(outputURL.path)")
            return nil
        }
        
        return outputURL
    }
    
    
    private func calculateImageRect(for image: UIImage, in bounds: CGRect) -> CGRect {
        let imageAspectRatio = image.size.width / image.size.height
        let boundsAspectRatio = bounds.width / bounds.height
        
        var imageRect: CGRect
        
        if imageAspectRatio > boundsAspectRatio {
            let width = bounds.width
            let height = width / imageAspectRatio
            let x: CGFloat = 0
            let y = (bounds.height - height) / 2
            imageRect = CGRect(x: x, y: y, width: width, height: height)
        } else {
            let height = bounds.height
            let width = height * imageAspectRatio
            let x = (bounds.width - width) / 2
            let y: CGFloat = 0
            imageRect = CGRect(x: x, y: y, width: width, height: height)
        }
        
        return imageRect
    }
    
    private func createPDFPage(from image: UIImage) -> PDFPage? {
        let pageSize = CGSize(width: 612, height: 792)
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            let imageRect = calculateImageRect(for: image, in: CGRect(origin: .zero, size: pageSize))
            image.draw(in: imageRect)
        }
        
        guard let tempDoc = PDFDocument(data: pdfData),
              let tempPage = tempDoc.page(at: 0) else {
            return nil
        }
        
        return tempPage
    }
    
    func isImageFile(_ fileExtension: String) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        return imageExtensions.contains(fileExtension)
    }
    
    private func savePDF(data: Data, filename: String) -> URL? {
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let randomSuffix = Int.random(in: 1000...9999)
        return "PDF_\(timestamp)_\(randomSuffix).pdf"
    }
}

