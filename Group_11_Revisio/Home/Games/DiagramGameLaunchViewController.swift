import UIKit

class DiagramGameLaunchViewController: UIViewController {

    private let mascotImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let topicDropdownButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)
    private let instructionsCard = UIView()

    private var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupUIElements()
        setupConstraints()
        setupDropdownMenu()

        // Hide any leftover storyboard elements
        view.subviews.forEach {
            if $0 != mascotImageView && $0 != titleLabel && $0 != subtitleLabel &&
               $0 != topicDropdownButton && $0 != startButton && $0 != instructionsCard &&
               !($0 is UIImageView && $0.tag == 100) {
                $0.isHidden = true
            }
        }
    }

    private func setupBackground() {
        view.backgroundColor = .black

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0).cgColor
        ]
        gradientLayer.frame = view.bounds
        let gradientView = UIView(frame: view.bounds)
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        gradientView.tag = 100
        view.insertSubview(gradientView, at: 0)
    }

    private func setupUIElements() {
        // Mascot
        mascotImageView.image = UIImage(named: "Diagram_dash")
        mascotImageView.contentMode = .scaleAspectFit
        mascotImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mascotImageView)

        // Header
        titleLabel.text = "Diagram Dash"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        subtitleLabel.text = "Label the components of your\ndiagrams and flowcharts"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // Topic/Image Dropdown
        topicDropdownButton.setTitle("Choose Diagram Source", for: .normal)
        topicDropdownButton.setImage(UIImage(systemName: "photo.on.rectangle.angled"), for: .normal)
        topicDropdownButton.tintColor = .white
        topicDropdownButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        topicDropdownButton.layer.cornerRadius = 16
        topicDropdownButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        topicDropdownButton.semanticContentAttribute = .forceLeftToRight
        var dropdownConfig = topicDropdownButton.configuration ?? UIButton.Configuration.plain()
        dropdownConfig.imagePadding = 8
        topicDropdownButton.configuration = dropdownConfig
        topicDropdownButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topicDropdownButton)

        // Start Button
        startButton.setTitle("Play Now", for: .normal)
        startButton.backgroundColor = UIColor(red: 0.39, green: 0.4, blue: 0.94, alpha: 1.0)
        startButton.tintColor = .white
        startButton.layer.cornerRadius = 16
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        startButton.isEnabled = false
        startButton.alpha = 0.5
        startButton.addTarget(self, action: #selector(StartButtonTapped), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)

        // XP Badge on Start Button
        let xpLabel = UILabel()
        xpLabel.text = " +15 XP "
        xpLabel.font = .systemFont(ofSize: 12, weight: .black)
        xpLabel.textColor = .white
        xpLabel.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        xpLabel.layer.cornerRadius = 6
        xpLabel.clipsToBounds = true
        xpLabel.translatesAutoresizingMaskIntoConstraints = false
        startButton.addSubview(xpLabel)

        NSLayoutConstraint.activate([
            xpLabel.trailingAnchor.constraint(equalTo: startButton.trailingAnchor, constant: -16),
            xpLabel.centerYAnchor.constraint(equalTo: startButton.centerYAnchor),
            xpLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        // Instructions Card
        instructionsCard.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        instructionsCard.layer.cornerRadius = 16
        instructionsCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionsCard)

        let instIcon = UIImageView(image: UIImage(systemName: "lightbulb.fill"))
        instIcon.tintColor = .systemYellow
        instIcon.contentMode = .scaleAspectFit
        instIcon.translatesAutoresizingMaskIntoConstraints = false
        instructionsCard.addSubview(instIcon)

        let instLabel = UILabel()
        instLabel.text = "Insert the correct labels to complete the diagram!"
        instLabel.font = .systemFont(ofSize: 13, weight: .regular)
        instLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        instLabel.numberOfLines = 0
        instLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionsCard.addSubview(instLabel)

        NSLayoutConstraint.activate([
            instIcon.leadingAnchor.constraint(equalTo: instructionsCard.leadingAnchor, constant: 16),
            instIcon.centerYAnchor.constraint(equalTo: instructionsCard.centerYAnchor),
            instIcon.widthAnchor.constraint(equalToConstant: 20),
            instIcon.heightAnchor.constraint(equalToConstant: 20),

            instLabel.leadingAnchor.constraint(equalTo: instIcon.trailingAnchor, constant: 12),
            instLabel.trailingAnchor.constraint(equalTo: instructionsCard.trailingAnchor, constant: -16),
            instLabel.topAnchor.constraint(equalTo: instructionsCard.topAnchor, constant: 12),
            instLabel.bottomAnchor.constraint(equalTo: instructionsCard.bottomAnchor, constant: -12)
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            mascotImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            mascotImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mascotImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25),

            titleLabel.topAnchor.constraint(equalTo: mascotImageView.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.heightAnchor.constraint(equalToConstant: 56),

            topicDropdownButton.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -16),
            topicDropdownButton.leadingAnchor.constraint(equalTo: startButton.leadingAnchor),
            topicDropdownButton.trailingAnchor.constraint(equalTo: startButton.trailingAnchor),
            topicDropdownButton.heightAnchor.constraint(equalToConstant: 56),

            instructionsCard.bottomAnchor.constraint(equalTo: topicDropdownButton.topAnchor, constant: -24),
            instructionsCard.leadingAnchor.constraint(equalTo: startButton.leadingAnchor),
            instructionsCard.trailingAnchor.constraint(equalTo: startButton.trailingAnchor)
        ])
    }

    private func setupDropdownMenu() {
        var menuActions: [UIAction] = []

        let photoAction = UIAction(title: "Photo Library", image: UIImage(systemName: "photo.on.rectangle")) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }
        menuActions.append(photoAction)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAction(title: "Camera", image: UIImage(systemName: "camera")) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            menuActions.append(cameraAction)
        }

        let demoAction = UIAction(title: "Use Demo Image", image: UIImage(systemName: "sparkles")) { [weak self] _ in
            self?.selectedImage = nil
            self?.topicDropdownButton.setTitle("Use Demo Image", for: .normal)
            self?.topicDropdownButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            self?.topicDropdownButton.tintColor = .systemGreen
            self?.enableStartButton()
        }
        menuActions.append(demoAction)

        topicDropdownButton.menu = UIMenu(title: "Choose Diagram", children: menuActions)
        topicDropdownButton.showsMenuAsPrimaryAction = true
    }

    private func enableStartButton() {
        UIView.animate(withDuration: 0.3) {
            self.startButton.isEnabled = true
            self.startButton.alpha = 1.0
            self.startButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.startButton.transform = .identity
            }
        }
    }

    @objc func StartButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        performSegue(withIdentifier: "StartDiagramGame", sender: nil)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartDiagramGame",
           let destVC = segue.destination as? DiagramGameViewController {
            destVC.diagramImageToPlay = selectedImage
        }
    }
}

extension DiagramGameLaunchViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.selectedImage = image
            self.topicDropdownButton.setTitle("Image Selected", for: .normal)
            self.topicDropdownButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            self.topicDropdownButton.tintColor = .systemGreen
            self.enableStartButton()
            picker.dismiss(animated: true)
        } else {
            picker.dismiss(animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
