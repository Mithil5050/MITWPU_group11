//
//  RenameAlerts.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 08/12/25.
//

import Foundation
import UIKit
extension UIViewController {
    
    // This reusable function presents the Rename Subject alert and handles the logic.
    func presentRenameAlert(for subjectName: String, completion: @escaping (String) -> Void) {
        
        let alert = UIAlertController(title: "Rename Subject", message: "Enter a new name for '\(subjectName)':", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = subjectName
            textField.placeholder = "New Subject Name"
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
            guard let newName = alert.textFields?.first?.text,
                  !newName.isEmpty,
                  newName != subjectName else {
                return
            }
            
            // Execute the completion handler with the validated new name
            completion(newName)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(renameAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
}
