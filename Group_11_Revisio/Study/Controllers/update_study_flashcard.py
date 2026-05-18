import re

with open("/Users/mithil/Desktop/MITWPU_group11/Group_11_Revisio/Study/Controllers/FlashcardsViewController.swift", "r") as f:
    code = f.read()

# Remove challenge mode switch from properties
code = re.sub(r'    private let challengeModeSwitch: UISwitch = \{.*?\n    \}\(\)\n\n    private let challengeModeLabel: UILabel = \{.*?\n    \}\(\)\n\n', '', code, flags=re.DOTALL)

# Add isChallengePhase
code = re.sub(r'(private var isTermDisplayed\s*=\s*true)', r'\1\n    private var isChallengePhase = false', code)

# Fix constraint setup
old_ui = r'''    private func setupProgrammaticUI\(\) \{
        view\.addSubview\(challengeModeSwitch\)
        view\.addSubview\(challengeModeLabel\)
        view\.addSubview\(challengeTextField\)
        
        NSLayoutConstraint\.activate\(\[
            cardsView\.heightAnchor\.constraint\(equalTo: view\.heightAnchor, multiplier: 0\.55\),
            challengeModeSwitch\.topAnchor\.constraint\(equalTo: cardsView\.bottomAnchor, constant: 40\),
            challengeModeSwitch\.centerXAnchor\.constraint\(equalTo: view\.centerXAnchor, constant: -60\),
            challengeModeLabel\.centerYAnchor\.constraint\(equalTo: challengeModeSwitch\.centerYAnchor\),
            challengeModeLabel\.leadingAnchor\.constraint\(equalTo: challengeModeSwitch\.trailingAnchor, constant: 10\),
            challengeTextField\.topAnchor\.constraint\(equalTo: challengeModeSwitch\.bottomAnchor, constant: 20\),
            challengeTextField\.centerXAnchor\.constraint\(equalTo: view\.centerXAnchor\),
            challengeTextField\.widthAnchor\.constraint\(equalToConstant: 250\),
            challengeTextField\.heightAnchor\.constraint\(equalToConstant: 44\)
        \]\)
    \}'''

new_ui = '''    private func setupProgrammaticUI() {
        view.addSubview(challengeTextField)
        NSLayoutConstraint.activate([
            cardsView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),
            challengeTextField.topAnchor.constraint(equalTo: cardsView.bottomAnchor, constant: 40),
            challengeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            challengeTextField.widthAnchor.constraint(equalToConstant: 250),
            challengeTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }'''
code = re.sub(old_ui, new_ui, code)

# Remove toggleChallengeMode
code = re.sub(r'    @objc private func toggleChallengeMode\(\) \{.*?\n    \}\n', '', code, flags=re.DOTALL)

# Update viewDidLoad
code = re.sub(r'        challengeModeSwitch\.addTarget\(self, action: #selector\(toggleChallengeMode\), for: \.valueChanged\)\n', '', code)

# Replace challengeModeSwitch.isOn with isChallengePhase
code = code.replace("challengeModeSwitch.isOn", "isChallengePhase")

# Update glow appearance in cardsView
old_app = r'''    private func configureCardViewAppearance\(\) \{
        cardsView\.layer\.cornerRadius = 16
        cardsView\.layer\.masksToBounds = false
        cardsView\.layer\.shadowColor = UIColor\.black\.cgColor
        cardsView\.layer\.shadowOpacity = 0\.1
        cardsView\.layer\.shadowOffset = CGSize\(width: 0, height: 4\)
        cardsView\.layer\.shadowRadius = 8
        cardsView\.backgroundColor = \.systemGray6
        cardsView\.layer\.borderWidth = 3\.0
        cardsView\.layer\.borderColor = UIColor\(red: 0\.57, green: 0\.76, blue: 0\.94, alpha: 1\.0\)\.cgColor
        cardsView\.layer\.zPosition = 100
    \}'''

