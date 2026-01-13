import UIKit

// Represents a single entry in your history list
struct LogHistoryItem {
    let amount: String
    let time: String
}

class LogProgressViewController: UIViewController {
    
    // DELEGATE PROPERTY
    weak var delegate: LogStudyTimeDelegate?
    
    // Local history to show in the table
    var history: [LogHistoryItem] = []
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var logHoursTextField: UITextField!
    @IBOutlet weak var historyTableView: UITableView!
    
        override func viewDidLoad() {
            super.viewDidLoad()
            
            setupNavigationBar()
            setupInitialData()
            setupTableView()
            
            // Listen for date changes to update the top label
            datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        }
        
        // MARK: - Setup
        private func setupTableView() {
            historyTableView.dataSource = self
            historyTableView.delegate = self
            // Standard cell registration
            historyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
            historyTableView.backgroundColor = .clear
            historyTableView.separatorStyle = .singleLine
        }
        
        private func setupNavigationBar() {
            navigationItem.title = "Log Study Time"
            
            // Setup Checkmark (Save) Button
            let checkmarkConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
            let checkmarkImage = UIImage(systemName: "checkmark", withConfiguration: checkmarkConfig)
            let saveButton = UIBarButtonItem(image: checkmarkImage, style: .plain, target: self, action: #selector(saveAndDismiss))
            navigationItem.rightBarButtonItem = saveButton
            
            // Setup Xmark (Cancel) Button
            let xmarkImage = UIImage(systemName: "xmark", withConfiguration: checkmarkConfig)
            let cancelButton = UIBarButtonItem(image: xmarkImage, style: .plain, target: self, action: #selector(dismissModal))
            navigationItem.leftBarButtonItem = cancelButton
        }
        
        private func setupInitialData() {
            updateDateLabel(for: datePicker.date)
            
            logHoursTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            logHoursTextField.leftViewMode = .always
            logHoursTextField.keyboardType = .decimalPad
        }
       
        @objc private func datePickerChanged(_ sender: UIDatePicker) {
            updateDateLabel(for: sender.date)
        }
        
        private func updateDateLabel(for date: Date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let dateString = formatter.string(from: date)
            
            dateLabel.text = Calendar.current.isDateInToday(date) ? "Today, \(dateString)" : dateString
        }
        
        @objc func dismissModal() {
            self.dismiss(animated: true)
        }
        
        @objc func saveAndDismiss() {
            let text = logHoursTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let hoursStudied = Double(text), hoursStudied > 0 else {
                self.dismiss(animated: true)
                return
            }

            let logDate = datePicker.date
            
            // 1. Update the Local History Table
            let timeString = DateFormatter.localizedString(from: logDate, dateStyle: .none, timeStyle: .short)
            let newItem = LogHistoryItem(amount: "\(text) hours", time: timeString)
            
            // Insert at the top of the list
            history.insert(newItem, at: 0)
            
            // 2. Refresh table with animation
            historyTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)

            // 3. Send data to ProgressViewController via delegate
            delegate?.didLogStudyTime(hours: hoursStudied, date: logDate, subject: nil)

            // Clear input for next entry
            logHoursTextField.text = ""
            
            // If you want to log multiple entries, remove the line below.
            // If you want to close immediately after one log, keep it.
            self.dismiss(animated: true)
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }
    }

    // MARK: - TableView Protocols
    extension LogProgressViewController: UITableViewDataSource, UITableViewDelegate {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return history.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // Create a cell with a subtitle style to show hours and time
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "HistoryCell")
            let item = history[indexPath.row]
            
            cell.textLabel?.text = "Logged Progress"
            cell.detailTextLabel?.text = "\(item.amount) at \(item.time)"
            
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            cell.detailTextLabel?.font = .systemFont(ofSize: 14)
            cell.detailTextLabel?.textColor = .secondaryLabel
            
            return cell
        }
    }
