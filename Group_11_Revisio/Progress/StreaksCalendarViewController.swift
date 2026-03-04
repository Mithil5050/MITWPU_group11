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
    
    private var calendarView: UICalendarView!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupCalendar()
            streakInfoCardView.layer.cornerRadius = 16
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            calendarView.reloadDecorations(forDateComponents: [], animated: true)
        }
        
        private func setupCalendar() {
            calendarView = UICalendarView()
            calendarView.translatesAutoresizingMaskIntoConstraints = false
            calendarContainerView.addSubview(calendarView)
            
            // ✅ CENTER ON TODAY (MARCH 2026)
            let now = Date()
            calendarView.visibleDateComponents = Calendar.current.dateComponents([.year, .month], from: now)
            
            NSLayoutConstraint.activate([
                calendarView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
                calendarView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
                calendarView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
                calendarView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
            ])
            
            let selection = UICalendarSelectionSingleDate(delegate: self)
            selection.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: now)
            calendarView.selectionBehavior = selection
            
            calendarView.delegate = self
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let calendar = Calendar.current
            guard let date = calendar.date(from: dateComponents) else { return nil }

            // ✅ Check dynamic history for today's login dot
            let hasStudied = ProgressDataManager.shared.history.contains { log in
                calendar.isDate(log.date, inSameDayAs: date)
            }

            if hasStudied {
                return .default(color: .systemOrange, size: .medium)
            }
            return nil
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) { }
    }
