import Foundation

struct DiaryStyle: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let basePrompt: String
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DiaryStyle, rhs: DiaryStyle) -> Bool {
        lhs.id == rhs.id
    }
    
    static let allStyles: [DiaryStyle] = [
        DiaryStyle(
            id: "realistic",
            name: "纪实风格",
            description: "记录真实生活，注重细节描写",
            basePrompt: "请以纪实的方式描述这一天发生的事情，注重细节和真实感，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "delicate",
            name: "细腻风格",
            description: "关注内心感受，描写细腻入微",
            basePrompt: "请以细腻的笔触描写这一天的感受和体验，注重情感的微妙变化，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "philosophical",
            name: "哲理风格",
            description: "探讨人生哲理，寻找深层意义",
            basePrompt: "请从哲理的角度思考这一天的经历，探讨其中的深层含义，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "lyrical",
            name: "抒情风格",
            description: "抒发内心情感，富有诗意",
            basePrompt: "请以抒情的方式表达这一天的心情和感受，语言要富有诗意，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "humorous",
            name: "幽默风格",
            description: "用轻松诙谐的方式记录生活",
            basePrompt: "请用幽默诙谐的方式记录这一天的趣事，保持轻松愉快的语调，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "profound",
            name: "深刻风格",
            description: "深入思考，探讨深层议题",
            basePrompt: "请深入思考这一天的经历，探讨其中的深层含义，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "dreamy",
            name: "梦幻风格",
            description: "充满想象力和诗意的描写",
            basePrompt: "请以梦幻的笔触描绘这一天的经历，充满想象力和诗意，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "inspirational",
            name: "励志风格",
            description: "积极向上，充满正能量",
            basePrompt: "请以积极向上的方式记录这一天，寻找其中的励志元素，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "narrative",
            name: "叙事风格",
            description: "以故事的方式记录生活",
            basePrompt: "请以讲故事的方式记录这一天的经历，注重情节的展开，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "satirical",
            name: "讽刺风格",
            description: "用智慧幽默的方式表达观点",
            basePrompt: "请用巧妙的讽刺手法记录这一天的见闻和感受，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "lonely",
            name: "孤独风格",
            description: "表达内心的孤独与思考",
            basePrompt: "请从孤独者的视角记录这一天的感受和思考，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "nostalgic",
            name: "怀旧风格",
            description: "充满回忆和怀念的笔触",
            basePrompt: "请以怀旧的笔触记录这一天，将当下与过往联系起来，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "reflective",
            name: "感悟风格",
            description: "记录生活感悟和心得",
            basePrompt: "请记录这一天的感悟和心得，分享你的思考，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "dialogue",
            name: "对话风格",
            description: "通过对话展现内心世界",
            basePrompt: "请通过对话的形式记录这一天的经历和感受，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "fantasy",
            name: "幻想风格",
            description: "充满想象力和创意",
            basePrompt: "请发挥想象力，以创意的方式记录这一天，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "melancholy",
            name: "伤感风格",
            description: "抒发伤感情怀",
            basePrompt: "请以伤感的笔触记录这一天的情感体验，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "warm",
            name: "温馨风格",
            description: "记录温暖治愈的时刻",
            basePrompt: "请记录这一天温暖治愈的时刻，传递温馨的感受，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "experimental",
            name: "实验风格",
            description: "尝试新颖独特的表达方式",
            basePrompt: "请用独特新颖的方式记录这一天，尝试不同的表达形式，但控制在200字以内。"
        ),
        DiaryStyle(
            id: "critical",
            name: "批判风格",
            description: "理性思考，批判性观察",
            basePrompt: "请以批判性思维记录这一天的观察和思考，但控制在200字以内。"
        )
    ]
}

struct StyleCombination: Codable {
    var styles: [DiaryStyle]
    var customPrompt: String
    
    var finalPrompt: String {
        if !customPrompt.isEmpty {
            return customPrompt
        }
        
        let styleDescriptions = styles.map { style in
            "\(style.name)"
        }.joined(separator: "和")
        
        return """
        你是一个日记写作助手。请用\(styleDescriptions)的风格写一篇简单完整的日记。

        限制：
        1. 回复必须在100个token以内（约200个汉字）
        2. 必须是一段完整的内容
        """
    }
} 