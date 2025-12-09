//
//  LogProgressViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 09/12/25.
//

import UIKit

protocol LogStudyTimeDelegate: AnyObject {
    func didLogStudyTime(hours: Double, date: Date, subject: String?)
}
class LogStudyTimeViewController: UIViewController {
    
    weak var delegate: LogStudyTimeDelegate?
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            setupNavigationBar()
            // Removed: setupCardView()
            setupInitialData()
        }

        // MARK: - Setup Methods

        func setupNavigationBar() {
            navigationItem.title = "Log Study Time"
            
            // Setup Cancel Button (Left)
            let largerConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
                // You can adjust 'pointSize' (e.g., 20, 24) and 'weight' (.medium, .bold)
                
                // 2. Setup Cancel Button (Left)
                let xmarkImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: largerConfig)
                
                let cancelButton = UIBarButtonItem(image: xmarkImage,
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(dismissModal))
                navigationItem.leftBarButtonItem = cancelButton
                
                // 3. Setup Save Button (Right - Tick Icon)
                let checkmarkImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: largerConfig)

                let saveButton = UIBarButtonItem(image: checkmarkImage,
                                                 style: .done,
                                                 target: self,
                                                 action: #selector(saveAndDismiss))
                navigationItem.rightBarButtonItem = saveButton
            }
        
        // Removed: func setupCardView() {...}
        
        func setupInitialData() {
            // Set the Date Label using the default date from the datePicker
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            // Use the date from the datePicker for the label text
            let todayString = dateFormatter.string(from: datePicker.date)
            dateLabel.text = "Today, \(todayString)"
            
            // Optional: Add padding to the text field for better look
            // NOTE: Uses the logHoursTextField outlet
            logHoursTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: logHoursTextField.frame.height))
            logHoursTextField.leftViewMode = .always
        }
        
        // MARK: - Action Handlers

        // Action for the 'X' (Cancel) Button
        @objc func dismissModal() {
            self.dismiss(animated: true, completion: nil)
        }

        // Action for the 'Checkmark' (Save) Button
        @objc func saveAndDismiss() {
            // 1. Data Validation and Extraction (Uses logHoursTextField)
            guard let hoursText = logHoursTextField.text, !hoursText.isEmpty,
                  let hoursStudied = Double(hoursText) else {
                // Handle error, e.g., show an alert
                print("ERROR: Hours field is empty or invalid.")
                return
            }
            
            // 2. Collect Data from UI
            // Uses the date selected by the Date Picker
            let logDate: Date = datePicker.date
            let subject: String? = nil
            
            // 3. Call the Delegate Method to send data back
            delegate?.didLogStudyTime(hours: hoursStudied, date: logDate, subject: subject)
            
            // 4. Dismiss the modal view
            self.dismiss(animated: true, completion: nil)
        }

        // Optional: Hide keyboard when tapping outside
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

