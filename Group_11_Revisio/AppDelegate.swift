//
//  AppDelegate.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import UIKit
import GoogleSignIn // Added for Google Auth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Google Sign-In with your iOS Client ID from GoogleService-Info.plist
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "858933947587-ftgf8jrrlp55tdb9j21j8k43stc92k62.apps.googleusercontent.com"
        )
        
        return true
    }
    
    // Added to handle the "bounce back" from Google's login screen
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
