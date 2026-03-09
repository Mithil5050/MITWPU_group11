import UIKit

class ConnectionsLaunchingScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func StartButton(_ sender: UIButton) {
        let topics = DataManager.shared.getAllRecentTopics()
        
        // Create an Action Sheet to let the user choose a topic
        let alert = UIAlertController(
            title: "Choose a Topic",
            message: "Select study material to generate your Connections game from:",
            preferredStyle: .actionSheet
        )
        
        // Add up to 10 recent topics to the list
        for topic in topics.prefix(10) {
            alert.addAction(UIAlertAction(title: topic.name, style: .default) { [weak self] _ in
                self?.performSegue(withIdentifier: "StartGameConnection", sender: topic)
            })
        }
        
        // Fallback option for random general knowledge
        alert.addAction(UIAlertAction(title: "General Knowledge (Random)", style: .default) { [weak self] _ in
            self?.performSegue(withIdentifier: "StartGameConnection", sender: nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support to prevent crashing
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        
        present(alert, animated: true)
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
