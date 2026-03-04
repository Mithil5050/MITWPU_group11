//
//  SceneDelegate.swift
//  Group_11_Revisio
//

import UIKit
import Supabase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // 1. Set a temporary root view controller while checking the session (prevents a black screen)
        window.rootViewController = storyboard.instantiateInitialViewController()
        window.makeKeyAndVisible()
        
        Task {
            do {
                // ✅ 2. Ask Supabase if this user is already logged in
                _ = try await supabase.auth.session
                
                // 🟢 YES: User is logged in -> Load the Tab Bar
                DispatchQueue.main.async {
                    let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
                    window.rootViewController = tabBarVC
                    
                    // Smooth cross-fade animation into the app
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                }
            } catch {
                // 🔴 NO: No active session -> Show the Onboarding flow
                DispatchQueue.main.async {
                    let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
                    
                    // Wrap in Navigation Controller so 'pushViewController' works inside Onboarding
                    let nav = UINavigationController(rootViewController: onboardingVC)
                    nav.isNavigationBarHidden = true // Keeps the splash look clean
                    
                    window.rootViewController = nav
                    
                    // Smooth cross-fade animation into the login flow
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
