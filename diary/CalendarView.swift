import SwiftUI

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date
    @State private var currentMonth: Date
    @State private var monthOffset: CGFloat = 0
    @State private var isAnimating = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._currentMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month selector
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
                
                Spacer()
                
                Text(currentMonth.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
            }
            .padding(.horizontal)
            
            // Days of week header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            onDateSelected: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    private var days: [Date?] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        
        let firstWeekday = calendar.component(.weekday, from: start)
        let previousMonthDays = firstWeekday - 1
        
        let totalDays = range.count
        let totalCells = ((totalDays + previousMonthDays + 6) / 7) * 7
        
        var days: [Date?] = Array(repeating: nil, count: totalCells)
        
        for day in 0..<totalDays {
            if let date = calendar.date(byAdding: .day, value: day, to: start) {
                days[day + previousMonthDays] = date
            }
        }
        
        return days
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

struct DayCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    let date: Date
    let isSelected: Bool
    let onDateSelected: () -> Void
    
    private let calendar = Calendar.current
    
    private var isWeekend: Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        let entry = CoreDataManager.shared.getEntryForDate(date)
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                onDateSelected()
            }
        }) {
            VStack(spacing: 8) {
                // Date
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : (isWeekend ? .blue : .primary))
                    .frame(width: 32, height: 32)
                    .background(
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(Color.blue)
                            } else if isToday {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1)
                            }
                        }
                    )
                
                // Mood indicator
                if let entry = entry {
                    Image(systemName: entry.moodEmoji ?? "")
                        .foregroundColor(getMoodColor(mood: Int(entry.mood)))
                        .font(.system(size: 12))
                } else {
                    Color.clear
                        .frame(height: 12)
                }
            }
            .frame(height: 60)
        }
        .buttonStyle(PlainButtonStyle())
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