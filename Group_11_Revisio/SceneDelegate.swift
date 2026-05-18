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
        window.overrideUserInterfaceStyle = .dark
        self.window = window

        // Show animated splash immediately
        let splash = SplashViewController()
        window.rootViewController = splash
        window.makeKeyAndVisible()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        // Minimum splash display time (seconds)
        let minimumSplashDuration: TimeInterval = 2.8

        Task {
            // Run auth check and minimum timer in parallel
            async let authResult: Bool = {
                do {
                    _ = try await SupabaseManager.shared.client.auth.session
                    ProgressDataManager.shared.restoreFromSupabase()
                    return true   // logged in
                } catch {
                    return false  // not logged in
                }
            }()

            async let timerDone: Void = {
                try? await Task.sleep(nanoseconds: UInt64(minimumSplashDuration * 1_000_000_000))
            }()

            // Wait for BOTH to finish before we transition
            let (isLoggedIn, _) = await (authResult, timerDone)

            DispatchQueue.main.async {
                splash.stopPlayback()

                if isLoggedIn {
                    let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
                    window.rootViewController = tabBarVC
                } else {
                    let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
                    let nav = UINavigationController(rootViewController: onboardingVC)
                    nav.isNavigationBarHidden = true
                    window.rootViewController = nav
                }

                UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil, completion: nil)
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
