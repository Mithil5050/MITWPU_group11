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
            
           
            setupNavigationBar()
            setupInitialData()
            
            datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        }
        
        // MARK: - Setup Methods
        
        func setupNavigationBar() {
            navigationItem.title = "Log Study Time"
                
           
           
            let checkmarkSymbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold, scale: .medium)
            let checkmarkImage = UIImage(systemName: "checkmark", withConfiguration: checkmarkSymbolConfig)
            let saveButton = UIBarButtonItem(image: checkmarkImage,
                                             style: .plain,
                                             target: self,
                                             action: #selector(saveAndDismiss))
            navigationItem.rightBarButtonItem = saveButton
        
            let xmarkConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold, scale: .medium)
            let xmarkImage = UIImage(systemName: "xmark", withConfiguration: xmarkConfig)
            
            let cancelButton = UIBarButtonItem(image: xmarkImage,
                                               style: .plain,
                                               target: self,
                                               action: #selector(dismissModal))
            navigationItem.leftBarButtonItem = cancelButton
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
        
       
        
        @objc func dismissModal() {
            self.dismiss(animated: true, completion: nil)
        }
        
        @objc func saveAndDismiss() {
            
            let text = logHoursTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let hoursStudied = Double(text) ?? 0

            guard hoursStudied > 0 else {
                
                self.dismiss(animated: true, completion: nil)
                return
            }

          
            let logDate: Date = datePicker.date
            let subject: String? = nil

           
            delegate?.didLogStudyTime(hours: hoursStudied, date: logDate, subject: subject)

           
            self.dismiss(animated: true, completion: nil)
        }
        
       
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }
    }
