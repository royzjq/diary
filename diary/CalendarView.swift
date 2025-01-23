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
                .disabled(isAnimating)
                
                Spacer()
                
                ZStack {
                    Text(monthYearString(from: currentMonth))
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .offset(x: monthOffset)
                        .clipped()
                }
                .frame(height: 30)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
                .disabled(isAnimating)
            }
            .padding(.horizontal)
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption.bold())
                        .foregroundColor(day == "Sun" || day == "Sat" ? .blue : .gray)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, selectedDate: $selectedDate)
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
    
    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        let remainingDays = 42 - days.count // 6 rows * 7 days
        days.append(contentsOf: Array(repeating: nil, count: remainingDays))
        
        return days
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.3)) {
            monthOffset = 100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
                currentMonth = newDate
                monthOffset = -100
                withAnimation(.easeInOut(duration: 0.3)) {
                    monthOffset = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }
    }
    
    private func nextMonth() {
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.3)) {
            monthOffset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
                currentMonth = newDate
                monthOffset = 100
                withAnimation(.easeInOut(duration: 0.3)) {
                    monthOffset = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }
    }
}

struct DayCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    let date: Date
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    
    private var isWeekend: Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    var body: some View {
        let entry = CoreDataManager.shared.getEntryForDate(date)
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
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