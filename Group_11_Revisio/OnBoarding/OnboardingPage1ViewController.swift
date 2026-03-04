//
//  OnboardingPage1ViewController.swift
//  App_Onboarding
//
//  Created by Chirag Poojari on 03/02/26.
//

import UIKit

class OnboardingPage1ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    // MARK: - Data Model
    private struct OnboardingPage {
        let imageName: String
        let title: String
        let subtitle: String
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "bot_pencil",
            title: "Learn Smarter with AI",
            subtitle: "Generate quick, personalized quizzes and flashcards."
        ),
        OnboardingPage(
            imageName: "bot_find",
            title: "Track your Progress",
            subtitle: "Stay motivated and keep moving toward your goals."
        ),
        OnboardingPage(
            imageName: "bot_phone",
            title: "Connect and Study",
            subtitle: "Join groups, share resources, and learn collaboratively."
        )
    ]

    private var currentPageIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0

        updateUI(for: 0)
    }

    // MARK: - UI Update
    private func updateUI(for index: Int) {
        let page = pages[index]

        heroImageView.image = UIImage(named: page.imageName)
        titleLabel.text = page.title
        subtitleLabel.text = page.subtitle
        pageControl.currentPage = index

        if index == 0 {
            actionButton.setTitle("Get Started", for: .normal)
        } else if index == pages.count - 1 {
            actionButton.setTitle("Continue", for: .normal)
        } else {
            actionButton.setTitle("Next", for: .normal)
        }
        
        skipButton.isHidden = (index == pages.count - 1)
    }
    
    private func goToLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let loginVC = storyboard.instantiateViewController(
            withIdentifier: "LoginViewController"
        ) as? LoginViewController else {
            return
        }

        // Prevent back navigation to onboarding
        navigationController?.setViewControllers([loginVC], animated: true)
    }
    

    // MARK: - Actions
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        if currentPageIndex < pages.count - 1 {
                currentPageIndex += 1
                updateUI(for: currentPageIndex)
            } else {
                goToLogin()
            }
    }

    @IBAction func skipTapped(_ sender: UIButton) {
        goToLogin()
    }
    
    @IBAction func pageControlChanged(_ sender: UIPageControl) {
        currentPageIndex = sender.currentPage
        updateUI(for: currentPageIndex)
    }
}