new_app = '''    private func configureCardViewAppearance() {
        cardsView.layer.cornerRadius = 16
        cardsView.layer.masksToBounds = false
        cardsView.layer.shadowColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        cardsView.layer.shadowOpacity = 0.8
        cardsView.layer.shadowOffset = .zero
        cardsView.layer.shadowRadius = 15
        cardsView.backgroundColor = .systemGray6
        cardsView.layer.borderWidth = 3.0
        cardsView.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        cardsView.layer.zPosition = 100
    }'''
code = re.sub(old_app, new_app, code)

# Update bg card appearance
old_bg = r'''    private func createBackgroundCard\(\) -> UIView \{
        let v = UIView\(\)
        v\.backgroundColor = \.systemGray6
        v\.layer\.cornerRadius = 16
        v\.layer\.borderWidth = 3\.0
        v\.layer\.borderColor = UIColor\(red: 0\.57, green: 0\.76, blue: 0\.94, alpha: 1\.0\)\.cgColor
        v\.translatesAutoresizingMaskIntoConstraints = false
        return v
    \}'''
new_bg = '''    private func createBackgroundCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = false
        v.layer.shadowColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        v.layer.shadowOpacity = 0.8
        v.layer.shadowOffset = .zero
        v.layer.shadowRadius = 15
        v.layer.borderWidth = 3.0
        v.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }'''
code = re.sub(old_bg, new_bg, code)

# Update handlePan and finishSwipe
old_pan = r'''    @objc func handlePan\(_ sender: UIPanGestureRecognizer\) \{.*?    private func finishSwipe\(translationX: CGFloat\) \{.*?    \}'''

new_pan = '''    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard !flashcards.isEmpty, let card = sender.view else { return }
        if isChallengePhase && isTermDisplayed { return }
        
        let translation = sender.translation(in: view)
        switch sender.state {
        case .began: initialCardCenter = card.center
        case .changed:
            let rotation = (translation.x / view.bounds.width) * 0.4
            card.transform = CGAffineTransform(translationX: translation.x, y: translation.y).rotated(by: rotation)
            let isVertical = abs(translation.y) > abs(translation.x)
            if isVertical {
                card.layer.borderColor = translation.y < 0 ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor
            } else {
                card.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
            }
        case .ended:
            let isVertical = abs(translation.y) > abs(translation.x)
            if isVertical && abs(translation.y) > 150 {
                translation.y < 0 ? (knownCount += 1) : (unknownCount += 1)
                finishSwipe(translationX: 0, translationY: translation.y < 0 ? -view.bounds.height : view.bounds.height, isNext: true)
            } else if !isVertical && abs(translation.x) > 150 {
                if translation.x < 0 {
                    finishSwipe(translationX: -view.bounds.width, translationY: 0, isNext: true)
                } else {
                    if currentCardIndex > 0 {
                        finishSwipe(translationX: view.bounds.width, translationY: 0, isNext: false)
                    } else {
                        snapBack(card: card)
                    }
                }
            } else {
                snapBack(card: card)
            }
        default: break
        }
    }

    private func snapBack(card: UIView) {
        UIView.animate(withDuration: 0.3) {
            card.center = self.initialCardCenter
            card.transform = .identity
            card.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        }
    }

    private func finishSwipe(translationX: CGFloat, translationY: CGFloat, isNext: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            self.cardsView.transform = CGAffineTransform(translationX: translationX, y: translationY).rotated(by: translationX > 0 ? 0.3 : (translationX < 0 ? -0.3 : 0))
            self.cardsView.alpha = 0
            
            if isNext {
                self.backgroundCard1.transform = .identity
                self.backgroundCard2.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
            }
        }) { _ in
            self.cardsView.transform = .identity
            self.cardsView.alpha = 1.0
            self.cardsView.center = self.initialCardCenter
            self.configureCardViewAppearance()
            
            if isNext {
                if self.currentCardIndex < self.flashcards.count - 1 {
                    self.currentCardIndex += 1
                    self.isTermDisplayed = true
                    self.updateCardContent(animated: false)
                    self.resetStackTransforms()
                } else {
                    self.cardsView.isHidden = true
                    self.showResultsScreen()
                }
            } else {
                self.currentCardIndex -= 1
                self.isTermDisplayed = true
                self.updateCardContent(animated: false)
                self.resetStackTransforms()
            }
        }
    }'''
