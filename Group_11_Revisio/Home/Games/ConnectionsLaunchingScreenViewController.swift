import UIKit

class ConnectionsLaunchingScreenViewController: UIViewController {

    private var topicDropdownButton: UIButton?
    private var startButton: UIButton?
    private var selectedTopic: Topic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for subview in view.subviews {
            if let btn = subview as? UIButton {
                if btn.configuration?.title == "Start" || btn.titleLabel?.text == "Start" {
                    startButton = btn
                } else if btn.configuration?.title == "Select Topic" || btn.titleLabel?.text == "Select Topic" {
                    topicDropdownButton = btn
                }
            }
        }
        
        if let topicBtn = topicDropdownButton, let startBtn = startButton {
            topicBtn.translatesAutoresizingMaskIntoConstraints = false
            startBtn.translatesAutoresizingMaskIntoConstraints = false
            
            view.removeConstraints(view.constraints.filter { 
                ($0.firstItem as? UIView == topicBtn) || ($0.secondItem as? UIView == topicBtn) ||
                ($0.firstItem as? UIView == startBtn) || ($0.secondItem as? UIView == startBtn)
            })
            topicBtn.removeConstraints(topicBtn.constraints)
            startBtn.removeConstraints(startBtn.constraints)
            
            NSLayoutConstraint.activate([
                startBtn.heightAnchor.constraint(equalToConstant: 52),
                startBtn.widthAnchor.constraint(equalToConstant: 353),
                startBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                startBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                
                topicBtn.heightAnchor.constraint(equalToConstant: 52),
                topicBtn.widthAnchor.constraint(equalToConstant: 353),
                topicBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                topicBtn.bottomAnchor.constraint(equalTo: startBtn.topAnchor, constant: -16)
            ])
        }
        
        setupDropdownMenu()
        startButton?.isEnabled = false
    }
    
    private func setupDropdownMenu() {
        let topics = DataManager.shared.getAllRecentTopics()
        var menuActions: [UIAction] = []
        
        for topic in topics.prefix(10) {
            let action = UIAction(title: topic.name) { [weak self] _ in
                self?.selectedTopic = topic
                self?.topicDropdownButton?.setTitle(topic.name, for: .normal)
                self?.startButton?.isEnabled = true
            }
            menuActions.append(action)
        }
        
        let randomAction = UIAction(title: "General Knowledge (Random)") { [weak self] _ in
            self?.selectedTopic = nil
            self?.topicDropdownButton?.setTitle("General Knowledge (Random)", for: .normal)
            self?.startButton?.isEnabled = true
        }
        menuActions.append(randomAction)
        
        topicDropdownButton?.menu = UIMenu(title: "Choose a Topic", children: menuActions)
        topicDropdownButton?.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func StartButton(_ sender: UIButton) {
        performSegue(withIdentifier: "StartGameConnection", sender: selectedTopic)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartGameConnection",
           let destVC = segue.destination as? ConnectionsViewController {
            
            // Pass the chosen topic!
            if let topic = sender as? Topic {
                destVC.currentTopic = topic
            }
        }
    }
}
