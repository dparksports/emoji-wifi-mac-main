import Foundation

// MARK: - CSV Parsing
func parseCSVLine(_ line: String) -> [String] {
    var components: [String] = []
    var currentComponent = ""
    var inQuotes = false
    for (index, character) in line.enumerated() {
        if character == "\"" {
            if index + 1 < line.count && line[line.index(line.startIndex, offsetBy: index + 1)] == "\"" {
                currentComponent += "\""
            } else { inQuotes.toggle() }
        } else if character == "," && !inQuotes {
            components.append(currentComponent); currentComponent = ""
        } else { currentComponent += String(character) }
    }
    components.append(currentComponent)
    return components
}

func loadSingleEmojiDescriptionsFromCSV() -> [String: String] {
    var descriptions: [String: String] = [:]
    guard let url = Bundle.module.url(forResource: "single", withExtension: "csv") else {
        print("❌ Could not find single.csv in bundle"); return descriptions
    }
    do {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        for line in csvContent.components(separatedBy: CharacterSet.newlines).dropFirst() {
            if line.isEmpty { continue }
            let components = parseCSVLine(line)
            if components.count >= 2 {
                descriptions[components[0].trimmingCharacters(in: .whitespacesAndNewlines)] = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        print("✅ Loaded \(descriptions.count) emoji descriptions from single.csv")
    } catch { print("❌ Error loading single.csv: \(error)") }
    return descriptions
}

func loadEmojiCombinationsFromCSV() -> [(name: String, emojis: String)] {
    var combinations: [(name: String, emojis: String)] = []
    guard let url = Bundle.module.url(forResource: "combos", withExtension: "csv") else {
        print("❌ Could not find combos.csv in bundle"); return combinations
    }
    do {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        for line in csvContent.components(separatedBy: CharacterSet.newlines).dropFirst() {
            if line.isEmpty { continue }
            let components = parseCSVLine(line)
            if components.count >= 2 {
                combinations.append((name: components[0].trimmingCharacters(in: .whitespacesAndNewlines), emojis: components[1].trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        print("✅ Loaded \(combinations.count) emoji combinations from combos.csv")
    } catch { print("❌ Error loading combos.csv: \(error)") }
    return combinations
}

// MARK: - Emoji WiFi Name Generator
class EmojiWiFiGenerator {
    static var loadedDescriptions: [String: String] = [:]
    static var loadedCombinations: [(name: String, emojis: String)] = []
    
    static func initializeFromCSV() {
        loadedDescriptions = loadSingleEmojiDescriptionsFromCSV()
        loadedCombinations = loadEmojiCombinationsFromCSV()
    }

    static var emojiCombinations: [(name: String, emojis: String)] {
        return loadedCombinations.isEmpty ? [
            ("Tech Hub", "💻📶🌐"), ("Signal Strong", "📡⚡🔥"), ("Network Master", "🔗💾🎮"), ("Digital Space", "🌐💻📱"), ("WiFi Zone", "📶🔗💡"), ("Space Station", "🚀🛰️🌌"), ("Galaxy Network", "🌌⭐🌑"), ("Rocket WiFi", "🚀⚡💨"), ("Astronaut Zone", "👨‍🚀🛰️🌌"), ("Cosmic Signal", "⭐🌌📡"), ("Gaming Hub", "🎮🎵🎧"), ("Game Zone", "🎮⚔️🛡️"), ("Player One", "🎮👾🤖"), ("Gaming Station", "🎮🎸🎤"), ("Arcade WiFi", "🎮💾🔫"), ("Music Studio", "🎵🎧🎤"), ("Rock WiFi", "🎸🤘🎵"), ("Sound Wave", "🎵🌊🎧"), ("Music Zone", "🎤🎸🎵"), ("Audio Hub", "🎧🎵🎤"), ("Nature WiFi", "🌲🌻🌱"), ("Forest Signal", "🌲🏞️🌿"), ("Garden Network", "🌻🌱🌿"), ("Tree WiFi", "🌲🌳🌱"), ("Natural Zone", "🌿🌻🌱"), ("Food Network", "🍕🍔🍟"), ("Pizza WiFi", "🍕🍕🍕"), ("Burger Zone", "🍔🍟🥤"), ("Snack Hub", "🍟🍕🍰"), ("Foodie WiFi", "🍕🍔🍰"), ("Cool Zone", "😎🔥⚡"), ("Stylish WiFi", "😎💎✨"), ("Awesome Network", "😎👍🔥"), ("Epic WiFi", "🔥⚡💥"), ("Legendary Zone", "👑⚡🔥"), ("Dark Network", "🖤🌑👻"), ("Ghost WiFi", "👻💀🖤"), ("Mystery Zone", "🔮🌑👻"), ("Shadow Network", "🖤🌑👻"), ("Night WiFi", "🌙⭐👻"), ("Dark Vader", "🖤🤖⚔️"), ("Fun Zone", "😄🎉🎈"), ("Happy WiFi", "😊🌈✨"), ("Party Network", "🎉🎊🎈"), ("Joy Zone", "😄😊🎉"), ("Smile WiFi", "😊💖✨"), ("Cat Zone", "🐱😸🐾"), ("Dog WiFi", "🐶🐕🐾"), ("Panda Paradise", "🐼🎋🎍"), ("Animal Kingdom", "🐱🐶🐼"), ("Pet Network", "🐾🐱🐶"), ("Storm WiFi", "⛈️⚡🌧️"), ("Sunny Zone", "☀️🌞🌻"), ("Rainbow Network", "🌈☀️🌧️"), ("Weather Hub", "🌤️⛈️🌈"), ("Sky WiFi", "☁️🌤️🌈"), ("Love Zone", "💖💕💗"), ("Heart WiFi", "❤️💙💚"), ("Sweet Network", "💖🍰💕"), ("Romance Zone", "💕💖💗"), ("Love Hub", "❤️💕💖"), ("Power Zone", "⚡🔥💥"), ("Energy WiFi", "⚡🔋💡"), ("Lightning Fast", "⚡💨🚀"), ("Power Hub", "⚡🔥💥"), ("Energy Zone", "🔋⚡💡"), ("Simple WiFi", "✨💫⭐"), ("Clean Zone", "🤍✨💫"), ("Pure Network", "🤍💫✨"), ("Minimal WiFi", "✨🤍💫"), ("Clear Zone", "💫✨🤍")
        ] : loadedCombinations
    }
    
    static var singleEmojis: [String] {
        return loadedDescriptions.isEmpty ? [
            "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🥹", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "🥲", "😋", "😛", "😜", "😝", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "😫", "😩", "🥺", "😢", "😭", "😮‍💨", "😤", "😠", "😡", "🤬", "😈", "👿", "💀", "👻", "👽", "🤖", "🤡", "👹", "👺", "😼", "😽", "😿", "😹", "😾", "😺", "😸", "🙌", "👏", "👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤏", "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛", "🤜", "🙏", "✍️", "💅", "👂", "👃", "👀", "🧠", "🦷", "👅", "💋", "👶", "👧", "👦", "👩", "🧑", "👨", "👵", "👴", "👸", "🤴", "👰", "🤵", "🤰", "🤱", "👼", "🎅", "🦸", "🦹", "🧙", "🧚", "🧛", "🧜", "🧝", "🧞", "🧟", "🚶", "🏃", "💃", "🕺", "🗣️", "👤", "👥",
            "🐵", "🐒", "🦍", "🦧", "🐶", "🐕", "🐩", "🐺", "🦊", "🦝", "🐱", "🐈", "🦁", "🐅", "🐆", "🐴", "🐎", "🦌", "🐮", "🐂", "🐃", "🐄", "🐷", "🐖", "🐗", "🐏", "🐑", "🐐", "🐪", "🐫", "🦙", "🦒", "🐘", "🦣", "🦏", "🦛", "🐭", "🐁", "🐀", "🐹", "🐰", "🐇", "🐿️", "🦫", "🦇", "🐻", "🐨", "🐼", "🦥", "🦦", "🦨", "🦘", "🦡", "🐾", "🦃", "🐔", "🐓", "🐣", "🐤", "🐥", "🐦", "🐧", "🕊️", "🦅", "🦆", "🦢", "🦉", "🦤", "🪶", "🐸", "🐊", "🐢", "🐍", "🦎", "🦖", "🦕", "🐳", "🐋", "🐬", "🦭", "🐟", "🐠", "🐡", "🦈", "🐙", "🐚", "🐌", "🦋", "🐛", "🐜", "🐝", "🪲", "🦗", "🕷️", "🦂", "🦟", "🦠", "💐", "🌸", "💮", "🌹", "🥀", "🌺", "🌻", "🌷", "🌱", "🌲", "🌳", "🌴", "🌵", "🌾", "🌿", "🍀", "🍁", "🍂", "🍃",
            "🍇", "🍈", "🍉", "🍊", "🍋", "🍌", "🍍", "🥭", "🍎", "🍏", "🍐", "🍑", "🍒", "🍓", "🥝", "🍅", "🥥", "🥑", "🍆", "🥔", "🥕", "🌽", "🌶️", "🥒", "🍄", "🌰", "🥜", "🍯", "🍞", "🥐", "🥖", "🥨", "🥞", "🧇", "🧀", "🥩", "🥓", "🍔", "🍟", "🍕", "🌭", "🌮", "🌯", "🥙", "🥗", "🥘", "🍝", "🍜", "🥟", "🍣", "🍤", "🍚", "🍛", "🍙", "🍘", "🍠", "🍢", "🍡", "🍧", "🍨", "🍦", "🥧", "🍰", "🍮", "🍬", "🍭", "🍫", "🍩", "🍪", "☕", "🍵", "🥤", "🥛", "🍻", "🥂", "🥃", "🍸", "🍹", "🍾", "🧊",
            "🌎", "🌍", "🌏", "🌐", "🗾", "🧭", "🏔️", "⛰️", "🌋", "🏕️", "🏖️", "🏜️", "🏝️", "🌃", "🏙️", "🌉", "🏠", "🏡", "🏢", "🏣", "🏥", "🏦", "🏨", "⛪", "🕌", "🕍", "⛩️", "🕋", "🗽", "🗼", "🏯", "🏰", "⛲", "🗿", "🚂", "🚆", "🚇", "🚝", "🚋", "🚌", "🚎", "🚕", "🚗", "🚙", "🚚", "🚛", "🚜", "🚲", "🛴", "🛵", "🏍️", "🛺", "🚨", "🚑", "🚒", "🚓", "✈️", "🛫", "🛬", "🚁", "🚀", "🛰️", "🛸", "🚢", "⛵", "🚤", "⚓", "🚧", "⛽", "🚦", "🚥",
            "⌚", "📱", "📲", "💻", "⌨️", "🖥️", "🖨️", "🖱️", "💾", "💿", "📀", "🧮", "🔭", "🔬", "💡", "🔦", "🔋", "🔌", "🔧", "🔨", "🔩", "⚙️", "🔪", "⚔️", "🛡️", "🔫", "🏹", "💣", "💰", "💴", "💵", "💶", "💷", "💳", "🧾", "✉️", "📧", "📥", "📤", "📦", "📫", "📪", "🔔", "🔕", "📓", "📔", "📒", "📚", "📖", "🔖", "📎", "📌", "📍", "📐", "📏", "✂️", "🔒", "🔑", "🗝️", "🚪", "🛋️", "🛏️", "🖼️", "🎈", "🎁", "🎉", "🎊", "🎀", "🪄", "🎵", "🎶", "🎤", "🎧", "🎷", "🎸", "🎹", "🎺", "🥁", "🎬", "🎨", "🎰", "🎲", "🎳", "🎮", "🕹️", "♠️", "♥️", "♦️", "♣️", "🌟", "⭐", "☀️", "🌙", "☁️", "🌧️", "🌩️", "❄️", "🔥", "💧", "🌈", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "💯", "✅", "❌", "❓", "❕", "⚠️", "🆘"
        ] : Array(loadedDescriptions.keys)
    }

    static func generateEmojiWiFiName() -> String { emojiCombinations.randomElement()!.emojis }
    static func generateSingleEmojiWiFiName() -> String { singleEmojis.randomElement()! }
    static func generateRandomLengthEmojiWiFiName() -> String {
        (0..<Int.random(in: 1...4)).map { _ in singleEmojis.randomElement()! }.joined()
    }
    static func getRandomCombination() -> (name: String, emojis: String) { emojiCombinations.randomElement()! }
    static func getAllCombinations() -> [(name: String, emojis: String)] { emojiCombinations }
    
    static func getSingleEmojiDescription(_ emoji: String) -> String {
        if !loadedDescriptions.isEmpty {
            return loadedDescriptions[emoji] ?? "A unique emoji symbol"
        }
        let descriptions: [String: String] = [
            "📶": "Antenna Bars", "📡": "Satellite Antenna", "💻": "Laptop", "📱": "Mobile Phone", "🌐": "Globe", "🔗": "Link", "💾": "Floppy Disk", "🎮": "Video Game", "🚀": "Rocket", "🛰️": "Satellite", "🌌": "Milky Way", "🌑": "New Moon", "⭐": "Star", "👨‍🚀": "Astronaut", "🤖": "Robot", "👾": "Alien Monster", "⚔️": "Crossed Swords", "🛡️": "Shield", "💥": "Collision", "🖤": "Black Heart", "❤️": "Red Heart", "💙": "Blue Heart", "💚": "Green Heart", "💜": "Purple Heart", "🤍": "White Heart", "🎵": "Musical Note", "🎧": "Headphone", "🎤": "Microphone", "🎸": "Guitar", "🍕": "Pizza", "🍔": "Hamburger", "🍟": "French Fries", "🍰": "Shortcake", "🌲": "Evergreen Tree", "🌻": "Sunflower", "🐱": "Cat Face", "🐶": "Dog Face", "🐼": "Panda Face", "💡": "Light Bulb", "🔑": "Key", "🔒": "Locked", "⚡": "High Voltage", "🔥": "Fire", "❄️": "Snowflake", "🌈": "Rainbow", "😎": "Sunglasses", "🤓": "Nerd Face", "😈": "Devil", "👻": "Ghost", "💀": "Skull", "👍": "Thumbs Up", "✌️": "Peace Sign", "🤘": "Rock On", "👊": "Fist", "🧠": "Brain", "🌱": "Seedling", "🔬": "Microscope"
        ]
        return descriptions[emoji] ?? "A unique emoji symbol"
    }
}
