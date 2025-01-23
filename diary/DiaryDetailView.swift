import SwiftUI

struct DiaryDetailView: View {
    @ObservedObject var entry: DiaryEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingFullScreenImage = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date and Mood
                HStack {
                    Text(entry.date?.formatted(date: .long, time: .omitted) ?? "")
                        .font(.headline)
                    Spacer()
                    HStack {
                        Image(systemName: entry.moodEmoji ?? "")
                        Text(getMoodTitle(mood: Int(entry.mood)))
                    }
                    .foregroundColor(getMoodColor(mood: Int(entry.mood)))
                }
                
                // Image
                if let imageData = entry.images,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                        .onTapGesture {
                            showingFullScreenImage = true
                        }
                }
                
                // Content
                Text(entry.content ?? "")
                    .font(.body)
                
                // Tags
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(15)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { isEditing = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            DiaryEditView(date: entry.date ?? Date(), existingEntry: entry)
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive, action: deleteEntry)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let imageData = entry.images,
               let uiImage = UIImage(data: imageData) {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: { showingFullScreenImage = false }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DiaryEntryDidChange"))) { _ in
            viewContext.refresh(entry, mergeChanges: true)
        }
    }
    
    private func getMoodColor(mood: Int) -> Color {
        switch mood {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return .gray
        }
    }
    
    private func getMoodTitle(mood: Int) -> String {
        switch mood {
        case 1: return "Very Bad"
        case 2: return "Bad"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return "Unknown"
        }
    }
    
    private func deleteEntry() {
        viewContext.delete(entry)
        try? viewContext.save()
        dismiss()
    }
} 