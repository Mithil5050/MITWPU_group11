//
//  BadgeDetailViewController.swift
//  Group_11_Revisio
//

import UIKit

class BadgeDetailViewController: UIViewController {

    var badge: Badging.Badge?

    private let largeBadgeImageView = UIImageView()
    private let challengeTitleLabel = UILabel()
    private let challengeDescriptionLabel = UILabel()
    private let challengeProgressView = UIProgressView(progressViewStyle: .default)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        populateData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Spring animation when the badge image appears (UI Polish)
        largeBadgeImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        largeBadgeImageView.alpha = 0
        
        UIView.animate(withDuration: 0.8,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
            self.largeBadgeImageView.transform = .identity
            self.largeBadgeImageView.alpha = 1
        }, completion: nil)
    }

    private func setupUI() {
        // Setup Views
        largeBadgeImageView.contentMode = .scaleAspectFit
        largeBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        
        challengeTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        challengeTitleLabel.textColor = .label
        challengeTitleLabel.textAlignment = .center
        challengeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        challengeDescriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        challengeDescriptionLabel.textColor = .secondaryLabel
        challengeDescriptionLabel.textAlignment = .center
        challengeDescriptionLabel.numberOfLines = 0
        challengeDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        challengeProgressView.trackTintColor = .systemGray5
        challengeProgressView.transform = challengeProgressView.transform.scaledBy(x: 1, y: 2.0)
        challengeProgressView.layer.cornerRadius = 4
        challengeProgressView.clipsToBounds = true
        challengeProgressView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(largeBadgeImageView)
        view.addSubview(challengeTitleLabel)
        view.addSubview(challengeDescriptionLabel)
        view.addSubview(challengeProgressView)
        
        NSLayoutConstraint.activate([
            challengeTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            challengeTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            challengeTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            challengeDescriptionLabel.topAnchor.constraint(equalTo: challengeTitleLabel.bottomAnchor, constant: 16),
            challengeDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            challengeDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            challengeProgressView.topAnchor.constraint(equalTo: challengeDescriptionLabel.bottomAnchor, constant: 32),
            challengeProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            challengeProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            challengeProgressView.heightAnchor.constraint(equalToConstant: 4),
            
            largeBadgeImageView.topAnchor.constraint(equalTo: challengeProgressView.bottomAnchor, constant: 40),
            largeBadgeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            largeBadgeImageView.widthAnchor.constraint(equalToConstant: 300),
            largeBadgeImageView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    private func populateData() {
        guard let badge = badge else { return }
        
        challengeTitleLabel.text = badge.title
        
        if let imageName = Badging.imageName(for: badge) {
            largeBadgeImageView.image = UIImage(named: imageName)
        }
        
        challengeDescriptionLabel.text = badge.displayDescription
        
        let completed = badge.isEarned
        challengeProgressView.progressTintColor = completed ? .systemGreen : .systemBlue
        
        // Progress animation
        challengeProgressView.setProgress(0, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut) {
                self.challengeProgressView.setProgress(badge.progress, animated: true)
            }
        }
        
        // Slightly dim unearned badges
        if !completed {
            largeBadgeImageView.alpha = 0.5
        }
    }
}
