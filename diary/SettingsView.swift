import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasSelectedStyle") private var hasSelectedStyle = false
    @State private var showingExportSheet = false
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var exportURL: URL?
    @State private var exportType: ExportType = .pdf
    @State private var isProcessing = false
    
    enum ExportType {
        case pdf
        case text
    }
    
    var body: some View {
        List {
            Section(header: Text("写作风格")) {
                NavigationLink(destination: StyleSelectionView()) {
                    HStack {
                        Image(systemName: "pencil.and.outline")
                            .foregroundColor(.blue)
                        Text("修改写作风格")
                    }
                }
            }
            
            Section(header: Text("提示词设置")) {
                NavigationLink(destination: PromptEditorView()) {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(.blue)
                        Text("自定义提示词")
                    }
                }
            }
            
            Section(header: Text("数据管理")) {
                NavigationLink(destination: StatisticsView().environment(\.managedObjectContext, viewContext)) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        Text("统计分析")
                    }
                }
                
                Button(action: {
                    exportType = .pdf
                    exportData()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.blue)
                        Text("导出为PDF")
                    }
                }
                
                Button(action: {
                    exportType = .text
                    exportData()
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("导出为文本")
                    }
                }
                
                Button(action: createBackup) {
                    HStack {
                        Image(systemName: "arrow.clockwise.icloud")
                            .foregroundColor(.blue)
                        Text("创建备份")
                    }
                }
                
                Button(action: { showingDocumentPicker = true }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.icloud")
                            .foregroundColor(.blue)
                        Text("从备份恢复")
                    }
                }
            }
            
            Section(header: Text("关于")) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                restoreFromBackup(url: url)
            case .failure(let error):
                alertTitle = "错误"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        .overlay(
            Group {
                if isProcessing {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView("处理中...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .foregroundColor(.white)
                        )
                }
            }
        )
    }
    
    private func createBackup() {
        isProcessing = true
        
        Task {
            do {
                let url = try await DataManager.shared.createBackup()
                await MainActor.run {
                    exportURL = url
                    exportType = .text
                    showingExportSheet = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertTitle = "备份失败"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func restoreFromBackup(url: URL) {
        isProcessing = true
        
        Task {
            do {
                try await DataManager.shared.restoreFromBackup(url: url)
                await MainActor.run {
                    alertTitle = "恢复成功"
                    alertMessage = "日记数据已成功恢复"
                    showingAlert = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertTitle = "恢复失败"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func exportData() {
        isProcessing = true
        
        Task {
            do {
                let fetchRequest = DiaryEntry.fetchRequest()
                let entries = try viewContext.fetch(fetchRequest)
                
                let url: URL
                switch exportType {
                case .pdf:
                    url = try await DataManager.shared.exportAsPDF(entries: entries)
                case .text:
                    url = try await DataManager.shared.exportAsText(entries: entries)
                }
                
                await MainActor.run {
                    exportURL = url
                    showingExportSheet = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertTitle = "导出失败"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isProcessing = false
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 