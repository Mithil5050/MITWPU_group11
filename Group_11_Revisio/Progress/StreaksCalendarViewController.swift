//
//  StreaksCalendarViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 13/12/25.
//

import UIKit

struct DayData {
    let date: Int // Day number (1, 2, 3, etc.)
    let isCurrentMonth: Bool
    let isStreaked: Bool // True if the day should have the orange background
}

class StreaksCalendarViewController: UIViewController {

    @IBOutlet weak var calendarGrid: UICollectionView!
    
    var novemberDays: [DayData] = [
            // Leading blank days for alignment (Sun, Mon, Tue)
            DayData(date: 0, isCurrentMonth: false, isStreaked: false),
            DayData(date: 0, isCurrentMonth: false, isStreaked: false),
            DayData(date: 0, isCurrentMonth: false, isStreaked: false),
            
            // WED to SUN (Streak days marked 'true')
            DayData(date: 1, isCurrentMonth: true, isStreaked: true),
            DayData(date: 2, isCurrentMonth: true, isStreaked: true),
            DayData(date: 3, isCurrentMonth: true, isStreaked: true),
            DayData(date: 4, isCurrentMonth: true, isStreaked: true),

            // Week 2
            DayData(date: 5, isCurrentMonth: true, isStreaked: true),
            DayData(date: 6, isCurrentMonth: true, isStreaked: true),
            DayData(date: 7, isCurrentMonth: true, isStreaked: false),
            DayData(date: 8, isCurrentMonth: true, isStreaked: true),
            DayData(date: 9, isCurrentMonth: true, isStreaked: true),
            DayData(date: 10, isCurrentMonth: true, isStreaked: true),
            DayData(date: 11, isCurrentMonth: true, isStreaked: true),

            // Week 3
            DayData(date: 12, isCurrentMonth: true, isStreaked: true),
            DayData(date: 13, isCurrentMonth: true, isStreaked: true),
            DayData(date: 14, isCurrentMonth: true, isStreaked: true),
            DayData(date: 15, isCurrentMonth: true, isStreaked: true),
            DayData(date: 16, isCurrentMonth: true, isStreaked: true),
            DayData(date: 17, isCurrentMonth: true, isStreaked: true),
            DayData(date: 18, isCurrentMonth: true, isStreaked: true),

            // Week 4
            DayData(date: 19, isCurrentMonth: true, isStreaked: true),
            DayData(date: 20, isCurrentMonth: true, isStreaked: true), // Current Day
            DayData(date: 21, isCurrentMonth: true, isStreaked: false),
            DayData(date: 22, isCurrentMonth: true, isStreaked: false),
            DayData(date: 23, isCurrentMonth: true, isStreaked: false),
            DayData(date: 24, isCurrentMonth: true, isStreaked: false),
            DayData(date: 25, isCurrentMonth: true, isStreaked: false),

            // Week 5
            DayData(date: 26, isCurrentMonth: true, isStreaked: false),
            DayData(date: 27, isCurrentMonth: true, isStreaked: false),
            DayData(date: 28, isCurrentMonth: true, isStreaked: false),
            DayData(date: 29, isCurrentMonth: true, isStreaked: false),
            DayData(date: 30, isCurrentMonth: true, isStreaked: false)
        ]

        var decemberDays: [DayData] = [
            // Starts on Thu
            DayData(date: 0, isCurrentMonth: false, isStreaked: false),
            DayData(date: 0, isCurrentMonth: false, isStreaked: false),
            DayData(date: 0, isCurrentMonth: false, isStreaked: false),
            DayData(date: 1, isCurrentMonth: true, isStreaked: false),
            
            DayData(date: 2, isCurrentMonth: true, isStreaked: false),
            DayData(date: 3, isCurrentMonth: true, isStreaked: false),
            DayData(date: 4, isCurrentMonth: true, isStreaked: false),

            // Week 2
            DayData(date: 5, isCurrentMonth: true, isStreaked: false),
            DayData(date: 6, isCurrentMonth: true, isStreaked: false),
            DayData(date: 7, isCurrentMonth: true, isStreaked: false),
            DayData(date: 8, isCurrentMonth: true, isStreaked: false),
            DayData(date: 9, isCurrentMonth: true, isStreaked: false),
            DayData(date: 10, isCurrentMonth: true, isStreaked: false),
            DayData(date: 11, isCurrentMonth: true, isStreaked: false),

            // Remaining days...
        ]


        override func viewDidLoad() {
            super.viewDidLoad()
            
            // --- 1. Delegate & Data Source Assignment ---
            calendarGrid.dataSource = self
            calendarGrid.delegate = self
            
            // --- 2. Cell Registration (Needed if not using Storyboard setup) ---
            // If your prototype cell in the Storyboard is a custom class, this line might be redundant
            // but is safe to keep if you did not link the class in the Storyboard.
            calendarGrid.register(CalendarDayCell.self, forCellWithReuseIdentifier: "CalendarDayCell")
            
            // --- 3. Flow Layout Spacing Setup ---
            if let layout = calendarGrid.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.minimumInteritemSpacing = 4.0 // Horizontal gap
                layout.minimumLineSpacing = 8.0      // Vertical gap
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    extension StreaksCalendarViewController: UICollectionViewDataSource {
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 2 // November and December
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return section == 0 ? novemberDays.count : decemberDays.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as? CalendarDayCell else {
                fatalError("Failed to dequeue CalendarDayCell. Ensure identifier is set correctly in Storyboard.")
            }
            
            let dayData: DayData
            if indexPath.section == 0 {
                dayData = novemberDays[indexPath.item]
            } else {
                dayData = decemberDays[indexPath.item]
            }
            
            // Pass data to the cell for styling
           // cell.configure(with: dayData)
            
            return cell
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout (The 7-Column Sizing Logic)

    extension StreaksCalendarViewController: UICollectionViewDelegateFlowLayout {
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
            
            let numberOfColumns: CGFloat = 7
            let interItemSpacing = flowLayout.minimumInteritemSpacing
            
            let totalHorizontalPadding: CGFloat = 0 // Assuming no Section Insets set on the CollectionView itself
            
            // Calculate the total width taken up by the 6 gaps between the 7 columns
            let totalSpacing = interItemSpacing * (numberOfColumns - 1)
            
            let availableWidth = collectionView.bounds.width - totalHorizontalPadding - totalSpacing
            
            // Calculate the dimension of a single square cell
            let cellDimension = floor(availableWidth / numberOfColumns)
            
            // Returns a perfect square for the circular styling
            return CGSize(width: cellDimension, height: cellDimension)
        }
    }

