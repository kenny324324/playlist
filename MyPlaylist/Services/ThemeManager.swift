import SwiftUI

// MARK: - 色系定義
enum ColorTone: String, CaseIterable, Identifiable {
    case defaultTone = "default"
    case softTone = "soft"
    case pastelTone = "pastel"
    case earthTone = "earth"
    
    var id: String { self.rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .defaultTone: return "tone.default"
        case .softTone: return "tone.soft"
        case .pastelTone: return "tone.pastel"
        case .earthTone: return "tone.earth"
        }
    }
}

// MARK: - 主題顏色定義
enum ThemeColor: String, CaseIterable, Identifiable {
    case color1 = "color1"   // Green
    case color2 = "color2"   // Blue
    case color3 = "color3"   // Purple
    case color4 = "color4"   // Orange
    case color5 = "color5"   // Pink
    case color6 = "color6"   // Gold
    case color7 = "color7"   // Sky Blue
    case color8 = "color8"   // Red
    case color9 = "color9"   // Teal
    case color10 = "color10" // Indigo
    
    var id: String { self.rawValue }
    
    func color(for tone: ColorTone) -> Color {
        switch tone {
        case .defaultTone:
            return defaultColor
        case .softTone:
            return softColor
        case .pastelTone:
            return pastelColor
        case .earthTone:
            return earthColor
        }
    }
    
    // Default Tone - 鮮豔飽和
    private var defaultColor: Color {
        switch self {
        case .color1: return Color(red: 0.11, green: 0.84, blue: 0.38)  // Spotify Green
        case .color2: return Color(red: 0.13, green: 0.59, blue: 0.95)  // Ocean Blue
        case .color3: return Color(red: 0.61, green: 0.35, blue: 0.95)  // Soft Purple
        case .color4: return Color(red: 0.95, green: 0.47, blue: 0.28)  // Coral Orange
        case .color5: return Color(red: 0.95, green: 0.33, blue: 0.58)  // Rose Pink
        case .color6: return Color(red: 0.95, green: 0.69, blue: 0.18)  // Amber Gold
        case .color7: return Color(red: 0.28, green: 0.77, blue: 0.96)  // Sky Blue
        case .color8: return Color(red: 0.93, green: 0.26, blue: 0.38)  // Ruby Red
        case .color9: return Color(red: 0.12, green: 0.75, blue: 0.68)  // Teal
        case .color10: return Color(red: 0.35, green: 0.34, blue: 0.84) // Indigo
        }
    }
    
    // Soft Tone - 莫蘭迪色系（降低飽和度、增加灰調）
    private var softColor: Color {
        switch self {
        case .color1: return Color(red: 0.52, green: 0.70, blue: 0.59)  // Sage Green
        case .color2: return Color(red: 0.55, green: 0.65, blue: 0.75)  // Dusty Blue
        case .color3: return Color(red: 0.68, green: 0.62, blue: 0.75)  // Lavender Gray
        case .color4: return Color(red: 0.82, green: 0.68, blue: 0.62)  // Terracotta
        case .color5: return Color(red: 0.80, green: 0.65, blue: 0.70)  // Dusty Rose
        case .color6: return Color(red: 0.82, green: 0.75, blue: 0.60)  // Sand
        case .color7: return Color(red: 0.60, green: 0.72, blue: 0.78)  // Powder Blue
        case .color8: return Color(red: 0.75, green: 0.58, blue: 0.60)  // Mauve
        case .color9: return Color(red: 0.56, green: 0.72, blue: 0.70)  // Sage Teal
        case .color10: return Color(red: 0.60, green: 0.60, blue: 0.72) // Dusty Indigo
        }
    }
    
