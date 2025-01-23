import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "DiaryEntry")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Failed to load CoreData: \(error.localizedDescription)")
            }
        }
    }
    
    func addDiaryEntry(
        title: String,
        content: String,
        date: Date,
        imageData: Data?,
        mood: Int16,
        moodEmoji: String,
        tags: [String]
    ) {
        let entry = DiaryEntry(context: container.viewContext)
        entry.id = UUID()
        entry.title = title
        entry.content = content
        entry.date = date
        entry.images = imageData
        entry.mood = mood
        entry.moodEmoji = moodEmoji
        entry.tags = tags
        
        do {
            try container.viewContext.save()
        } catch {
            print("Error saving diary entry: \(error)")
        }
    }
    
    func updateEntry(_ entry: DiaryEntry, with newEntry: DiaryEntry) {
        entry.content = newEntry.content
        entry.images = newEntry.images
        entry.mood = newEntry.mood
        entry.moodEmoji = newEntry.moodEmoji
        entry.tags = newEntry.tags
        
        do {
            try container.viewContext.save()
        } catch {
            print("Error updating diary entry: \(error)")
        }
    }
    
    func deleteEntry(_ entry: DiaryEntry) {
        container.viewContext.delete(entry)
        
        do {
            try container.viewContext.save()
        } catch {
            print("Error deleting diary entry: \(error)")
        }
    }
    
    func fetchEntriesForMonth(date: Date) -> [DiaryEntry] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.date, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch entries: \(error.localizedDescription)")
            return []
        }
    }
    
    func getEntryForDate(_ date: Date) -> DiaryEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let entries = try container.viewContext.fetch(request)
            return entries.first
        } catch {
            print("Failed to fetch entry: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getAverageMoodForMonth(date: Date) -> Double {
        let entries = fetchEntriesForMonth(date: date)
        let totalMood = entries.reduce(0) { $0 + Int($1.mood) }
        return entries.isEmpty ? 0 : Double(totalMood) / Double(entries.count)
    }
} 