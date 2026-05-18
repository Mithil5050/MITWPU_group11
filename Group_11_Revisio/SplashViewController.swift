//
//  SplashViewController.swift
//  Group_11_Revisio
//
//  Gizmo-style animated splash screen.
//  Mascot pops in with a spring, title fades in below, then SceneDelegate
//  replaces the root after auth resolves.
//

import UIKit

final class SplashViewController: UIViewController {

    // MARK: - UI

    private let mascotImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bot_pencil"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        // Start scaled to zero — will spring into place
        iv.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        iv.alpha = 0
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "ReviseQ"
        l.font = UIFont.systemFont(ofSize: 42, weight: .heavy)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.alpha = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Minutes to Mastery"
        l.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.55)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.alpha = 0
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 12/255, alpha: 1)
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runAnimation()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(mascotImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            // Mascot — centred, slightly above mid-screen
            mascotImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mascotImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -70),
            mascotImageView.widthAnchor.constraint(equalToConstant: 200),
            mascotImageView.heightAnchor.constraint(equalToConstant: 200),

            // App title
            titleLabel.topAnchor.constraint(equalTo: mascotImageView.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Tagline
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Animation

    private func runAnimation() {
        // Step 1 — Mascot springs in (scale 0 → 1.12 → 1.0)
        UIView.animate(
            withDuration: 0.55,
            delay: 0.0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut],
            animations: {
                self.mascotImageView.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
                self.mascotImageView.alpha = 1
            },
            completion: { _ in
                UIView.animate(withDuration: 0.18) {
                    self.mascotImageView.transform = .identity
                }
            }
        )

        // Step 2 — Title pops / fades in slightly after mascot
        UIView.animate(
            withDuration: 0.4,
            delay: 0.3,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [],
            animations: {
                self.titleLabel.alpha = 1
                self.titleLabel.transform = .identity
            }
        )

        // Step 3 — Subtitle fades in last
        UIView.animate(
            withDuration: 0.35,
            delay: 0.5,
            options: [.curveEaseIn],
            animations: {
                self.subtitleLabel.alpha = 1
            }
        )
    }

    // MARK: - Called by SceneDelegate when auth resolves

    /// Call this before replacing the rootViewController.
    /// It fades everything out gracefully so the cross-dissolve
    /// from SceneDelegate feels seamless.
    func stopPlayback() {
        // No video to stop — just a lightweight fade-out so the
        // SceneDelegate cross-dissolve doesn't look jarring.
        UIView.animate(withDuration: 0.15) {
            self.view.alpha = 0.85
        }
    }
}