code = re.sub(old_pan, new_pan, code, flags=re.DOTALL)

# Replace showResultsOverlay
old_res = r'''    private func showResultsOverlay\(\) \{.*?    \}'''
new_res = '''    private func showResultsScreen() {
        let resultsVC = FlashcardResultsViewController()
        resultsVC.knownCount = knownCount
        resultsVC.unknownCount = unknownCount
        resultsVC.delegate = self
        resultsVC.modalPresentationStyle = .fullScreen
        present(resultsVC, animated: true)
    }'''
code = re.sub(old_res, new_res, code, flags=re.DOTALL)

# Remove resultsOverlay from properties
code = re.sub(r'    private let resultsOverlay = UIView\(\)\n', '', code)

# Make sure new classes are injected at the very bottom
delegate_code = '''
protocol FlashcardResultsDelegate: AnyObject {
    func didSelectChallengeMode()
    func didSelectSaveAndExit()
}

class FlashcardResultsViewController: UIViewController {
    var knownCount = 0
    var unknownCount = 0
    weak var delegate: FlashcardResultsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "Study Complete! 🎉"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        
        let knownLabel = UILabel()
        knownLabel.text = "✅ Known: \\(knownCount)"
        knownLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        knownLabel.textColor = .systemGreen
        
        let unknownLabel = UILabel()
        unknownLabel.text = "❌ Need Review: \\(unknownCount)"
        unknownLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        unknownLabel.textColor = .systemRed
        
        let challengeBtn = UIButton(type: .system)
        challengeBtn.setTitle("Enter Challenge Mode", for: .normal)
        challengeBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        challengeBtn.backgroundColor = .systemPurple
        challengeBtn.setTitleColor(.white, for: .normal)
        challengeBtn.layer.cornerRadius = 12
        challengeBtn.addTarget(self, action: #selector(challengeTapped), for: .touchUpInside)
        
        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("Save & Exit", for: .normal)
        saveBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveBtn.backgroundColor = .systemBlue
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.layer.cornerRadius = 12
        saveBtn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, knownLabel, unknownLabel, challengeBtn, saveBtn])
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            challengeBtn.widthAnchor.constraint(equalToConstant: 250),
            challengeBtn.heightAnchor.constraint(equalToConstant: 50),
            saveBtn.widthAnchor.constraint(equalToConstant: 250),
            saveBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func challengeTapped() {
        dismiss(animated: true) {
            self.delegate?.didSelectChallengeMode()
        }
    }
    
    @objc private func saveTapped() {
        dismiss(animated: true) {
            self.delegate?.didSelectSaveAndExit()
        }
    }
}

extension FlashcardsViewController: FlashcardResultsDelegate {
    func didSelectChallengeMode() {
        isChallengePhase = true
        let numCards = min(Int.random(in: 5...7), self.flashcards.count)
        guard numCards > 0 else { return }
        self.flashcards = Array(self.flashcards.shuffled().prefix(numCards))
        self.currentCardIndex = 0
        
        self.cardsView.isHidden = false
        self.challengeTextField.isHidden = false
        self.challengeTextField.text = ""
        self.isTermDisplayed = true
        self.updateCardContent(animated: false)
        self.resetStackTransforms()
        self.challengeTextField.becomeFirstResponder()
    }
    
    func didSelectSaveAndExit() {
        handleDone()
    }
}
'''
code += delegate_code

with open("/Users/mithil/Desktop/MITWPU_group11/Group_11_Revisio/Study/Controllers/FlashcardsViewController.swift", "w") as f:
    f.write(code)

