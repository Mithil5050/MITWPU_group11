import UIKit
import UniformTypeIdentifiers // Replaces MobileCoreServices in modern Swift
import PhotosUI

// Adopt all necessary protocols
class UploadContentViewController: UIViewController,
                                     UIDocumentPickerDelegate,
                                     UIImagePickerControllerDelegate,
                                   UINavigationControllerDelegate {
    
    // MARK: - Lifecycle Methods
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialization code here
    }
    
    @IBAction func doneButtontapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showUploadedContent", sender: sender)
    }
    // MARK: - 📄 Document Button Action (Files)
    
    @IBAction func documentButtonTapped(_ sender: UIButton) {
        // Define accepted document UTIs using the modern UniformTypeIdentifiers framework
        let supportedTypes: [UTType] = [
            .pdf,            // PDF documents
            .plainText,      // Plain text files
            .data,           // Generic data type (covers many file formats)
            .text            // General text format
        ]
        
        // Initialize with the array of UTTypes
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: - UIDocumentPickerDelegate Methods (Handles file selection result)
    
    // MARK: - UIDocumentPickerDelegate Methods (Handles file selection result)
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedURL = urls.first else { return }
            
            let didStartAccessing = selectedURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            }
            
            if didStartAccessing {
                let fileName = selectedURL.lastPathComponent // Extract the file name
                print("Selected document URL: \(selectedURL.absoluteString)")
                
                // 1. Dismiss the Document Picker first
                controller.dismiss(animated: true) { [weak self] in
                    
                    // 2. Instantiate the Confirmation View Controller
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let confirmationVC = storyboard.instantiateViewController(withIdentifier: "ConfirmationVC") as? UploadConfirmationViewController else {
                        return
                    }
                    
                    // 3. Pass the data to the new screen
                    confirmationVC.uploadedContentName = fileName
                    
                    // 4. Push the Confirmation VC onto the navigation stack
                    self?.navigationController?.pushViewController(confirmationVC, animated: true)
                }
            }
        }
        // ... rest of the code ...
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }
    
    // MARK: - 📸 Media Button Action (Photos/Videos)
    
    @IBAction func mediaButtonTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        
        picker.sourceType = .photoLibrary
        
        // Use UTType.identifier property for mediaTypes array
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    // MARK: - UIImagePickerControllerDelegate Methods
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            var contentName: String? = nil
            
            // Check for selected image
            if let _ = info[.originalImage] as? UIImage {
                contentName = "Selected Image"
            }
            
            // Check for selected video
            else if let mediaType = info[.mediaType] as? String, mediaType == UTType.movie.identifier,
                      let videoURL = info[.mediaURL] as? URL {
                contentName = videoURL.lastPathComponent // Use video file name
            }
            
            // Execute the navigation only if content was selected
            if let name = contentName {
                self?.navigateToConfirmation(with: name)
            }
        }
    }

    // Helper method to consolidate navigation logic (Highly recommended!)
    private func navigateToConfirmation(with contentName: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let confirmationVC = storyboard.instantiateViewController(withIdentifier: "ConfirmationVC") as? UploadConfirmationViewController else {
            print("Error: Could not instantiate ConfirmationVC.")
            return
        }
        
        confirmationVC.uploadedContentName = contentName
        self.navigationController?.pushViewController(confirmationVC, animated: true)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - 🔗 Link Button Action (Alert Input)
    
    @IBAction func linkButtonTapped(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: "Paste URL", message: "Enter or paste the link you want to share.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "https://example.com"
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
        }
        
//        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
//            guard let urlString = alertController.textFields?.first?.text, !urlString.isEmpty else { return }
//            
//            // Basic validation
//            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
//                print("Confirmed URL: \(urlString)")
//                // TO DO: Save and prepare link content for upload
//            } else {
//                self?.showInvalidLinkAlert()
//            }
//        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
                guard let urlString = alertController.textFields?.first?.text, !urlString.isEmpty else { return }
                
                // Basic validation
                if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                    print("Confirmed URL: \(urlString)")
                    // Call the shared navigation method
                    self?.navigateToConfirmation(with: urlString)
                } else {
                    self?.showInvalidLinkAlert()
                }
            }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func showInvalidLinkAlert() {
        let errorAlert = UIAlertController(title: "Invalid Link", message: "Please enter a valid URL (starting with http:// or https://).", preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
        present(errorAlert, animated: true)
    }
    
    // MARK: - 📝 Text Button Action (Dedicated Editor Screen)
    
    @IBAction func textButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add Text Content",
                                                message: "Enter or paste your text here. This alert is best for short notes.",
                                                preferredStyle: .alert)
        
        // Add the Text Field for single-line input
        alertController.addTextField { textField in
            textField.placeholder = "Start typing your note..."
            textField.keyboardType = .default
            textField.autocapitalizationType = .sentences // Recommended for text input
        }
        
        // Add "Confirm" Action
//        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
//            guard let textContent = alertController.textFields?.first?.text, !textContent.isEmpty else { return }
//            
//            print("Confirmed Text Content: \(textContent)")
//            // TO DO: Save the text content for upload
//        }
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
                guard let textContent = alertController.textFields?.first?.text, !textContent.isEmpty else { return }
                
                print("Confirmed Text Content: \(textContent)")
                // Pass a truncated version of the text as the name
                let preview = textContent.prefix(25) + (textContent.count > 25 ? "..." : "")
                self?.navigateToConfirmation(with: String(preview))
            }
        
        // Add "Cancel" Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}
