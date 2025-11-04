import UIKit
import SwiftUI

// MARK: - 觸覺回饋管理器
class HapticManager {
    static let shared = HapticManager()
    
    @AppStorage("hapticFeedbackEnabled") private var isEnabled: Bool = true
    
    private init() {}
    
    // MARK: - 觸覺回饋類型
    
    /// 輕觸回饋 - 用於一般按鈕點擊
    func light() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// 中等回饋 - 用於重要操作
    func medium() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 強烈回饋 - 用於關鍵操作
    func heavy() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// 成功回饋
    func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 警告回饋
    func warning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// 錯誤回饋
    func error() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// 選擇回饋 - 用於滑動選擇
    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - 設定
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    func isHapticEnabled() -> Bool {
        return isEnabled
    }
}

// MARK: - SwiftUI View Extension
extension View {
    /// 添加觸覺回饋到任何 View
    func hapticFeedback(_ style: HapticStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .light:
                    HapticManager.shared.light()
                case .medium:
                    HapticManager.shared.medium()
                case .heavy:
                    HapticManager.shared.heavy()
                case .selection:
                    HapticManager.shared.selection()
                }
            }
        )
    }
}

enum HapticStyle {
    case light
    case medium
    case heavy
    case selection
}

