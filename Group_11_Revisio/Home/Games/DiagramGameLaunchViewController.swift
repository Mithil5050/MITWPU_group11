import UIKit

class DiagramGameLaunchViewController: UIViewController {
    
    private var selectedImage: UIImage?
    private var topicDropdownButton: UIButton?
    private var startButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for subview in view.subviews {
            if let btn = subview as? UIButton {
                if btn.configuration?.title == "Start" || btn.titleLabel?.text == "Start" {
                    startButton = btn
                } else if btn.configuration?.title == "Select Topic" || btn.titleLabel?.text == "Select Topic" {
                    topicDropdownButton = btn
                }
            }
        }
        
        if let topicBtn = topicDropdownButton, let startBtn = startButton {
            topicBtn.translatesAutoresizingMaskIntoConstraints = false
            startBtn.translatesAutoresizingMaskIntoConstraints = false
            
            view.removeConstraints(view.constraints.filter { 
                ($0.firstItem as? UIView == topicBtn) || ($0.secondItem as? UIView == topicBtn) ||
                ($0.firstItem as? UIView == startBtn) || ($0.secondItem as? UIView == startBtn)
            })
            topicBtn.removeConstraints(topicBtn.constraints)
            startBtn.removeConstraints(startBtn.constraints)
            
            NSLayoutConstraint.activate([
                startBtn.heightAnchor.constraint(equalToConstant: 52),
                startBtn.widthAnchor.constraint(equalToConstant: 353),
                startBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                startBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                
                topicBtn.heightAnchor.constraint(equalToConstant: 52),
                topicBtn.widthAnchor.constraint(equalToConstant: 353),
                topicBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                topicBtn.bottomAnchor.constraint(equalTo: startBtn.topAnchor, constant: -16)
            ])
        }
        
        setupDropdownMenu()
        startButton?.isEnabled = false
    }
    
    private func setupDropdownMenu() {
        var menuActions: [UIAction] = []
        
        let photoAction = UIAction(title: "Photo Library") { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }
        menuActions.append(photoAction)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAction(title: "Camera") { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            menuActions.append(cameraAction)
        }
        
        let demoAction = UIAction(title: "Use Demo Image") { [weak self] _ in
            self?.selectedImage = nil
            self?.topicDropdownButton?.setTitle("Use Demo Image", for: .normal)
            self?.startButton?.isEnabled = true
        }
        menuActions.append(demoAction)
        
        topicDropdownButton?.menu = UIMenu(title: "Choose Diagram", children: menuActions)
        topicDropdownButton?.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func StartButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "StartDiagramGame", sender: nil)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartDiagramGame",
           let destVC = segue.destination as? DiagramGameViewController {
            
            // Pass the dynamically selected image to the game
            destVC.diagramImageToPlay = selectedImage
            
//            // If they picked a topic, pass it to the game!
//            if let topic = sender as? Topic {
//                destVC.currentTopic = topic
//            }
        }
    }
}

// MARK: - Image Picker
extension DiagramGameLaunchViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.selectedImage = image
            self.startButton?.isEnabled = true
            self.topicDropdownButton?.setTitle("Image Selected", for: .normal)
            picker.dismiss(animated: true) {
                // Do not perform segue here automatically, let them click Start
            }
        } else {
            picker.dismiss(animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
