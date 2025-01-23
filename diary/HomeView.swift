import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingNewEntry = false
    @State private var selectedEntry: DiaryEntry?
    @State private var showingDetail = false
    @State private var refreshID = UUID()
    @State private var showingSettings = false
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = .current
        return calendar
    }
    
    private var dateRange: (start: Date, end: Date) {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return (startOfDay, endOfDay)
    }
    
    @FetchRequest private var currentDayEntry: FetchedResults<DiaryEntry>
    
    init() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        _currentDayEntry = FetchRequest(
            entity: DiaryEntry.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        )
    }
    
    private var currentEntry: DiaryEntry? {
        currentDayEntry.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Text("Diary")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Button(action: {
                            showingNewEntry = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    VStack(spacing: 0) {
                        CalendarView(selectedDate: $selectedDate)
                            .onChange(of: selectedDate) { newDate in
                                updateCurrentDayPredicate()
                            }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        if let entry = currentEntry {
                            EntryPreview(entry: entry)
                                .onTapGesture {
                                    viewContext.refresh(entry, mergeChanges: true)
                                    if entry.managedObjectContext != nil {
                                        selectedEntry = entry
                                        showingDetail = true
                                    }
                                }
                                .background(Color(.secondarySystemBackground))
                        } else {
                            EntryPreview(entry: nil)
                                .onTapGesture {
                                    showingNewEntry = true
                                }
                                .background(Color(.secondarySystemBackground))
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .id(refreshID)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewEntry, onDismiss: {
                refreshView()
                if let entry = currentEntry {
                    viewContext.refresh(entry, mergeChanges: true)
                    selectedEntry = entry
                    showingDetail = true
                }
            }) {
                DiaryEditView(date: selectedDate)
            }
            .sheet(isPresented: $showingDetail, onDismiss: {
                refreshView()
            }) {
                if let entry = selectedEntry,
                   entry.managedObjectContext != nil {
                    NavigationView {
                        DiaryDetailView(entry: entry)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    SettingsView()
                }
            }
        }
        .onAppear {
            updateCurrentDayPredicate()
            setupNotificationObserver()
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DiaryEntryDidChange"),
            object: nil,
            queue: .main
        ) { _ in
            refreshView()
            if let entry = currentEntry {
                viewContext.refresh(entry, mergeChanges: true)
                selectedEntry = entry
            }
        }
    }
    
    private func refreshView() {
        viewContext.refreshAllObjects()
        updateCurrentDayPredicate()
        refreshID = UUID()
    }
    
    private func updateCurrentDayPredicate() {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        currentDayEntry.nsPredicate = NSPredicate(format: "date >= %@ AND date < %@", 
            startOfDay as NSDate, 
            endOfDay as NSDate
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 