
import SwiftUI
import UIKit

struct NavigationBarBlurModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NavigationBarBlurView())
    }
}

struct NavigationBarBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            setupNavigationBarAppearance()
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            setupNavigationBarAppearance()
        }
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let navController = findNavigationController(in: window.rootViewController) {
            navController.navigationBar.standardAppearance = appearance
            navController.navigationBar.scrollEdgeAppearance = appearance
            navController.navigationBar.compactAppearance = appearance
        }
    }
    
    private func findNavigationController(in viewController: UIViewController?) -> UINavigationController? {
        if let navController = viewController as? UINavigationController {
            return navController
        }
        if let presented = viewController?.presentedViewController {
            if let navController = presented as? UINavigationController {
                return navController
            }
        }
        if let tabBarController = viewController as? UITabBarController {
            if let selected = tabBarController.selectedViewController {
                if let navController = selected as? UINavigationController {
                    return navController
                }
            }
        }
        for child in viewController?.children ?? [] {
            if let navController = findNavigationController(in: child) {
                return navController
            }
        }
        return nil
    }
}

extension View {
    func navigationBarBlur() -> some View {
        modifier(NavigationBarBlurModifier())
    }
}

