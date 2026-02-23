import SwiftUI
import AppKit

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var historyManager = HistoryManager()
    @State private var generatedWiFiName = ""
    @State private var generatedDescription = ""
    @State private var generatedPassword = ""
    @State private var passwordLength: Double = 62
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSpecialChars = true
    @State private var selectedStyle = WiFiStyle.combination
    @State private var selectedView: ViewTab = .generate
    @State private var qrCodeImage: NSImage?
    @State private var searchText = ""
    @State private var joinStatusMessage = ""
    @State private var showScanSuccessMessage = false
    @State private var scanSuccessMessage = ""
    @State private var showPasswordOptions = false
    @State private var showCombinations = false
    @State private var scanMode: ScanMode = .importImage
    
    enum ViewTab: String, CaseIterable {
        case generate = "Generate"
        case scan = "Scan"
        case history = "History"
    }
    
    enum ScanMode: String, CaseIterable {
        case importImage = "Import Image"
        case liveCamera = "Live Camera"
    }
    
    enum WiFiStyle: String, CaseIterable {
        case combination = "Combination"
        case single = "Single Emoji"
        case random = "Random Length"
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("EmojiWifi")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("Generate WiFi names using only emojis")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 30)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(ViewTab.allCases, id: \.self) { tab in
                        NavigationButton(
                            title: tab.rawValue,
                            icon: iconForTab(tab),
                            isSelected: selectedView == tab
                        ) { selectedView = tab }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 20)
                
                Spacer()
                
                // Current WiFi in sidebar
                if !generatedWiFiName.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current WiFi").font(.headline).padding(.horizontal, 20)
                        HStack {
                            Text(generatedWiFiName).font(.system(.body, design: .monospaced)).padding(.horizontal, 20).padding(.vertical, 8)
                            Spacer()
                            Button(action: { copyToClipboard(generatedWiFiName) }) {
                                Image(systemName: "doc.on.doc").font(.caption).foregroundColor(.secondary)
                            }.buttonStyle(PlainButtonStyle()).padding(.trailing, 20)
                        }
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.1)))
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Version 2.0").font(.caption).foregroundColor(.secondary)
                    Text("macOS WiFi Generator").font(.caption2).foregroundColor(.secondary)
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
            .frame(minWidth: 250, maxWidth: 300)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main Content
            Group {
                switch selectedView {
                case .generate: generateWiFiView
                case .scan: scanView
                case .history: historyView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showCombinations) { combinationsSheet }
        .overlay(toastOverlay)
        .onAppear { if generatedWiFiName.isEmpty { generateWiFiName() } }
    }
    
    // MARK: - Generate View
    private var generateWiFiView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WiFi Name Style").font(.headline)
                    Picker("WiFi Style", selection: $selectedStyle) {
                        ForEach(WiFiStyle.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).frame(maxWidth: 400)
                }.padding(.horizontal, 30).padding(.top, 30)
                
                HStack(spacing: 12) {
                    Button(action: generateWiFiName) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles").font(.title3)
                            Text("Generate WiFi Name").font(.headline)
                        }
                        .foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
                    }.buttonStyle(PlainButtonStyle())
                    
                    Button("Browse Combinations") { showCombinations = true }
                        .buttonStyle(.bordered)
                }.padding(.bottom, 10)
                
                // Inline password options
                DisclosureGroup("Password Options", isExpanded: $showPasswordOptions) {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Length: \(Int(passwordLength))").font(.subheadline)
                            Slider(value: $passwordLength, in: 8...63, step: 1).frame(maxWidth: 250)
                                .onChange(of: passwordLength) { _ in regeneratePassword() }
                        }
                        HStack(spacing: 16) {
                            Toggle("A-Z", isOn: $includeUppercase).onChange(of: includeUppercase) { _ in regeneratePassword() }
                            Toggle("a-z", isOn: $includeLowercase).onChange(of: includeLowercase) { _ in regeneratePassword() }
                            Toggle("0-9", isOn: $includeNumbers).onChange(of: includeNumbers) { _ in regeneratePassword() }
                            Toggle("!@#", isOn: $includeSpecialChars).onChange(of: includeSpecialChars) { _ in regeneratePassword() }
                        }.font(.caption)
                    }.padding(.top, 8)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                .padding(.horizontal, 30).padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Results
            ScrollView {
                LazyVStack(spacing: 24) {
                    if !generatedWiFiName.isEmpty {
                        ResultCard(title: "WiFi Network Name", content: generatedWiFiName, description: generatedDescription, color: .blue, actionTitle: "Copy WiFi Name") { copyToClipboard(generatedWiFiName) }
                    }
                    if !generatedPassword.isEmpty {
                        ResultCard(title: "WiFi Password", content: generatedPassword, description: "\(Int(passwordLength)) characters", color: .orange, actionTitle: "Copy Password") { copyToClipboard(generatedPassword) }
                    }
                    if !generatedWiFiName.isEmpty && !generatedPassword.isEmpty {
                        QRCodeCard(wifiName: generatedWiFiName, password: generatedPassword, qrCodeImage: $qrCodeImage)
                        
                        // Join button
                        HStack(spacing: 12) {
                            Button(action: {
                                joinStatusMessage = "Joining network..."
                                WiFiJoiner.joinWiFi(ssid: generatedWiFiName, password: generatedPassword) { joinStatusMessage = $0 }
                            }) {
                                HStack(spacing: 6) { Image(systemName: "wifi"); Text("Join Network") }
                                    .foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.green))
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                    if !joinStatusMessage.isEmpty {
                        Text(joinStatusMessage)
                            .font(.body)
                            .foregroundColor(joinStatusMessage.contains("✅") ? .green : joinStatusMessage.contains("❌") ? .red : .orange)
                            .padding().background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 30).padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onChange(of: generatedWiFiName) { _ in if !generatedPassword.isEmpty { generateQRCode() } }
        .onChange(of: generatedPassword) { _ in if !generatedWiFiName.isEmpty { generateQRCode() } }
    }
    
    // MARK: - Scan View
    private var scanView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack { Text("Scan QR Code").font(.title).fontWeight(.bold); Spacer() }
                Picker("Scan Mode", selection: $scanMode) {
                    ForEach(ScanMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).frame(maxWidth: 300)
            }
            .padding().background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if scanMode == .importImage {
                ImportQRCodeImageView(
                    onQRCodeScanned: { handleScannedQR($0, source: "imported") },
                    onJoinStatusUpdated: { joinStatusMessage = $0 }
                )
            } else {
                LiveScanQRCodeView(
                    onQRCodeScanned: { handleScannedQR($0, source: "scanned") },
                    onJoinStatusUpdated: { joinStatusMessage = $0 }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - History View
    private var historyView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("History").font(.title).fontWeight(.bold)
                Spacer()
                if !historyManager.entries.isEmpty {
                    Button("Clear All") { historyManager.clearAll() }
                        .buttonStyle(.bordered).controlSize(.small).foregroundColor(.red)
                }
            }
            .padding().background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if historyManager.entries.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 48)).foregroundColor(.secondary)
                    Text("No history yet").font(.headline).foregroundColor(.secondary)
                    Text("Generated and scanned WiFi networks will appear here").font(.body).foregroundColor(.secondary)
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(historyManager.entries) { entry in
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.wifiName).font(.title2)
                                    Text(entry.description).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Text(entry.source).font(.caption2)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(badgeColor(entry.source).opacity(0.15)))
                                    .foregroundColor(badgeColor(entry.source))
                                
                                Text(entry.timestamp, style: .relative).font(.caption).foregroundColor(.secondary).frame(width: 80, alignment: .trailing)
                                
                                HStack(spacing: 8) {
                                    Button(action: { reuse(entry) }) { Image(systemName: "arrow.uturn.left").font(.caption) }
                                        .buttonStyle(.bordered).controlSize(.mini).help("Reuse")
                                    Button(action: { copyToClipboard(entry.wifiName) }) { Image(systemName: "doc.on.doc").font(.caption) }
                                        .buttonStyle(.bordered).controlSize(.mini).help("Copy")
                                    Button(action: { historyManager.deleteEntry(entry) }) { Image(systemName: "trash").font(.caption).foregroundColor(.red) }
                                        .buttonStyle(.bordered).controlSize(.mini).help("Delete")
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(NSColor.separatorColor), lineWidth: 1)))
                        }
                    }.padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Combinations Sheet
    private var combinationsSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Text("All Emoji Combinations").font(.title2).fontWeight(.bold)
                Spacer()
                Button("Done") { showCombinations = false }.buttonStyle(.bordered)
            }.padding()
            
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search...", text: $searchText).textFieldStyle(PlainTextFieldStyle()).padding(8).background(Color(NSColor.textBackgroundColor)).cornerRadius(6)
                if !searchText.isEmpty { Button("Clear") { searchText = "" }.buttonStyle(.bordered).controlSize(.small) }
            }.padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
                    ForEach(filteredCombinations, id: \.name) { combo in
                        VStack(spacing: 8) {
                            Text(combo.emojis).font(.system(size: 24)).padding(8).background(Color.blue.opacity(0.1)).cornerRadius(8)
                            Text(combo.name).font(.caption).foregroundColor(.secondary)
                        }
                        .padding(10).background(Color.gray.opacity(0.05)).cornerRadius(8)
                        .onTapGesture { generatedWiFiName = combo.emojis; generatedDescription = combo.name; copyToClipboard(combo.emojis); showCombinations = false; selectedView = .generate }
                    }
                }.padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear { searchText = "" }
    }
    
    // MARK: - Toast Overlay
    private var toastOverlay: some View {
        Group {
            if showScanSuccessMessage {
                VStack { Spacer(); HStack { Spacer(); Text(scanSuccessMessage).font(.headline).foregroundColor(.white).padding().background(Color.green).cornerRadius(8).shadow(radius: 5); Spacer() }.padding(.bottom, 50) }
            }
        }
    }
    
    // MARK: - Helpers
    private var filteredCombinations: [(name: String, emojis: String)] {
        searchText.isEmpty ? EmojiWiFiGenerator.getAllCombinations() :
            EmojiWiFiGenerator.getAllCombinations().filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.emojis.contains(searchText) }
    }
    
    private func iconForTab(_ tab: ViewTab) -> String {
        switch tab { case .generate: return "sparkles"; case .scan: return "qrcode.viewfinder"; case .history: return "clock.arrow.circlepath" }
    }
    
    private func badgeColor(_ source: String) -> Color {
        source == "generated" ? .blue : source == "scanned" ? .green : .orange
    }
    
    private func reuse(_ entry: WiFiHistoryEntry) {
        generatedWiFiName = entry.wifiName; generatedPassword = entry.password
        generatedDescription = entry.description; generateQRCode(); selectedView = .generate
    }
    
    private func handleScannedQR(_ qrString: String, source: String) {
        let (ssid, password) = QRCodeGenerator.parseWiFiQRCode(qrString)
        if let s = ssid { generatedWiFiName = s; generatedDescription = "\(source == "imported" ? "Imported" : "Scanned") from QR code" }
        if let p = password { generatedPassword = p }
        generateQRCode()
        if let s = ssid, let p = password {
            historyManager.addEntry(wifiName: s, password: p, description: "\(source == "imported" ? "Imported" : "Scanned") from QR code", source: source)
        }
        selectedView = .generate
        scanSuccessMessage = "✅ QR Code \(source)!"
        showScanSuccessMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showScanSuccessMessage = false }
    }
    
    private func regeneratePassword() {
        if !generatedWiFiName.isEmpty {
            generatedPassword = PasswordGenerator.generateWiFiPassword(length: Int(passwordLength), includeUppercase: includeUppercase, includeLowercase: includeLowercase, includeNumbers: includeNumbers, includeSpecialChars: includeSpecialChars)
        }
    }
    
    private func generateWiFiName() {
        switch selectedStyle {
        case .combination:
            let combo = EmojiWiFiGenerator.getRandomCombination()
            generatedWiFiName = combo.emojis; generatedDescription = combo.name
        case .single:
            generatedWiFiName = EmojiWiFiGenerator.generateSingleEmojiWiFiName()
            generatedDescription = EmojiWiFiGenerator.getSingleEmojiDescription(generatedWiFiName)
        case .random:
            generatedWiFiName = EmojiWiFiGenerator.generateRandomLengthEmojiWiFiName()
            generatedDescription = "Random combination of \(generatedWiFiName.count) emojis"
        }
        generatedPassword = PasswordGenerator.generateWiFiPassword(length: Int(passwordLength), includeUppercase: includeUppercase, includeLowercase: includeLowercase, includeNumbers: includeNumbers, includeSpecialChars: includeSpecialChars)
        generateQRCode()
        historyManager.addEntry(wifiName: generatedWiFiName, password: generatedPassword, description: generatedDescription, source: "generated")
    }
    
    private func generateQRCode() {
        if !generatedWiFiName.isEmpty && !generatedPassword.isEmpty {
            qrCodeImage = QRCodeGenerator.generateWiFiQRCode(ssid: generatedWiFiName, password: generatedPassword)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general; pb.clearContents(); pb.setString(text, forType: .string)
    }
}