    // Pastel Tone - 粉彩色系（高明度、柔和）
    private var pastelColor: Color {
        switch self {
        case .color1: return Color(red: 0.67, green: 0.89, blue: 0.75)  // Mint Green
        case .color2: return Color(red: 0.68, green: 0.82, blue: 0.95)  // Baby Blue
        case .color3: return Color(red: 0.82, green: 0.75, blue: 0.94)  // Lilac
        case .color4: return Color(red: 0.98, green: 0.82, blue: 0.71)  // Peach
        case .color5: return Color(red: 0.98, green: 0.78, blue: 0.85)  // Pink
        case .color6: return Color(red: 0.98, green: 0.89, blue: 0.71)  // Cream
        case .color7: return Color(red: 0.73, green: 0.88, blue: 0.96)  // Light Blue
        case .color8: return Color(red: 0.95, green: 0.75, blue: 0.77)  // Coral Pink
        case .color9: return Color(red: 0.70, green: 0.92, blue: 0.90)  // Mint Teal
        case .color10: return Color(red: 0.78, green: 0.80, blue: 0.94) // Periwinkle
        }
    }
    
    // Earth Tone - 大地色系（自然、溫暖、棕調）
    private var earthColor: Color {
        switch self {
        case .color1: return Color(red: 0.45, green: 0.58, blue: 0.42)  // Olive Green
        case .color2: return Color(red: 0.42, green: 0.52, blue: 0.58)  // Slate Blue
        case .color3: return Color(red: 0.55, green: 0.48, blue: 0.55)  // Taupe
        case .color4: return Color(red: 0.75, green: 0.52, blue: 0.38)  // Clay
        case .color5: return Color(red: 0.72, green: 0.48, blue: 0.52)  // Terracotta Rose
        case .color6: return Color(red: 0.78, green: 0.65, blue: 0.42)  // Ochre
        case .color7: return Color(red: 0.48, green: 0.58, blue: 0.62)  // Stone Blue
        case .color8: return Color(red: 0.65, green: 0.42, blue: 0.40)  // Rust
        case .color9: return Color(red: 0.42, green: 0.58, blue: 0.55)  // Forest Teal
        case .color10: return Color(red: 0.48, green: 0.45, blue: 0.58) // Eggplant
        }
    }
}

// MARK: - 主題管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = ThemeColor.color1.rawValue
    @AppStorage("selectedTone") private var selectedToneRawValue: String = ColorTone.defaultTone.rawValue
    
    @Published var currentTheme: ThemeColor
    @Published var currentTone: ColorTone
    
    var themeColor: Color {
        currentTheme.color(for: currentTone)
    }
    
    private init() {
        // 讀取保存的色系
        if let tone = ColorTone(rawValue: UserDefaults.standard.string(forKey: "selectedTone") ?? ColorTone.defaultTone.rawValue) {
            self.currentTone = tone
        } else {
            self.currentTone = .defaultTone
        }
        
        // 讀取保存的主題顏色
        if let theme = ThemeColor(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? ThemeColor.color1.rawValue) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .color1
        }
    }
    
    func setTheme(_ theme: ThemeColor) {
        currentTheme = theme
        selectedThemeRawValue = theme.rawValue
    }
    
    func setTone(_ tone: ColorTone) {
        currentTone = tone
        selectedToneRawValue = tone.rawValue
    }
    
    // 重置為預設主題（登出時使用）
    func resetToDefault() {
        currentTheme = .color1  // 預設綠色
        currentTone = .defaultTone  // 預設色系
        selectedThemeRawValue = ThemeColor.color1.rawValue
        selectedToneRawValue = ColorTone.defaultTone.rawValue
    }
}

// MARK: - Color Extension
extension Color {
    static let spotifyText = Color(red: 0.07, green: 0.07, blue: 0.07)
    
    // 動態主題色
    static var themeColor: Color {
        ThemeManager.shared.themeColor
    }
    
    // 保留舊的 spotifyGreen 以兼容性（但實際上會使用動態主題色）
    static var spotifyGreen: Color {
        ThemeManager.shared.themeColor
    }
    
    // 固定的 Spotify 綠色（不受主題影響，用於 Spotify 相關按鈕）
    static let spotifyDefaultGreen = Color(red: 0.11, green: 0.84, blue: 0.38)
}

