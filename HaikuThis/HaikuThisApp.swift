//
//  HaikuThisApp.swift
//  HaikuThis
//
//  Created by Khanh Nguyen on 7/30/25.
//

import SwiftUI
import FirebaseCore

@main
struct HaikuThisApp: App {
	 @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
	 @State private var model = authModel()
    var body: some Scene {
        WindowGroup {
					 ContentView()
							.environmentObject(model)
							.environment(\.colorScheme, .light)
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
	 func application(_ application: UIApplication,
										didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
			FirebaseApp.configure()
			return true
	 }
}