// MARK: - QR Code Full View
struct QRCodeView: View {
    let wifiName: String; let password: String
    @Environment(\.presentationMode) var presentationMode
    @State private var qrCodeImage: NSImage?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack { Spacer(); Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "xmark.circle.fill").font(.title2) }.buttonStyle(PlainButtonStyle()) }
            Text("WiFi QR Code").font(.largeTitle).fontWeight(.bold)
            Text(wifiName).font(.title)
            if let img = qrCodeImage {
                Image(nsImage: img).interpolation(.none).resizable().aspectRatio(contentMode: .fit).frame(width: 300, height: 300).background(Color.white).cornerRadius(16).shadow(radius: 10)
            }
            Text("Password: \(password)").font(.system(.body, design: .monospaced)).foregroundColor(.secondary)
            Spacer()
            Button("Close") { presentationMode.wrappedValue.dismiss() }.buttonStyle(.bordered).padding(.bottom)
        }
        .frame(minWidth: 500, maxWidth: 600, minHeight: 600)
        .padding(20)
        .onAppear { qrCodeImage = QRCodeGenerator.generateWiFiQRCode(ssid: wifiName, password: password) }
    }
}

// MARK: - App Entry Point
@main
struct EmojiWifiApp: App {
    init() { EmojiWiFiGenerator.initializeFromCSV() }
    var body: some Scene {
        WindowGroup { ContentView() }
            .windowStyle(.titleBar)
            .windowResizability(.contentMinSize)
            .defaultSize(width: 800, height: 600)
            .commands { CommandGroup(replacing: .newItem) { }; CommandGroup(replacing: .help) { } }
    }
}
