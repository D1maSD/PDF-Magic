
import SwiftUI
import PDFKit
import QuartzCore

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        loadPDF(into: pdfView, url: url)
        
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let page = pdfView.currentPage,
               let document = pdfView.document {
                let index = document.index(for: page)
                NotificationCenter.default.post(
                    name: NSNotification.Name("PDFPageChanged"),
                    object: nil,
                    userInfo: ["pageIndex": index, "totalPages": document.pageCount]
                )
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PDFReloadRequired"),
            object: nil,
            queue: .main
        ) { _ in
            loadPDF(into: pdfView, url: url)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PDFRotatePage"),
            object: nil,
            queue: .main
        ) { notification in
            let now = Date()
            guard let pageIndex = notification.userInfo?["pageIndex"] as? Int else {
                return
            }
            let key = "\(url.path)_\(pageIndex)"
            
            if let lastTime = PDFKitView.lastRotationTimes[key],
               now.timeIntervalSince(lastTime) < 0.5 {
                print("PDFKitView: Rotation ignored - too soon after last rotation")
                return
            }
            
            PDFKitView.lastRotationTimes[key] = now
            
            guard let document = pdfView.document,
                  pageIndex >= 0,
                  pageIndex < document.pageCount,
                  let page = document.page(at: pageIndex) else {
                return
            }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            CATransaction.setAnimationDuration(0)
            
            pdfView.layer.removeAllAnimations()
            
            let currentRotation = page.rotation
            let newRotation = (currentRotation + 90) % 360
            
            page.rotation = newRotation
            
            pdfView.setNeedsDisplay()
            pdfView.layoutIfNeeded()
            
            CATransaction.flush()
            
            CATransaction.commit()
            
            print("PDFKitView: Rotated page \(pageIndex) from \(currentRotation)° to \(newRotation)°")
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
    }
    
    private static var lastRotationTimes: [String: Date] = [:]
    
    private func loadPDF(into pdfView: PDFView, url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("PDFKitView: File does not exist at path: \(url.path)")
            pdfView.document = nil 
            return
        }
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        } else {
            print("PDFKitView: Failed to load PDF document from URL: \(url)")
            pdfView.document = nil 
        }
    }
}


