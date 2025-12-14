//
//  ReviewDetailViewController.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 14/12/25.
//

import UIKit

class ReviewDetailViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var reviewTableView: UITableView!
    
    var allQuestionDetails: [QuestionResultDetail] = []
    var filteredQuestionDetails: [QuestionResultDetail] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        reviewTableView.dataSource = self
                reviewTableView.delegate = self
                
                // Set the title for the screen
                title = "Review Summary"
                
                // Initially load the "All" segment data (segment 0)
                filterResults(for: segmentedControl.selectedSegmentIndex)
                
                // Ensure table view updates on load
                reviewTableView.reloadData()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        filterResults(for: sender.selectedSegmentIndex)
                reviewTableView.reloadData()
    }
    func filterResults(for index: Int) {
            switch index {
            case 0: // All (first segment)
                filteredQuestionDetails = allQuestionDetails
            case 1: // Correct (second segment)
                // Filter using the correct property: 'wasCorrect'
                filteredQuestionDetails = allQuestionDetails.filter { $0.wasCorrect == true }
            case 2: // Wrong (Incorrect) (third segment)
                // Filter using the correct property: 'wasCorrect' == false
                filteredQuestionDetails = allQuestionDetails.filter { $0.wasCorrect == false }
            default:
                filteredQuestionDetails = allQuestionDetails
            }
        }

        // MARK: - UITableViewDataSource Methods
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return filteredQuestionDetails.count
        }
        
    // ReviewDetailViewController.swift

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // IMPORTANT: Cast the cell to your custom class
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as? ReviewQuestionCell else {
            // Fallback
            return UITableViewCell()
        }
        
        let detail = filteredQuestionDetails[indexPath.row]
        
        // Use the custom configure method to set all content
        cell.configure(with: detail, index: indexPath.row)
        
        return cell
    }
        
        // MARK: - UITableViewDelegate Methods

        // Ensures cells can expand to show the full question text
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return UITableView.automaticDimension
        }

        func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
            // Provide a reasonable estimate for performance
            return 80
        }
        
        // Optional: Prevent selection in the review table
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
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
