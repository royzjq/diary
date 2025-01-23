import SwiftUI
import Charts

enum TimeRange: String, CaseIterable {
    case week = "周"
    case month = "月"
    case year = "年"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: DiaryEntry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.date, ascending: true)]
    ) private var entries: FetchedResults<DiaryEntry>
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            TabView(selection: $selectedTab) {
                MoodTrendView(entries: Array(entries), timeRange: selectedTimeRange)
                    .tabItem {
                        Label("心情趋势", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(0)
                
                WritingFrequencyView(entries: Array(entries), timeRange: selectedTimeRange)
                    .tabItem {
                        Label("写作频率", systemImage: "calendar.badge.clock")
                    }
                    .tag(1)
                
                TagCloudView(entries: Array(entries))
                    .tabItem {
                        Label("标签统计", systemImage: "tag.circle")
                    }
                    .tag(2)
            }
        }
        .navigationTitle("统计分析")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MoodTrendView: View {
    let entries: [DiaryEntry]
    let timeRange: TimeRange
    
    private var filteredEntries: [DiaryEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        return entries.filter { entry in
            guard let date = entry.date else { return false }
            return date >= cutoffDate
        }
    }
    
    private var moodData: [(date: Date, mood: Double)] {
        let sorted = filteredEntries.compactMap { entry -> (Date, Double)? in
            guard let date = entry.date else { return nil }
            return (date, Double(entry.mood))
        }.sorted { $0.0 < $1.0 }
        return sorted
    }
    
    var body: some View {
        VStack {
            if moodData.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.gray)
            } else {
                Chart {
                    ForEach(moodData, id: \.date) { item in
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("心情", item.mood)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("日期", item.date),
                            y: .value("心情", item.mood)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisValueLabel {
                            Text(getMoodLabel(for: value.as(Int.self) ?? 3))
                        }
                    }
                }
                .frame(height: 300)
                .padding()
            }
        }
    }
    
    private func getMoodLabel(for value: Int) -> String {
        switch value {
        case 1: return "很差"
        case 2: return "较差"
        case 3: return "一般"
        case 4: return "不错"
        case 5: return "很好"
        default: return ""
        }
    }
}

struct WritingFrequencyView: View {
    let entries: [DiaryEntry]
    let timeRange: TimeRange
    
    private var frequencyData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        
        var frequencies: [Date: Int] = [:]
        let dateEntries = entries.compactMap { $0.date }
            .filter { $0 >= cutoffDate }
        
        // 创建所有日期的零值
        for dayOffset in 0...timeRange.days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let normalizedDate = calendar.startOfDay(for: date)
                frequencies[normalizedDate] = 0
            }
        }
        
        // 计算实际频率
        for date in dateEntries {
            let normalizedDate = calendar.startOfDay(for: date)
            frequencies[normalizedDate, default: 0] += 1
        }
        
        return frequencies.sorted { $0.key < $1.key }.map { (date: $0.key, count: $0.value) }
    }
    
    var body: some View {
        VStack {
            if frequencyData.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.gray)
            } else {
                Chart {
                    ForEach(frequencyData, id: \.date) { item in
                        BarMark(
                            x: .value("日期", item.date),
                            y: .value("数量", item.count)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 300)
                .padding()
            }
        }
    }
}

struct TagCloudView: View {
    let entries: [DiaryEntry]
    
    private var tagFrequencies: [(tag: String, count: Int)] {
        var frequencies: [String: Int] = [:]
        
        for entry in entries {
            for tag in entry.tags {
                frequencies[tag, default: 0] += 1
            }
        }
        
        return frequencies.sorted { $0.value > $1.value }.map { (tag: $0.key, count: $0.value) }
    }
    
    var body: some View {
        ScrollView {
            if tagFrequencies.isEmpty {
                Text("暂无标签数据")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(tagFrequencies, id: \.tag) { item in
                        Text(item.tag)
                            .font(.system(size: CGFloat(14 + min(item.count, 10))))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(15)
                    }
                }
                .padding()
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var width: CGFloat = 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > (proposal.width ?? .infinity) {
                currentX = 0
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            
            currentX += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            width = max(width, currentX)
            height = currentY + maxHeight
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
} 