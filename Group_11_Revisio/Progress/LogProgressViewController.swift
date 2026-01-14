import UIKit

// Represents a single entry in your history list
//struct LogHistoryItem {
//    let amount: String
//    let time: String
//}

class LogProgressViewController: UIViewController {
    
    // DELEGATE PROPERTY
    weak var delegate: LogStudyTimeDelegate?
    
    // Local history to show in the table
    var history: [LogHistoryItem] = []
 
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!

    override func viewDidLoad() {
            super.viewDidLoad()
            
//            // Safety check to prevent crashes if outlets are disconnected
//            guard timePicker != nil, dateLabel != nil, datePicker != nil else {
//                print("❌ Storyboard Connection Missing: check your Outlets!")
//                return
//            }
//            
            setupNavigationBar()
            
            // Set the timer mode
            timePicker.datePickerMode = .countDownTimer
            
            // Initial label update
            updateDateLabel(for: datePicker.date)
            
            // Listen for date changes
            datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        }
        
        // MARK: - Helper Functions (DO NOT DELETE THESE)
        
        @objc private func datePickerChanged(_ sender: UIDatePicker) {
            updateDateLabel(for: sender.date)
        }
        
        private func updateDateLabel(for date: Date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let dateString = formatter.string(from: date)
            dateLabel.text = Calendar.current.isDateInToday(date) ? "Today, \(dateString)" : dateString
        }
        
    @objc func saveAndDismiss() {
        let totalSeconds = timePicker.countDownDuration
        let hoursStudied = totalSeconds / 3600.0
        let logDate = datePicker.date
        
        guard totalSeconds > 0 else {
            self.dismiss(animated: true)
            return
        }

        // Create a new Log Item
        let newEntry = LogHistoryItem(
            id: UUID().uuidString,
            amount: hoursStudied >= 1 ? "\(Int(hoursStudied))h" : "\(Int(totalSeconds/60))m",
            hours: hoursStudied,
            time: DateFormatter.localizedString(from: logDate, dateStyle: .none, timeStyle: .short),
            date: logDate
        )

        // Add to DataManager and save to memory
        ProgressDataManager.shared.history.insert(newEntry, at: 0)
        ProgressDataManager.shared.save()

        // Notify the Progress screen to refresh
        delegate?.didLogStudyTime(hours: hoursStudied, date: logDate, subject: nil)
        self.dismiss(animated: true)
    }
//        @objc func saveAndDismiss() {
//            let totalSeconds = timePicker.countDownDuration
//            let hoursStudied = totalSeconds / 3600.0
//            
//            guard totalSeconds > 0 else {
//                self.dismiss(animated: true)
//                return
//            }
//
//            delegate?.didLogStudyTime(hours: hoursStudied, date: datePicker.date, subject: nil)
//            self.dismiss(animated: true)
//        }
        
        @objc func dismissModal() {
            self.dismiss(animated: true)
        }
        
        private func setupNavigationBar() {
            navigationItem.title = "Log Study Time"
            
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            
            let saveButton = UIBarButtonItem(image: UIImage(systemName: "checkmark", withConfiguration: config),
                                             style: .plain, target: self, action: #selector(saveAndDismiss))
            
            let cancelButton = UIBarButtonItem(image: UIImage(systemName: "xmark", withConfiguration: config),
                                               style: .plain, target: self, action: #selector(dismissModal))
            
            navigationItem.rightBarButtonItem = saveButton
            navigationItem.leftBarButtonItem = cancelButton
        }
    }
