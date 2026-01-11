import Foundation
import UIKit

// Protocol used by LogProgressViewController to notify when study time is logged
public protocol LogStudyTimeDelegate: AnyObject {
    /// Called when the user logs study time.
    /// - Parameters:
    ///   - hours: The number of hours studied.
    ///   - date: The date associated with the logged study time.
    ///   - subject: Optional subject/category for the study session.
    func didLogStudyTime(hours: Double, date: Date, subject: String?)
}
