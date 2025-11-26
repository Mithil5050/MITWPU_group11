//
//  UploadConfirmationViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import UIKit

class UploadConfirmationViewController: UIViewController {
    
    
    // This property will be set by UploadContentViewController before navigation.
    var uploadedContentName: String?
    
    // Simple UI to display the uploaded content name.
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Upload Confirmation"
        
        setupUI()
        updateUI()
    }
    
    // Matches the storyboard connection "DoneTapped:"
    @IBAction func DoneTapped(_ sender: Any) {
        // Validate that we actually have a name to proceed with
        if uploadedContentName == nil || uploadedContentName?.isEmpty == true {
            let alert = UIAlertController(title: "No Content", message: "Please add a source before continuing.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Trigger the segue using the identifier set in the Storyboard
        performSegue(withIdentifier: "showGenerationScreen", sender: self)
    }
    
    private func setupUI() {
        view.addSubview(nameLabel)
        
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            nameLabel.centerYAnchor.constraint(equalTo: guide.centerYAnchor)
        ])
    }
    
    private func updateUI() {
        if let name = uploadedContentName, !name.isEmpty {
            nameLabel.text = "Uploaded: \(name)"
        } else {
            nameLabel.text = "No content name provided."
        }
    }
}
    /*
//    // MARK: - Navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Pass data to next screen if needed.
//    }
//    */


//import UIKit
//
//class UploadConfirmationViewController: UIViewController {
//    
//    // MARK: - Data Model
//    
//    // Property to receive the name of the content that was just uploaded
//    var uploadedContentName: String?
//    
//    // MARK: - UI Elements (Connect these as IBOutlets in Storyboard if you use them)
//    
//    // Example: A label to show the confirmation status
//    let statusLabel = UILabel()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // 1. Configure the Navigation Bar
//        self.title = "Success" // A concise, clear title
//        
//        // 2. Set up the Done button (standard iOS aesthetic)
//        // If you used a Bar Button Item in Storyboard, connect its action to 'doneButtonTapped'
//        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
//        self.navigationItem.rightBarButtonItem = doneButton
//        
//        // 3. Setup the visual confirmation elements
//        setupConfirmationUI()
//    }
//    
//    func setupConfirmationUI() {
//        // --- iOS 26 HIG Recommendation: Use a large checkmark icon ---
//        
//        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
//        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
//        checkmarkImageView.tintColor = .systemGreen // Standard success color
//        checkmarkImageView.preferredSymbolConfiguration = .init(pointSize: 80)
//        
//        statusLabel.translatesAutoresizingMaskIntoConstraints = false
//        statusLabel.font = UIFont.preferredFont(forTextStyle: .title2)
//        statusLabel.textAlignment = .center
//        statusLabel.numberOfLines = 0
//        
//        // Display the uploaded content name
//        statusLabel.text = "Successfully added: \n\(uploadedContentName ?? "Content")"
//        
//        view.addSubview(checkmarkImageView)
//        view.addSubview(statusLabel)
//        
//        // Auto Layout constraints to center the elements
//        NSLayoutConstraint.activate([
//            // Center the checkmark
//            checkmarkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            checkmarkImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
//            
//            // Position the status label below the checkmark
//            statusLabel.topAnchor.constraint(equalTo: checkmarkImageView.bottomAnchor, constant: 20),
//            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
//            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
//        ])
//    }
//    
//    // MARK: - Dismissal Logic
//    
//    @objc func doneButtonTapped() {
//        self.navigationController?.popToRootViewController(animated: true)
//    }
//}
