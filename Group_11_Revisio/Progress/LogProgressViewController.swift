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

class LogProgressViewController: UIViewController {
    
    // DELEGATE PROPERTY
    weak var delegate: LogStudyTimeDelegate?
    
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var logHoursTextField: UITextField!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // Background is managed by the system and the Navigation Controller for blur effect.
            // The input card should be set to white in the Storyboard.
            
            setupNavigationBar()
            setupInitialData()
            
            datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        }
        
        // MARK: - Setup Methods
        
        func setupNavigationBar() {
            navigationItem.title = "Log Study Time"
            
            let largerConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            
            // Setup Cross Button (Left Side)
            let xmarkImage = UIImage(systemName: "xmark", withConfiguration: largerConfig)
            let cancelButton = UIBarButtonItem(image: xmarkImage,
                                               style: .plain,
                                               target: self,
                                               action: #selector(dismissModal))
            navigationItem.leftBarButtonItem = cancelButton
            
            // Setup Tick Button (Right Side)
            let checkmarkImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: largerConfig)
            let saveButton = UIBarButtonItem(image: checkmarkImage,
                                             style: .done,
                                             target: self,
                                             action: #selector(saveAndDismiss))
            navigationItem.rightBarButtonItem = saveButton
        }
        
        func setupInitialData() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let todayString = dateFormatter.string(from: datePicker.date)
            dateLabel.text = "Today, \(todayString)"
            
            logHoursTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: logHoursTextField.frame.height))
            logHoursTextField.leftViewMode = .always
        }
        
        @objc private func datePickerChanged(_ sender: UIDatePicker) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let dateString = dateFormatter.string(from: sender.date)
            
            let calendar = Calendar.current
            if calendar.isDateInToday(sender.date) {
                dateLabel.text = "Today, \(dateString)"
            } else {
                dateLabel.text = dateString
            }
        }
        
        // MARK: - Action Handlers
        
        @objc func dismissModal() {
            self.dismiss(animated: true, completion: nil)
        }
        
        @objc func saveAndDismiss() {
            // 1. Data Validation and Extraction
            let text = logHoursTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let hoursStudied = Double(text) ?? 0

            guard hoursStudied > 0 else {
                // Dismiss if hours are invalid, preventing empty data submission
                self.dismiss(animated: true, completion: nil)
                return
            }

            // 2. Collect Data
            let logDate: Date = datePicker.date
            let subject: String? = nil

            // 3. Send to delegate
            delegate?.didLogStudyTime(hours: hoursStudied, date: logDate, subject: subject)

            // 4. Dismiss
            self.dismiss(animated: true, completion: nil)
        }
        
        // Optional: Hide keyboard when tapping outside
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }
    }
