import Foundation
import CoreData
import UIKit

class DataManager {
    static let shared = DataManager()
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Export Functions
    
    func exportAsPDF(entries: [DiaryEntry]) async throws -> URL {
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        for entry in entries {
            UIGraphicsBeginPDFPage()
            let context = UIGraphicsGetCurrentContext()!
            
            // 绘制背景
            let mood = Int(entry.mood)
            let backgroundColor = getMoodBackgroundColor(mood)
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
            
            // 绘制装饰性边框和背景
            let borderInset: CGFloat = 20
            let borderRect = CGRect(x: borderInset, y: borderInset,
                                  width: pageWidth - (borderInset * 2),
                                  height: pageHeight - (borderInset * 2))
            
            // 绘制内容区域背景
            context.setFillColor(UIColor.black.withAlphaComponent(0.05).cgColor)
            let path = UIBezierPath(roundedRect: borderRect, cornerRadius: 10)
            path.fill()
            
            // 绘制边框
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            context.setLineWidth(1.5)
            path.stroke()
            
            var yOffset: CGFloat = margin
            
            // 绘制日期
            let dateString = dateFormatter.string(from: entry.date ?? Date())
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "HiraMinProN-W6", size: 28) ?? .systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let dateSize = (dateString as NSString).size(withAttributes: dateAttributes)
            (dateString as NSString).draw(
                at: CGPoint(x: margin, y: yOffset),
                withAttributes: dateAttributes
            )
            
            yOffset += dateSize.height + 20
            
            // 绘制心情
            let moodString = "心情：" + getMoodDescription(mood)
            let moodAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "HiraMinProN-W3", size: 18) ?? .systemFont(ofSize: 18),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
            (moodString as NSString).draw(
                at: CGPoint(x: margin, y: yOffset),
                withAttributes: moodAttributes
            )
            
            yOffset += 40
            
            // 绘制图片（如果有）
            if let imageData = entry.images,
               let image = UIImage(data: imageData) {
                let maxImageHeight: CGFloat = 250
                let imageSize = image.size
                let aspectRatio = imageSize.width / imageSize.height
                let imageWidth = min(contentWidth, imageSize.width)
                let imageHeight = min(maxImageHeight, imageWidth / aspectRatio)
                let imageRect = CGRect(x: margin, y: yOffset,
                                     width: imageWidth, height: imageHeight)
                
                // 绘制图片背景和边框
                context.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
                let imagePath = UIBezierPath(roundedRect: imageRect, cornerRadius: 8)
                context.addPath(imagePath.cgPath)
                context.fillPath()
                
                // 绘制图片阴影
                context.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.2).cgColor)
                image.draw(in: imageRect)
                context.setShadow(offset: .zero, blur: 0, color: nil)
                
                yOffset += imageHeight + 40
            }
            
            // 绘制内容
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "HiraMinProN-W3", size: 16) ?? .systemFont(ofSize: 16),
                .foregroundColor: UIColor.white.withAlphaComponent(0.95),
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 10
                    style.paragraphSpacing = 15
                    style.alignment = .justified
                    return style
                }()
            ]
            
            let contentRect = CGRect(x: margin, y: yOffset,
                                   width: contentWidth,
                                   height: pageHeight - yOffset - margin - 40)
            (entry.content ?? "").draw(
                with: contentRect,
                options: .usesLineFragmentOrigin,
                attributes: contentAttributes,
                context: nil
            )
            
            // 绘制标签
            if !entry.tags.isEmpty {
                let tagsString = "标签：" + entry.tags.joined(separator: "、")
                let tagsAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "HiraMinProN-W3", size: 14) ?? .systemFont(ofSize: 14),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.8)
                ]
                let tagsRect = CGRect(x: margin, y: pageHeight - margin - 30,
                                    width: contentWidth, height: 20)
                (tagsString as NSString).draw(
                    with: tagsRect,
                    options: .usesLineFragmentOrigin,
                    attributes: tagsAttributes,
                    context: nil
                )
            }
        }
        
        UIGraphicsEndPDFContext()
        
        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "diary_export_\(Date().timeIntervalSince1970).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try pdfData.write(to: fileURL, options: .atomic)
        return fileURL
    }
    
    func exportAsText(entries: [DiaryEntry]) async throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var text = ""
        
        for entry in entries {
            let dateString = formatter.string(from: entry.date ?? Date())
            text += """
            ==================
            日期：\(dateString)
            心情：\(getMoodDescription(Int(entry.mood)))
            
            \(entry.content ?? "")
            
            标签：\(entry.tags.joined(separator: ", "))
            ==================
            
            """
        }
        
        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "diary_export_\(Date().timeIntervalSince1970).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // MARK: - Backup Functions
    
    func createBackup() async throws -> URL {
        return try await MainActor.run {
            let context = persistenceController.container.viewContext
            let fetchRequest: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
            let entries = try context.fetch(fetchRequest)
            
            let dateFormatter = ISO8601DateFormatter()
            var backupData: [[String: Any]] = []
            
            for entry in entries {
                var entryData: [String: Any] = [
                    "date": entry.date.map { dateFormatter.string(from: $0) } as Any,
                    "content": entry.content as Any,
                    "mood": entry.mood,
                    "tags": entry.tags,
                    "moodEmoji": entry.moodEmoji as Any
                ]
                
                if let imageData = entry.images {
                    entryData["images"] = imageData.base64EncodedString()
                }
                
                backupData.append(entryData)
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
            
            // Save to Documents directory
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let fileName = "diary_backup_\(formatter.string(from: Date())).json"
            let fileURL = documentsDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL, options: .atomic)
            print("Backup created at: \(fileURL.path)")
            return fileURL
        }
    }
    
    func restoreFromBackup(url: URL) async throws {
        try await MainActor.run {
            let jsonData = try Data(contentsOf: url)
            let backupData = try JSONSerialization.jsonObject(with: jsonData) as! [[String: Any]]
            
            let context = persistenceController.container.viewContext
            let dateFormatter = ISO8601DateFormatter()
            
            // Delete all existing entries
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = DiaryEntry.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
            
            // Insert new entries
            for entryData in backupData {
                let entry = DiaryEntry(context: context)
                if let dateString = entryData["date"] as? String {
                    entry.date = dateFormatter.date(from: dateString)
                }
                entry.content = entryData["content"] as? String
                entry.mood = entryData["mood"] as? Int16 ?? 3
                entry.tags = entryData["tags"] as? [String] ?? []
                entry.moodEmoji = entryData["moodEmoji"] as? String
                
                if let base64String = entryData["images"] as? String {
                    entry.images = Data(base64Encoded: base64String)
                }
            }
            
            try context.save()
        }
    }
    
    // MARK: - Helper Functions
    
    private func getMoodBackgroundColor(_ mood: Int) -> UIColor {
        switch mood {
        case 1: return UIColor(red: 0.85, green: 0.3, blue: 0.3, alpha: 0.3)  // 很差 - 深红
        case 2: return UIColor(red: 0.85, green: 0.5, blue: 0.3, alpha: 0.3)  // 不好 - 橙红
        case 3: return UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.25)  // 一般 - 灰色
        case 4: return UIColor(red: 0.3, green: 0.7, blue: 0.85, alpha: 0.25) // 不错 - 蓝色
        case 5: return UIColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 0.25) // 很好 - 绿色
        default: return UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.25)
        }
    }
    
    private func getMoodDescription(_ mood: Int) -> String {
        switch mood {
        case 1: return "很差"
        case 2: return "不好"
        case 3: return "一般"
        case 4: return "不错"
        case 5: return "很好"
        default: return "一般"
        }
    }
} 