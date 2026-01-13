
import UIKit

struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

extension UIImage: @retroactive Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}


