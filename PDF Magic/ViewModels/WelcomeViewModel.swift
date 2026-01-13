
import Foundation
import SwiftUI

class WelcomeViewModel: ObservableObject {
    @Published var shouldNavigateToDocuments = false
    
    func startButtonTapped() {
        shouldNavigateToDocuments = true
    }
}



