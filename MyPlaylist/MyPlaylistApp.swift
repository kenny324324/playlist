//
//  MyPlaylistApp.swift
//  MyPlaylist
//
//  Created by Kenny's Macbook on 2024/10/24.
//

import SwiftUI

@main
struct MyPlaylistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate  // 加入這一行

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)  // 強制使用深色模式
        }
    }
}
