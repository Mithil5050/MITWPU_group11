//
//  DiagramGameLaunchViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 20/03/26.
//


import UIKit

class DiagramGameLaunchViewController: UIViewController {
    
    private var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func StartButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose Diagram", message: "Upload a diagram from your photos or take a picture.", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        })
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Use Demo Image", style: .default) { _ in
            self.selectedImage = nil
            self.performSegue(withIdentifier: "StartDiagramGame", sender: nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        
        present(alert, animated: true)
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
            picker.dismiss(animated: true) {
                self.performSegue(withIdentifier: "StartDiagramGame", sender: nil)
            }
        } else {
            picker.dismiss(animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
