import UIKit

final class LearnMoreViewController: UIViewController {

    private let word: String
    private let definition: String
    private let didWin: Bool

    // MARK: - Init
    init(word: String, definition: String, didWin: Bool = true) {
        self.word = word
        self.definition = definition
        self.didWin = didWin
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI
    private let backgroundView     = GradientViews()
    private let mascotView         = UIImageView()
    private let glowView           = UIView()
    private let resultBadge        = UILabel()
    private let wordLabel          = UILabel()
    private let subtitleLabel      = UILabel()
    private let defCard            = UIView()
    private let defTitleLabel      = UILabel()
    private let defBodyLabel       = UILabel()
    private let doneButton         = UIButton(type: .system)
    private let xpBadge            = UIView()
    private let xpLabel            = UILabel()
    private var emitterLayer: CAEmitterLayer?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
        if didWin { launchConfetti() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundView.frame = view.bounds
        emitterLayer?.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitterLayer?.emitterSize     = CGSize(width: view.bounds.width, height: 1)
        // Glow circle behind mascot
        let glowSize: CGFloat = 180
        glowView.frame = CGRect(
            x: view.bounds.midX - glowSize / 2,
            y: mascotView.frame.midY - glowSize / 2,
            width: glowSize, height: glowSize
        )
        glowView.layer.cornerRadius = glowSize / 2
    }

    // MARK: - Build UI
    private func buildUI() {
        // ── Gradient background ──────────────────────────────────────────
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)

        // ── Glow blob behind mascot ───────────────────────────────────────
        glowView.backgroundColor = didWin
            ? UIColor.systemBlue.withAlphaComponent(0.25)
            : UIColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 0.18)
        glowView.layer.shadowColor   = UIColor.systemBlue.cgColor
        glowView.layer.shadowRadius  = 40
        glowView.layer.shadowOpacity = 0.6
        glowView.layer.shadowOffset  = .zero
        view.addSubview(glowView)

