//
//  StreaksCalendarViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 13/12/25.
//

import UIKit

class StreaksCalendarViewController: UIViewController, UICalendarSelectionSingleDateDelegate, UICalendarViewDelegate {
    
    
    @IBOutlet weak var streakInfoCardView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var calendarContainerView: UIView!
    
    // MARK: - Properties
    private var calendarView: UICalendarView!
    
    // Demo streak dates
    private let streakDates: [Date] = [
        Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        Calendar.current.date(byAdding: .day, value: -4, to: Date())!
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInfoCard()
        setupCalendar()
    }
    
    // MARK: - Info Card Styling
    private func setupInfoCard() {
        streakInfoCardView.layer.cornerRadius = 16
        streakInfoCardView.clipsToBounds = true
    }
    
    // MARK: - Calendar Setup
    private func setupCalendar() {
        calendarView = UICalendarView()
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarContainerView.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
        ])
        
        // Enable single date selection (today circle)
        let selection = UICalendarSelectionSingleDate(delegate: self)
        selection.selectedDate = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: Date()
        )
        calendarView.selectionBehavior = selection
        
        // Enable decorations
        calendarView.delegate = self
    }
    
    // MARK: - Calendar Decoration (🔥 streaks)
    func calendarView(_ calendarView: UICalendarView,
                      decorationFor dateComponents: DateComponents)
    -> UICalendarView.Decoration? {

        let calendar = Calendar.current
        guard let date = calendar.date(from: dateComponents) else {
            return nil
        }

        if streakDates.contains(where: {
            calendar.isDate($0, inSameDayAs: date)
        }) {
            return .default(color: .systemOrange, size: .small)
        }

        return nil
    }
    
    // MARK: - Date Selection Delegate
    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                       didSelectDate dateComponents: DateComponents?) {
       
    }
}
