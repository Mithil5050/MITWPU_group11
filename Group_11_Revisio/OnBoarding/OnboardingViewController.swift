//
//  OnboardingViewController.swift
//  App_Onboarding
//
//  Created by Chirag Poojari on 02/02/26.
//

import UIKit

class OnboardingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        moveToOnboardingPage1()
    }
    
    private func moveToOnboardingPage1() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "OnboardingPage1VC")
            vc.modalPresentationStyle = .fullScreen
            self.navigationController?.pushViewController(vc, animated: true)        }
    }
    
}


