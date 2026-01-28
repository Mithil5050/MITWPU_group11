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
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Refresh decorations in case new study logs were added
            calendarView.reloadDecorations(forDateComponents: [], animated: true)
        }
        
        private func setupInfoCard() {
            streakInfoCardView.layer.cornerRadius = 16
            streakInfoCardView.clipsToBounds = true
        }
        
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
            
            let selection = UICalendarSelectionSingleDate(delegate: self)
            selection.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            calendarView.selectionBehavior = selection
            
            calendarView.delegate = self
        }
        
        // MARK: - Calendar Decoration (Real Study Logs)
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let calendar = Calendar.current
            guard let date = calendar.date(from: dateComponents) else { return nil }

            // ✅ Check real history instead of demo dates
            let hasStudied = ProgressDataManager.shared.history.contains { log in
                calendar.isDate(log.date, inSameDayAs: date)
            }

            if hasStudied {
                // Orange dot for days with study logs
                return .default(color: .systemOrange, size: .medium)
            }

            return nil
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            // Optional: Show logs for the specific selected day
        }
    }
