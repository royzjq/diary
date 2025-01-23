import SwiftUI

struct PromptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPrompt: String
    @State private var showingSaveAlert = false
    @State private var isGeneratingPrompt = false
    @State private var currentStyleCombination: StyleCombination?
    
    init() {
        // 获取当前的提示词和风格组合
        if let combination = UserDefaults.standard.getCodable(StyleCombination.self, forKey: "selectedStyleCombination") {
            _currentStyleCombination = State(initialValue: combination)
            _currentPrompt = State(initialValue: combination.finalPrompt)
        } else {
            _currentPrompt = State(initialValue: "你是一个专业的日记写作助手，请根据用户提供的内容，以温暖、真诚的语气写一篇200字以内的日记。注意要体现用户的情感和心理活动。")
        }
    }
    
    var body: some View {
        Form {
            if let styles = currentStyleCombination?.styles {
                Section(header: Text("当前写作风格").textCase(.none)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(styles) { style in
                                Text(style.name)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("提示词").textCase(.none)) {
                TextEditor(text: $currentPrompt)
                    .frame(minHeight: 150)
                
                Text("提示：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text("这里的提示词将用于指导 AI 如何生成日记内容。你可以描述你想要的写作风格、情感表达方式等。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("恢复默认提示词") {
                    if let combination = currentStyleCombination {
                        currentPrompt = combination.finalPrompt
                    } else {
                        currentPrompt = "你是一个专业的日记写作助手，请根据用户提供的内容，以温暖、真诚的语气写一篇200字以内的日记。注意要体现用户的情感和心理活动。"
                    }
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("提示词设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    savePrompt()
                }
            }
        }
        .alert("保存成功", isPresented: $showingSaveAlert) {
            Button("确定", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("提示词已更新")
        }
    }
    
    private func savePrompt() {
        if var combination = currentStyleCombination {
            combination.customPrompt = currentPrompt
            UserDefaults.standard.setCodable(combination, forKey: "selectedStyleCombination")
        }
        showingSaveAlert = true
    }
} 