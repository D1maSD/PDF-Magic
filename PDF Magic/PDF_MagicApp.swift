
import SwiftUI

@main
struct PDF_MagicApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WelcomeView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
