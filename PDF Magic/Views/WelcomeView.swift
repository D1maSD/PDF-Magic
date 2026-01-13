
import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 40)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("PDF Magic")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    Text("Управляйте вашими PDF документами")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "photo.on.rectangle",
                            title: "Создание PDF",
                            description: "Создавайте PDF из фотографий и файлов"
                        )
                        
                        FeatureRow(
                            icon: "doc.on.doc",
                            title: "Объединение",
                            description: "Объединяйте несколько PDF в один документ"
                        )
                        
                        FeatureRow(
                            icon: "trash",
                            title: "Редактирование",
                            description: "Удаляйте ненужные страницы из PDF"
                        )
                        
                        FeatureRow(
                            icon: "square.and.arrow.up",
                            title: "Поделиться",
                            description: "Делитесь документами с другими приложениями"
                        )
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                NavigationLink(
                    destination: DocumentsListView(),
                    isActive: $viewModel.shouldNavigateToDocuments
                ) {
                    Text("Начать")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        WelcomeView()
    }
}

