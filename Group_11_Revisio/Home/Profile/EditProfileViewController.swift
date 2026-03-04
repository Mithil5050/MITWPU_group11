//
//  EditProfileViewController.swift
//  Group_11_Revisio
//

import UIKit
import Supabase

// MARK: - Protocol for passing data back
protocol EditProfileDelegate: AnyObject {
    func didUpdateProfile(name: String, image: UIImage?)
}

// ✅ Helper struct for updating the database
struct ProfileUpdateParams: Encodable {
    let username: String
    let avatar_url: String?
}

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - UI Components
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 50
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.image = UIImage(systemName: "person.fill")
        return iv
    }()

    private let changePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Change Photo", for: .normal)
        return button
    }()

    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.placeholder = "Enter your name"
        return tf
    }()

    // MARK: - Properties
    weak var delegate: EditProfileDelegate?
    var currentName: String?
    var currentImage: UIImage?
    
    // We use this to track if the user actually picked a new photo
    private var didChangePhoto = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupLayout()
        configureInitialData()
        
        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = "Edit Profile"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }

    private func setupLayout() {
        view.addSubview(profileImageView)
        view.addSubview(changePhotoButton)
        view.addSubview(nameTextField)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            changePhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            changePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nameTextField.topAnchor.constraint(equalTo: changePhotoButton.bottomAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func configureInitialData() {
        if let name = currentName { nameTextField.text = name }
        if let image = currentImage { profileImageView.image = image }
    }

    // MARK: - Actions
    @objc private func changePhotoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    // ✅ THE MAGIC HAPPENS HERE
    @objc private func saveTapped() {
        guard let newName = nameTextField.text, !newName.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Name cannot be empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Disable the save button so they don't spam it while uploading
        navigationItem.rightBarButtonItem?.isEnabled = false
        changePhotoButton.setTitle("Saving...", for: .normal)
        
        Task {
            do {
                // 1. Get the current user
                let user = try await supabase.auth.session.user
                let userId = user.id.uuidString
                var finalAvatarURL: String? = nil
                
                // 2. Did they pick a new photo? If so, upload it!
                if didChangePhoto, let imageToUpload = profileImageView.image,
                   let imageData = imageToUpload.jpegData(compressionQuality: 0.5) {
                    
                    let filePath = "\(userId).jpg"
                    
                    // Upload to Storage
                    try await supabase.storage
                        .from("avatars")
                        .upload(
                            path: filePath,
                            file: imageData,
                            options: FileOptions(contentType: "image/jpeg", upsert: true)
                        )
                    
                    // Get the public URL
                    finalAvatarURL = try supabase.storage.from("avatars").getPublicURL(path: filePath).absoluteString
                }
                
                // 3. Update the 'profiles' database table
                let updateData = ProfileUpdateParams(username: newName, avatar_url: finalAvatarURL)
                
                try await supabase
                    .from("profiles")
                    .update(updateData)
                    .eq("id", value: userId)
                    .execute()
                
                // 4. Success! Tell the Profile & Home screens to update
                DispatchQueue.main.async {
                    // ✅ Broadcast update to all listeners (Home & Profile ViewControllers)
                    NotificationCenter.default.post(name: NSNotification.Name("ProfileDidUpdate"), object: nil)
                    
                    self.delegate?.didUpdateProfile(name: newName, image: self.profileImageView.image)
                    self.dismiss(animated: true)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.changePhotoButton.setTitle("Change Photo", for: .normal)
                    let alert = UIAlertController(title: "Save Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
            didChangePhoto = true
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageView.image = originalImage
            didChangePhoto = true
        }
        picker.dismiss(animated: true)
    }
}
