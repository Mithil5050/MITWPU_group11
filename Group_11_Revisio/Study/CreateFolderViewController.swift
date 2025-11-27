//
//  CreateFolderViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 27/11/25.
//

import UIKit

class CreateFolderViewController: UIViewController {
    
    @IBOutlet var folderNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        guard let newFolderName = folderNameTextField.text, !newFolderName.isEmpty else {
                // Add UI feedback (e.g., alert or shake) for empty input
                print("Folder name cannot be empty.")
                return
            }

            // 1. Save Data: Create the new structure in the DataManager
            // Ensure DataManager.createNewSubjectFolder is implemented as previously discussed
            DataManager.shared.createNewSubjectFolder(name: newFolderName)

            // 2. Dismiss the modal
            self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
