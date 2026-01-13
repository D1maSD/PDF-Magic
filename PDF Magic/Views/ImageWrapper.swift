
import UIKit

struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

extension UIImage: Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}


