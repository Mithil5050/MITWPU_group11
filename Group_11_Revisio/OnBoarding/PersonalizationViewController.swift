import UIKit

class PersonalizationViewController: UIViewController {

    private let backgroundView = GradientViews()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personalize Your Experience"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tell us a bit about yourself so we can tailor the AI for you."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(white: 1.0, alpha: 0.7)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        return sv
    }()

    private var step = 1
    private var selectedCategory = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showCategoryOptions()
    }

    private func setupUI() {
        view.addSubview(backgroundView)
        backgroundView.frame = view.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func showCategoryOptions() {
        step = 1
        UIView.animate(withDuration: 0.3) {
            self.scrollView.alpha = 0
        } completion: { _ in
            self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            self.titleLabel.text = "What best describes you?"
            self.subtitleLabel.text = "This helps us personalize your AI study companion."

            let options = [
                ("🏫 School Student", "School"),
                ("🎓 College Student", "College"),
                ("📚 Preparing for Entrance Exam", "Entrance Exam")
            ]

            for (title, value) in options {
                let btn = self.createOptionButton(title: title)
                btn.addAction(UIAction { [weak self] _ in
                    self?.selectedCategory = value
                    self?.showSubCategoryOptions()
                }, for: .touchUpInside)
                self.stackView.addArrangedSubview(btn)
            }

            UIView.animate(withDuration: 0.3) {
                self.scrollView.alpha = 1
            }
        }
    }

    private func showSubCategoryOptions() {
        step = 2
        UIView.animate(withDuration: 0.3) {
            self.scrollView.alpha = 0
        } completion: { _ in
            self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            var options: [String] = []

            if self.selectedCategory == "School" {
                self.titleLabel.text = "Which grade are you in?"
                options = ["Middle School (6-8)", "High School (9-10)", "Senior Secondary (11-12)"]
            } else if self.selectedCategory == "College" {
                self.titleLabel.text = "What is your major?"
                options = ["Engineering", "Medical", "Arts & Humanities", "Commerce & Business", "Science", "Other"]
            } else {
                self.titleLabel.text = "Which exam?"
                options = ["JEE", "NEET", "UPSC", "CAT", "SAT/GRE", "Other"]
            }
            self.subtitleLabel.text = "Select one to continue."

            for title in options {
                let btn = self.createOptionButton(title: title)
                btn.addAction(UIAction { [weak self] _ in
                    self?.finishPersonalization(subCategory: title)
                }, for: .touchUpInside)
                self.stackView.addArrangedSubview(btn)
            }

            let backBtn = UIButton(type: .system)
            backBtn.setTitle("← Back", for: .normal)
            backBtn.setTitleColor(UIColor(white: 1.0, alpha: 0.7), for: .normal)
            backBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            backBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
            backBtn.addAction(UIAction { [weak self] _ in
                self?.showCategoryOptions()
            }, for: .touchUpInside)
            self.stackView.addArrangedSubview(backBtn)

            UIView.animate(withDuration: 0.3) {
                self.scrollView.alpha = 1
            }
        }
    }

    private func createOptionButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = UIColor(red: 40/255, green: 44/255, blue: 55/255, alpha: 0.85)
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        btn.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return btn
    }

    private func finishPersonalization(subCategory: String) {
        UserDefaults.standard.set(selectedCategory, forKey: "user_category")
        UserDefaults.standard.set(subCategory, forKey: "user_subcategory")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
        navigationController?.setViewControllers([loginVC], animated: true)
    }
}
