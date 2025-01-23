import SwiftUI

struct StyleSelectionView: View {
    let onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyles: Set<DiaryStyle> = []
    @State private var showingPromptEditor = false
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    
    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Instructions
            Text("请选择2-3种写作风格")
                .font(.headline)
                .padding(.top)
            
            // Style Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(DiaryStyle.allStyles) { style in
                        StyleCard(
                            style: style,
                            isSelected: selectedStyles.contains(style),
                            onTap: {
                                toggleStyle(style)
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Next Button
            Button(action: {
                if selectedStyles.count < 2 {
                    alertMessage = "请至少选择2种风格"
                    isShowingAlert = true
                } else if selectedStyles.count > 3 {
                    alertMessage = "最多只能选择3种风格"
                    isShowingAlert = true
                } else {
                    // Save the style combination with default prompt
                    let combination = StyleCombination(
                        styles: Array(selectedStyles),
                        customPrompt: ""
                    )
                    UserDefaults.standard.setCodable(combination, forKey: "selectedStyleCombination")
                    onComplete?()
                    dismiss()
                }
            }) {
                Text("保存")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("选择写作风格")
        .navigationBarTitleDisplayMode(.inline)
        .alert("提示", isPresented: $isShowingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func toggleStyle(_ style: DiaryStyle) {
        if selectedStyles.contains(style) {
            selectedStyles.remove(style)
        } else if selectedStyles.count < 3 {
            selectedStyles.insert(style)
        } else {
            alertMessage = "最多只能选择3种风格"
            isShowingAlert = true
        }
    }
}

struct StyleCard: View {
    let style: DiaryStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(style.name)
                    .font(.headline)
                Text(style.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 