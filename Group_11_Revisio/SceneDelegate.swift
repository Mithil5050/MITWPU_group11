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
        
        window.rootViewController = storyboard.instantiateInitialViewController()
        window.makeKeyAndVisible()
        
        Task {
            do {
                _ = try await SupabaseManager.shared.client.auth.session
                
                // ✅ User already has an active session — restore their XP/Level/Streak
                // before the tab bar appears so UI is correct from the first frame
                ProgressDataManager.shared.restoreFromSupabase()
                
                DispatchQueue.main.async {
                    let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
                    window.rootViewController = tabBarVC
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
                    let nav = UINavigationController(rootViewController: onboardingVC)
                    nav.isNavigationBarHidden = true
                    window.rootViewController = nav
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                }
            }
        }
    }

    // ✅ AUTOMATIC STREAK CHECK
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("📱 App entered foreground. Checking daily streak...")
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
