import UIKit

class WordFillLaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func StartButtonTapped(_ sender: UIButton) {
        let topics = DataManager.shared.getAllRecentTopics()
        
        // Create an Action Sheet to let the user choose a topic
        let alert = UIAlertController(
            title: "Choose a Topic",
            message: "Select study material to generate your game from:",
            preferredStyle: .actionSheet
        )
        
        // Add up to 10 recent topics to the list
        for topic in topics.prefix(10) {
            alert.addAction(UIAlertAction(title: topic.name, style: .default) { [weak self] _ in
                self?.performSegue(withIdentifier: "StartWordFill", sender: topic)
            })
        }
        
        // Always give them a fallback option to just play a random game
        alert.addAction(UIAlertAction(title: "General Knowledge (Random)", style: .default) { [weak self] _ in
            self?.performSegue(withIdentifier: "StartWordFill", sender: nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support for Action Sheets to prevent crashing
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartWordFill",
           let destVC = segue.destination as? WordFillViewController {
            
            // If they picked a topic, pass it to the game!
            if let topic = sender as? Topic {
                destVC.currentTopic = topic
            }
        }
    }
}
