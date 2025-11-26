//
//  MailService.swift
//  MyPlaylist
//
//  Created by Kenny's Macbook on 2024/11/26.
//

import SwiftUI
import MessageUI

/// 郵件發送服務
/// 用於回報問題、提供意見回饋等功能
class MailService: NSObject {
    static let shared = MailService()
    
    private override init() {}
    
    /// 支援的郵件類型
    enum MailType {
        case reportIssue        // 回報問題
        case feedback           // 意見回饋
        case support            // 技術支援
        
        var subject: String {
            switch self {
            case .reportIssue:
                return String(localized: "mail.subject.reportIssue")
            case .feedback:
                return String(localized: "mail.subject.feedback")
            case .support:
                return String(localized: "mail.subject.support")
            }
        }
        
        var body: String {
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            let systemVersion = UIDevice.current.systemVersion
            let deviceModel = UIDevice.current.model
            
            let systemInfo = """
            
            
            ---
            \(String(localized: "mail.systemInfo"))
            App Version: \(appVersion) (\(buildNumber))
            iOS Version: \(systemVersion)
            Device: \(deviceModel)
            ---
            """
            
            switch self {
            case .reportIssue:
                return String(localized: "mail.body.reportIssue") + systemInfo
            case .feedback:
                return String(localized: "mail.body.feedback") + systemInfo
            case .support:
                return String(localized: "mail.body.support") + systemInfo
            }
        }
    }
    
    /// 檢查設備是否支援發送郵件
    func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    /// 創建郵件視圖控制器
    func createMailComposeViewController(
        type: MailType,
        recipient: String = "kenny4work324@gmail.com"
    ) -> MFMailComposeViewController? {
        
        guard canSendMail() else {
            return nil
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.setToRecipients([recipient])
        mailComposer.setSubject(type.subject)
        mailComposer.setMessageBody(type.body, isHTML: false)
        
        return mailComposer
    }
    
    /// 使用 mailto URL 打開郵件應用（備用方案）
    func openMailApp(
        type: MailType,
        recipient: String = "kenny4work324@gmail.com"
    ) {
        let subject = type.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = type.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoString = "mailto:\(recipient)?subject=\(subject)&body=\(body)"
        
        if let mailtoURL = URL(string: mailtoString) {
            if UIApplication.shared.canOpenURL(mailtoURL) {
                UIApplication.shared.open(mailtoURL)
            }
        }
    }
}

// MARK: - SwiftUI 整合

/// 郵件撰寫視圖
struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    let mailType: MailService.MailType
    let recipient: String
    var onComplete: ((MFMailComposeResult) -> Void)?
    
    init(
        mailType: MailService.MailType,
        recipient: String = "kenny4work324@gmail.com",
        onComplete: ((MFMailComposeResult) -> Void)? = nil
    ) {
        self.mailType = mailType
        self.recipient = recipient
        self.onComplete = onComplete
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MailService.shared.createMailComposeViewController(
            type: mailType,
            recipient: recipient
        ) ?? MFMailComposeViewController()
        
        mailComposer.mailComposeDelegate = context.coordinator
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            parent.onComplete?(result)
            parent.dismiss()
        }
    }
}

// MARK: - 便利的 View Modifier

extension View {
    /// 顯示郵件撰寫視圖
    func mailSheet(
        isPresented: Binding<Bool>,
        mailType: MailService.MailType,
        recipient: String = "kenny4work324@gmail.com",
        onComplete: ((MFMailComposeResult) -> Void)? = nil
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            MailComposeView(
                mailType: mailType,
                recipient: recipient,
                onComplete: onComplete
            )
        }
    }
}

