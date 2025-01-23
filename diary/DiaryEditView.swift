import SwiftUI
import PhotosUI
import UIKit
import Vision
import Speech

struct MoodOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: Int
    let color: Color
}

extension UIImage {
    func compressedImage(targetSize: CGSize = CGSize(width: 800, height: 800)) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
}

enum ImagePickerType {
    case camera
    case photoLibrary
    case none
}

struct DiaryEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    let date: Date
    let existingEntry: DiaryEntry?
    
    @State private var content: String = ""
    @State private var selectedImageData: Data?
    @State private var moodValue: Double = 3
    @State private var isGeneratingContent = false
    @State private var imageDescription: String = ""
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingImagePicker = false
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var showingTagInput = false
    @State private var isRecording = false
    @State private var showingRecordingAlert = false
    @State private var recordingPermissionDenied = false
    
    private let speechRecognizer = SpeechRecognizer()
    
    init(date: Date, existingEntry: DiaryEntry? = nil) {
        self.date = date
        self.existingEntry = existingEntry
        
        // Initialize state properties with existing entry data if available
        if let entry = existingEntry {
            _content = State(initialValue: entry.content ?? "")
            _selectedImageData = State(initialValue: entry.images)
            _moodValue = State(initialValue: Double(entry.mood))
            _tags = State(initialValue: entry.tags as? [String] ?? [])
        }
    }
    
    let moods: [MoodOption] = [
        MoodOption(icon: "cloud.rain", title: "Very Bad", value: 1, color: .red),
        MoodOption(icon: "cloud", title: "Bad", value: 2, color: .orange),
        MoodOption(icon: "cloud.sun", title: "Neutral", value: 3, color: .yellow),
        MoodOption(icon: "sun.max", title: "Good", value: 4, color: .green),
        MoodOption(icon: "sparkles", title: "Excellent", value: 5, color: .blue)
    ]
    
    var selectedMood: MoodOption {
        let index = Int(moodValue.rounded()) - 1
        return moods[max(0, min(index, moods.count - 1))]
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How are you feeling?")) {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: selectedMood.icon)
                                .font(.system(size: 30))
                                .foregroundColor(selectedMood.color)
                            Text(selectedMood.title)
                                .font(.headline)
                                .foregroundColor(selectedMood.color)
                        }
                        
                        Slider(value: $moodValue, in: 1...5, step: 1)
                            .accentColor(selectedMood.color)
                        
                        HStack {
                            ForEach(moods) { mood in
                                VStack {
                                    Image(systemName: mood.icon)
                                        .foregroundColor(moodValue.rounded() == Double(mood.value) ? mood.color : .gray)
                                    Text(mood.title)
                                        .font(.caption2)
                                        .foregroundColor(moodValue.rounded() == Double(mood.value) ? mood.color : .gray)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                Section(header: Text("Photos")) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        VStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                            Text("Gallery")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.vertical, 5)
                    
                    if let imageData = selectedImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }
                }
                
                Section(header: Text("Content")) {
                    if isGeneratingContent {
                        ProgressView("Generating content with AI...")
                    }
                    
                    HStack {
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                        
                        VStack {
                            Button(action: {
                                if isRecording {
                                    stopRecording()
                                } else {
                                    startRecording()
                                }
                            }) {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(isRecording ? .red : .blue)
                            }
                            if isRecording {
                                Text("录音中...")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section(header: Text("Tags")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                    Button(action: {
                                        tags.removeAll { $0 == tag }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                            }
                            
                            Button(action: {
                                showingTagInput = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section {
                    Button(action: generateContent) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate with AI")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .disabled(isGeneratingContent)
                }
                .listRowBackground(Color.blue)
                .foregroundColor(.white)
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDiary()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImageData, sourceType: .photoLibrary)
            }
            .alert("Add Tag", isPresented: $showingTagInput) {
                TextField("Tag", text: $newTag)
                Button("Cancel", role: .cancel) {
                    newTag = ""
                }
                Button("Add") {
                    if !newTag.isEmpty && !tags.contains(newTag) {
                        tags.append(newTag)
                        newTag = ""
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .alert("需要录音权限", isPresented: $showingRecordingAlert) {
                Button("取消", role: .cancel) { }
                Button("去设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("请在设置中允许应用访问麦克风，以使用语音输入功能。")
            }
        }
    }
    
    private func generateContent() {
        // 如果既没有文字也没有图片，就不生成内容
        if content.isEmpty && selectedImageData == nil {
            return
        }
        
        isGeneratingContent = true
        
        Task {
            do {
                var imageDescription: String? = nil
                if let imageData = selectedImageData,
                   let image = UIImage(data: imageData) {
                    imageDescription = try await analyzeImage(image)
                }
                
                let generatedContent = try await OpenAIService.shared.generateDiaryContent(
                    summary: content,
                    imageDescription: imageDescription,
                    mood: Int(moodValue.rounded())
                )
                
                await MainActor.run {
                    content = generatedContent
                    isGeneratingContent = false
                }
                
                // 生成标签
                let tags = try await OpenAIService.shared.generateTags(content: generatedContent)
                await MainActor.run {
                    self.tags = tags
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isGeneratingContent = false
                }
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Failed to analyze image: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            imageDescription = recognizedText.isEmpty ? "这张图片没有文字内容" : recognizedText
        }
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform image analysis: \(error.localizedDescription)")
        }
        
        return imageDescription
    }
    
    private func saveDiary() {
        if let existingEntry = existingEntry {
            // Update existing entry
            existingEntry.content = content
            existingEntry.images = selectedImageData
            existingEntry.mood = Int16(moodValue)
            existingEntry.moodEmoji = selectedMood.icon
            existingEntry.tags = tags
        } else {
            // Create new entry
            let newEntry = DiaryEntry(context: viewContext)
            newEntry.id = UUID()
            newEntry.content = content
            newEntry.date = date
            newEntry.images = selectedImageData
            newEntry.mood = Int16(moodValue)
            newEntry.moodEmoji = selectedMood.icon
            newEntry.tags = tags
        }
        
        do {
            try viewContext.save()
            viewContext.refreshAllObjects()
            NotificationCenter.default.post(name: NSNotification.Name("DiaryEntryDidChange"), object: nil)
            dismiss()
        } catch {
            print("Error saving diary entry: \(error)")
        }
    }
    
    private func startRecording() {
        speechRecognizer.checkPermission { authorized in
            if authorized {
                speechRecognizer.startRecording { result in
                    switch result {
                    case .success(let text):
                        content += text + " "
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                    isRecording = false
                }
                isRecording = true
            } else {
                showingRecordingAlert = true
            }
        }
    }
    
    private func stopRecording() {
        speechRecognizer.stopRecording()
        isRecording = false
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: Data?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                let compressedImage = image.compressedImage()
                parent.image = compressedImage.jpegData(compressionQuality: 0.8)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct DiaryEditView_Previews: PreviewProvider {
    static var previews: some View {
        DiaryEditView(date: Date())
    }
} 