        // ── Mascot ────────────────────────────────────────────────────────
        mascotView.image       = UIImage(named: "bot_pencil")
        mascotView.contentMode = .scaleAspectFit
        mascotView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mascotView)

        // ── XP badge (win only) ───────────────────────────────────────────
        xpBadge.backgroundColor  = .systemBlue
        xpBadge.layer.cornerRadius = 14
        xpBadge.translatesAutoresizingMaskIntoConstraints = false
        xpBadge.isHidden = !didWin

        xpLabel.text      = "+15 XP"
        xpLabel.font      = .systemFont(ofSize: 13, weight: .bold)
        xpLabel.textColor = .white
        xpLabel.translatesAutoresizingMaskIntoConstraints = false
        xpBadge.addSubview(xpLabel)
        view.addSubview(xpBadge)

        // ── Result badge ──────────────────────────────────────────────────
        resultBadge.text            = didWin ? "🎉  Correct!" : "😅  Nice Try!"
        resultBadge.font            = .systemFont(ofSize: 17, weight: .semibold)
        resultBadge.textColor       = .white.withAlphaComponent(0.9)
        resultBadge.textAlignment   = .center
        resultBadge.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        resultBadge.layer.cornerRadius = 16
        resultBadge.clipsToBounds   = true
        resultBadge.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultBadge)

        // ── Word (big) ────────────────────────────────────────────────────
        wordLabel.text                 = word.uppercased()
        wordLabel.font                 = .systemFont(ofSize: 52, weight: .heavy)
        wordLabel.textColor            = .white
        wordLabel.textAlignment        = .center
        wordLabel.adjustsFontSizeToFitWidth = true
        wordLabel.minimumScaleFactor   = 0.5
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wordLabel)

        // ── Subtitle ──────────────────────────────────────────────────────
        subtitleLabel.text          = didWin ? "Today's word was" : "The answer was"
        subtitleLabel.font          = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor     = .white.withAlphaComponent(0.5)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // ── Definition card ───────────────────────────────────────────────
        defCard.backgroundColor    = UIColor(red: 40/255, green: 44/255, blue: 55/255, alpha: 0.85)
        defCard.layer.cornerRadius = 22
        defCard.layer.cornerCurve  = .continuous
        defCard.layer.borderColor  = UIColor.white.withAlphaComponent(0.1).cgColor
        defCard.layer.borderWidth  = 1
        defCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(defCard)

        defTitleLabel.text          = "DEFINITION"
        defTitleLabel.font          = .systemFont(ofSize: 11, weight: .semibold)
        defTitleLabel.textColor     = .white.withAlphaComponent(0.4)
        defTitleLabel.textAlignment = .center
        defTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        defCard.addSubview(defTitleLabel)

        defBodyLabel.text          = definition
        defBodyLabel.font          = .systemFont(ofSize: 16, weight: .regular)
        defBodyLabel.textColor     = .white.withAlphaComponent(0.85)
        defBodyLabel.textAlignment = .center
        defBodyLabel.numberOfLines = 0
        defBodyLabel.translatesAutoresizingMaskIntoConstraints = false
        defCard.addSubview(defBodyLabel)

        // ── Done button ───────────────────────────────────────────────────
        var config = UIButton.Configuration.filled()
        config.title              = didWin ? "Awesome! 🙌" : "See You Tomorrow"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle        = .capsule
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            return out
        }
        doneButton.configuration = config
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
        // Lift shadow
        doneButton.layer.shadowColor   = UIColor.systemBlue.cgColor
        doneButton.layer.shadowOpacity = 0.55
        doneButton.layer.shadowRadius  = 14
        doneButton.layer.shadowOffset  = CGSize(width: 0, height: 6)
        view.addSubview(doneButton)

        // ── Constraints ───────────────────────────────────────────────────
        NSLayoutConstraint.activate([
            // Mascot
            mascotView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mascotView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            mascotView.widthAnchor.constraint(equalToConstant: 150),
            mascotView.heightAnchor.constraint(equalToConstant: 150),

            // XP badge (top-right of mascot)
            xpBadge.trailingAnchor.constraint(equalTo: mascotView.trailingAnchor, constant: 10),
            xpBadge.topAnchor.constraint(equalTo: mascotView.topAnchor, constant: 10),
            xpBadge.heightAnchor.constraint(equalToConstant: 28),
            xpLabel.leadingAnchor.constraint(equalTo: xpBadge.leadingAnchor, constant: 10),
            xpLabel.trailingAnchor.constraint(equalTo: xpBadge.trailingAnchor, constant: -10),
            xpLabel.centerYAnchor.constraint(equalTo: xpBadge.centerYAnchor),

            // Result badge
            resultBadge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultBadge.topAnchor.constraint(equalTo: mascotView.bottomAnchor, constant: 20),
            resultBadge.heightAnchor.constraint(equalToConstant: 40),
            resultBadge.widthAnchor.constraint(equalToConstant: 160),

            // Subtitle (above word)
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: resultBadge.bottomAnchor, constant: 28),

            // Word
            wordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wordLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 6),
            wordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            wordLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Definition card
            defCard.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 30),
            defCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            defCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            defTitleLabel.topAnchor.constraint(equalTo: defCard.topAnchor, constant: 20),
            defTitleLabel.centerXAnchor.constraint(equalTo: defCard.centerXAnchor),

            defBodyLabel.topAnchor.constraint(equalTo: defTitleLabel.bottomAnchor, constant: 10),
            defBodyLabel.leadingAnchor.constraint(equalTo: defCard.leadingAnchor, constant: 20),
            defBodyLabel.trailingAnchor.constraint(equalTo: defCard.trailingAnchor, constant: -20),
            defBodyLabel.bottomAnchor.constraint(equalTo: defCard.bottomAnchor, constant: -20),

            // Done button
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            doneButton.heightAnchor.constraint(equalToConstant: 58),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        // Initial state for animation
        [mascotView, glowView, xpBadge, resultBadge, subtitleLabel, wordLabel, defCard, doneButton].forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: 0, y: 30)
        }
    }

    // MARK: - Animate in (staggered)
    private func animateIn() {
        let items: [UIView] = [mascotView, resultBadge, subtitleLabel, wordLabel, defCard, doneButton]
        for (i, item) in items.enumerated() {
            UIView.animate(
                withDuration: 0.55,
                delay: Double(i) * 0.08,
                usingSpringWithDamping: 0.78,
                initialSpringVelocity: 0.4,
                options: .curveEaseOut
            ) {
                item.alpha = 1
                item.transform = .identity
            }
        }
        // Glow fades in slightly later
        UIView.animate(withDuration: 0.6, delay: 0.1) {
            self.glowView.alpha = 1
            self.glowView.transform = .identity
        }
        if didWin {
            UIView.animate(withDuration: 0.5, delay: 0.35) {
                self.xpBadge.alpha = 1
                self.xpBadge.transform = .identity
            }
        }
        // Mascot float
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(
                withDuration: 1.6,
                delay: 0,
                options: [.repeat, .autoreverse, .allowUserInteraction]
            ) {
                self.mascotView.transform = CGAffineTransform(translationX: 0, y: -10)
            }
        }
    }

    // MARK: - Confetti
    private func launchConfetti() {
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .line
        view.layer.addSublayer(emitter)
        emitterLayer = emitter

        let colors: [UIColor] = [
            .systemYellow, .systemPink, .systemCyan,
            .systemBlue,
            .systemGreen, .white, .systemOrange
        ]
        emitter.emitterCells = colors.map { color in
            let cell            = CAEmitterCell()
            cell.birthRate      = 7
            cell.lifetime       = 5.5
            cell.velocity       = 260
            cell.velocityRange  = 100
            cell.emissionRange  = .pi / 5
            cell.spin           = 4
            cell.spinRange      = 8
            cell.scale          = 0.07
            cell.scaleRange     = 0.04
            cell.color          = color.cgColor
            cell.contents       = confettiImage(color: color)
            return cell
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            emitter.birthRate = 0
        }
    }

    private func confettiImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 10, height: 6)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()?.cgImage
    }

    // MARK: - Action
    @objc private func handleDone() {
        dismiss(animated: true) {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}
