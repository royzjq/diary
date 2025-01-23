import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    private var apiKey: String = "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"
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func generateDiaryContent(summary: String, imageDescription: String?, mood: Int) async throws -> String {
        // 获取保存的写作风格组合
        guard let styleCombination = UserDefaults.standard.getCodable(StyleCombination.self, forKey: "selectedStyleCombination") else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No writing style selected"])
        }
        
        let moodDescription = getMoodDescription(mood)
        
        // 使用自定义提示词或默认提示词
        let systemPrompt = UserDefaults.standard.string(forKey: "customPrompt") ?? styleCombination.finalPrompt
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": """
                心情：\(moodDescription)
                内容：\(summary)
                \(imageDescription.map { "照片：\($0)" } ?? "")
                """]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 400
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to get response from OpenAI"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "OpenAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
        }
        
        return content
    }
    
    func setApiKey(_ key: String) {
        apiKey = key
    }
    
    func generateTags(content: String) async throws -> [String] {
        let prompt = """
        根据以下日记内容，生成3-5个相关的标签。
        每个标签应该是一个单词或短语，用来概括日记中提到的主要主题、情感或活动。
        只返回标签，用逗号分隔。标签必须是中文。

        内容：\(content)
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": "你是一个帮助用户生成日记标签的AI助手。你只需要返回中文标签，用逗号分隔。"],
            ["role": "user", "content": prompt]
        ]
        
        let parameters: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 100
        ]
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get response from OpenAI"])
        }
        
        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let tags = result.choices.first?.message.content ?? ""
        
        return tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    }
    
    func generatePromptForStyles(_ styles: [DiaryStyle]) async throws -> String {
        let systemPrompt = """
        你是一个专业的写作指导专家。你需要为用户生成一个写作提示语，这个提示语将用于AI生成日记内容。
        要求：
        1. 提示语要融合用户选择的所有写作风格的特点
        2. 提示语要专业、具体，包含具体的写作技巧和要求
        3. 提示语的长度要适中，不要太长
        4. 提示语本身要优雅、专业
        5. 确保生成的内容符合日记的私密性和真实性
        6. 字数一定要在200字以内
        """
        
        let styleDescriptions = styles.map { "【\($0.name)】\($0.description)" }.joined(separator: "\n")
        let userPrompt = """
        请为以下写作风格组合生成一个专业的写作提示语：
        \(styleDescriptions)
        
        记住：
        1. 提示语要自然地融合这些风格的特点
        2. 要包含具体的写作技巧和建议
        3. 必须强调内容限制在200字以内
        4. 提示语要简洁但专业
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to get response from OpenAI"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "OpenAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
        }
        
        return content
    }
    
    private func getMoodDescription(_ mood: Int) -> String {
        switch mood {
        case 1: return "心情很差"
        case 2: return "心情不太好"
        case 3: return "心情一般"
        case 4: return "心情不错"
        case 5: return "心情非常好"
        default: return "心情一般"
        }
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
} 