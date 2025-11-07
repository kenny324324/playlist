//
//  DeviceAdaptive.swift
//  MyPlaylist
//
//  響應式設計擴展 - 針對 iPhone 和 iPad 提供不同的尺寸
//

import SwiftUI

// MARK: - 設備類型判斷
extension UIDevice {
    /// 是否為 iPad（使用螢幕尺寸判斷，更穩健）
    static var isPad: Bool {
        // 方法 1: 使用 idiom
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        
        // 方法 2: 使用螢幕尺寸作為後備判斷
        // iPad 最小螢幕寬度通常 >= 768pt
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let minDimension = min(screenWidth, screenHeight)
        return minDimension >= 768
    }
    
    /// 是否為 iPhone
    static var isPhone: Bool {
        !isPad
    }
}

// MARK: - 響應式尺寸計算
struct AdaptiveSize {
    /// 根據設備返回適當的尺寸
    /// - Parameters:
    ///   - phone: iPhone 上的尺寸
    ///   - pad: iPad 上的尺寸
    /// - Returns: 適合當前設備的尺寸
    static func size(phone: CGFloat, pad: CGFloat) -> CGFloat {
        UIDevice.isPad ? pad : phone
    }
    
    /// 常用的頭像尺寸
    static var profileImageSize: CGFloat {
        size(phone: 60, pad: 90)
    }
    
    /// Toolbar 中的小頭像尺寸
    static var toolbarAvatarSize: CGFloat {
        size(phone: 30, pad: 44)
    }
    
    /// 播放按鈕尺寸
    static var playButtonSize: CGFloat {
        size(phone: 30, pad: 44)
    }
    
    /// 卡片專輯/藝人圖片尺寸
    static var cardImageSize: CGFloat {
        size(phone: 140, pad: 200)
    }
    
    /// 列表項目高度
    static var listItemHeight: CGFloat {
        size(phone: 45, pad: 60)
    }
    
    /// 播放列表縮圖尺寸
    static var playlistThumbnailSize: CGFloat {
        size(phone: 50, pad: 70)
    }
    
    /// 按鈕內邊距 - 水平
    static var buttonPaddingHorizontal: CGFloat {
        size(phone: 16, pad: 24)
    }
    
    /// 按鈕內邊距 - 垂直
    static var buttonPaddingVertical: CGFloat {
        size(phone: 8, pad: 12)
    }
    
    /// 字體大小
    static func fontSize(phone: CGFloat, pad: CGFloat) -> CGFloat {
        size(phone: phone, pad: pad)
    }
}

// MARK: - View Extension for Adaptive Sizing
extension View {
    /// 響應式 frame 修飾符
    func adaptiveFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        let scale: CGFloat = UIDevice.isPad ? 1.4 : 1.0
        return self.frame(
            width: width.map { $0 * scale },
            height: height.map { $0 * scale }
        )
    }
    
    /// 響應式 padding
    func adaptivePadding(_ edges: Edge.Set = .all, phone: CGFloat, pad: CGFloat) -> some View {
        let value = AdaptiveSize.size(phone: phone, pad: pad)
        return self.padding(edges, value)
    }
    
    /// 響應式字體
    func adaptiveFont(name: String, phoneSize: CGFloat, padSize: CGFloat) -> some View {
        let size = AdaptiveSize.fontSize(phone: phoneSize, pad: padSize)
        return self.font(.custom(name, size: size))
    }
}

// MARK: - Presentation Detents for iPad
extension PresentationDetent {
    /// 針對 iPad 優化的 Sheet 高度
    static var adaptiveMedium: PresentationDetent {
        UIDevice.isPad ? .large : .medium
    }
    
    /// 返回適合的 detents 陣列
    static var adaptiveDetents: Set<PresentationDetent> {
        if UIDevice.isPad {
            return [.medium, .large]
        } else {
            return [.medium]
        }
    }
}

