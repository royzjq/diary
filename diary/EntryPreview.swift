import SwiftUI

struct EntryPreview: View {
    let entry: DiaryEntry?
    
    var body: some View {
        VStack(spacing: 0) {
            if let entry = entry {
                VStack(alignment: .leading, spacing: 16) {
                    // Header: Date and Mood
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Image(systemName: entry.moodEmoji ?? "")
                                .foregroundColor(getMoodColor(mood: Int(entry.mood)))
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                                .background(getMoodColor(mood: Int(entry.mood)).opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(entry.date?.formatted(date: .long, time: .omitted) ?? "")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    // Content Preview
                    HStack(spacing: 16) {
                        if let imageData = entry.images,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.content ?? "")
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            if !entry.tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(entry.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.blue.opacity(0.1))
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    Text("No entry for this date")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Tap to create one")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .background(Color(.systemBackground))
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
} 