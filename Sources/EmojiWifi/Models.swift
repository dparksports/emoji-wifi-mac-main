import Foundation
import AppKit
import CoreImage.CIFilterBuiltins
import CoreImage

// MARK: - Password Generator
class PasswordGenerator {
    static func generateWiFiPassword(length: Int = 62, includeUppercase: Bool = true, includeLowercase: Bool = true, includeNumbers: Bool = true, includeSpecialChars: Bool = true) -> String {
        var characters = ""
        if includeLowercase { characters += "abcdefghijklmnopqrstuvwxyz" }
        if includeUppercase { characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if includeNumbers { characters += "0123456789" }
        if includeSpecialChars { characters += "!@#$%^&*()_+-=[]{}|<>?" }
        guard !characters.isEmpty else { return "" }
        var password = ""
        for _ in 0..<length { password += String(characters.randomElement()!) }
        return password
    }
}

// MARK: - QR Code Generator
class QRCodeGenerator {
    static func generateWiFiQRCode(ssid: String, password: String) -> NSImage? {
        let wifiString = "WIFI:T:WPA;S:\(ssid);P:\(password);H:false;;"
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(wifiString.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: 300, height: 300))
    }
    
    static func parseWiFiQRCode(_ qrString: String) -> (ssid: String?, password: String?) {
        var ssid: String?
        var password: String?
        if let ssidRange = qrString.range(of: "S:") {
            let startIndex = ssidRange.upperBound
            if let endIndex = qrString.range(of: ";", range: startIndex..<qrString.endIndex) {
                ssid = String(qrString[startIndex..<endIndex.lowerBound])
            }
        }
        if let passwordRange = qrString.range(of: "P:") {
            let startIndex = passwordRange.upperBound
            if let endIndex = qrString.range(of: ";", range: startIndex..<qrString.endIndex) {
                password = String(qrString[startIndex..<endIndex.lowerBound])
            }
        }
        return (ssid, password)
    }
}

// MARK: - WiFi Joiner
class WiFiJoiner {
    static func joinWiFi(ssid: String, password: String, completion: @escaping (String) -> Void) {
        let interface: String = "en0"
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-setairportnetwork", interface, ssid, password]
        task.standardOutput = pipe
        task.standardError = pipe
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8), !output.isEmpty { print("Output: \(output)") }
                if task.terminationStatus == 0 {
                    DispatchQueue.main.async { completion("✅ Successfully joined network: \(ssid)!") }
                } else {
                    DispatchQueue.main.async { completion("❌ Failed to join network. Exit code: \(task.terminationStatus)") }
                }
            } catch {
                DispatchQueue.main.async { completion("⚠️ Error running networksetup: \(error)") }
            }
        }
    }
}

// MARK: - WiFi History
struct WiFiHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let wifiName: String
    let password: String
    let description: String
    let source: String
    let timestamp: Date
    
    init(id: UUID = UUID(), wifiName: String, password: String, description: String, source: String, timestamp: Date = Date()) {
        self.id = id; self.wifiName = wifiName; self.password = password
        self.description = description; self.source = source; self.timestamp = timestamp
    }
}

class HistoryManager: ObservableObject {
    @Published var entries: [WiFiHistoryEntry] = []
    
    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("EmojiWifi")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("history.json")
    }
    
    init() { load() }
    
    func addEntry(wifiName: String, password: String, description: String, source: String) {
        let entry = WiFiHistoryEntry(wifiName: wifiName, password: password, description: description, source: source)
        entries.insert(entry, at: 0)
        save()
    }
    
    func deleteEntry(_ entry: WiFiHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }
    
    func clearAll() { entries.removeAll(); save() }
    
    private func save() {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) { try? data.write(to: fileURL) }
    }
    
    private func load() {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([WiFiHistoryEntry].self, from: data) else { return }
        entries = decoded
    }
}
