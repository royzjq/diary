import Foundation
import CoreData

extension DiaryEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DiaryEntry> {
        return NSFetchRequest<DiaryEntry>(entityName: "DiaryEntry")
    }

    @NSManaged public var content: String?
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var images: Data?
    @NSManaged public var mood: Int16
    @NSManaged public var moodEmoji: String?
    @NSManaged public var title: String?
    @NSManaged private var tagsData: Data?
    
    public var tags: [String] {
        get {
            if let data = tagsData {
                return (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String]) ?? []
            }
            return []
        }
        set {
            tagsData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
        }
    }
} 