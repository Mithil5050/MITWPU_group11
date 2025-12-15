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

// NEW STRUCTURE: To hold the name and data for each month
struct Month {
    let name: String
    let days: [DayData]
}

class StreaksCalendarViewController: UIViewController {

      
    @IBOutlet weak var calendarGrid: UICollectionView!
    
    @IBOutlet weak var streakInfoMessageBox: UIView!
    

    var allMonths: [Month] = []
    

        override func viewDidLoad() {
            super.viewDidLoad()
            
            // 1. Generate the data for all desired months
                generateCalendarData()
                
                // --- STYLING THE ENTIRE STREAK TIP BOX (This can stay near the top) ---
                if let containerView = streakInfoMessageBox {
                    containerView.backgroundColor = .systemGray6
                    containerView.layer.cornerRadius = 12
                    containerView.layer.masksToBounds = true
                }
                
                // 2. Delegate & Data Source Assignment (MOVED DOWN)
                calendarGrid.dataSource = self
                calendarGrid.delegate = self
                
                // 3. Cell and Header Registration
                calendarGrid.register(CalendarDayCollectionViewCell.self, forCellWithReuseIdentifier: "CalendarDayCell")
                
                calendarGrid.register(UICollectionReusableView.self,
                                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                      withReuseIdentifier: "MonthHeader")
                
                // 4. Flow Layout Setup
                if let layout = calendarGrid.collectionViewLayout as? UICollectionViewFlowLayout {
                    layout.minimumInteritemSpacing = 4.0
                    layout.minimumLineSpacing = 8.0
                }
            }
        
    // MARK: - Dynamic Data Generation (NOW COMPLETE for Nov, Dec, Jan)
        
        func generateCalendarData() {
            
            // --- November Data (Section 0) - Ends on a Monday ---
            let novemberDays: [DayData] = [
                // Leading blank days for alignment (Sun, Mon, Tue)
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                
                // Days 1-30
                DayData(date: 1, isCurrentMonth: true, isStreaked: true), DayData(date: 2, isCurrentMonth: true, isStreaked: true), DayData(date: 3, isCurrentMonth: true, isStreaked: true), DayData(date: 4, isCurrentMonth: true, isStreaked: true),
                DayData(date: 5, isCurrentMonth: true, isStreaked: true), DayData(date: 6, isCurrentMonth: true, isStreaked: true), DayData(date: 7, isCurrentMonth: true, isStreaked: false),
                DayData(date: 8, isCurrentMonth: true, isStreaked: true), DayData(date: 9, isCurrentMonth: true, isStreaked: true), DayData(date: 10, isCurrentMonth: true, isStreaked: true), DayData(date: 11, isCurrentMonth: true, isStreaked: true),
                DayData(date: 12, isCurrentMonth: true, isStreaked: true), DayData(date: 13, isCurrentMonth: true, isStreaked: true), DayData(date: 14, isCurrentMonth: true, isStreaked: true),
                DayData(date: 15, isCurrentMonth: true, isStreaked: true), DayData(date: 16, isCurrentMonth: true, isStreaked: true), DayData(date: 17, isCurrentMonth: true, isStreaked: true), DayData(date: 18, isCurrentMonth: true, isStreaked: true),
                DayData(date: 19, isCurrentMonth: true, isStreaked: true), DayData(date: 20, isCurrentMonth: true, isStreaked: true), DayData(date: 21, isCurrentMonth: true, isStreaked: false),
                DayData(date: 22, isCurrentMonth: true, isStreaked: false), DayData(date: 23, isCurrentMonth: true, isStreaked: false), DayData(date: 24, isCurrentMonth: true, isStreaked: false), DayData(date: 25, isCurrentMonth: true, isStreaked: false),
                DayData(date: 26, isCurrentMonth: true, isStreaked: false), DayData(date: 27, isCurrentMonth: true, isStreaked: false), DayData(date: 28, isCurrentMonth: true, isStreaked: false),
                DayData(date: 29, isCurrentMonth: true, isStreaked: false), DayData(date: 30, isCurrentMonth: true, isStreaked: false) // Day 30 is a Monday (Index 29)
            ]
            
            // --- December Data (Section 1) - Starts on a Tuesday ---
            let decemberDays: [DayData] = [
                // Alignment for Tuesday (Sun, Mon)
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                
                // Days 1-31 (December has 31 days)
                DayData(date: 1, isCurrentMonth: true, isStreaked: false), DayData(date: 2, isCurrentMonth: true, isStreaked: false), DayData(date: 3, isCurrentMonth: true, isStreaked: false), DayData(date: 4, isCurrentMonth: true, isStreaked: false), DayData(date: 5, isCurrentMonth: true, isStreaked: false),
                DayData(date: 6, isCurrentMonth: true, isStreaked: false), DayData(date: 7, isCurrentMonth: true, isStreaked: false), DayData(date: 8, isCurrentMonth: true, isStreaked: false), DayData(date: 9, isCurrentMonth: true, isStreaked: false), DayData(date: 10, isCurrentMonth: true, isStreaked: false), DayData(date: 11, isCurrentMonth: true, isStreaked: false), DayData(date: 12, isCurrentMonth: true, isStreaked: false),
                DayData(date: 13, isCurrentMonth: true, isStreaked: false), DayData(date: 14, isCurrentMonth: true, isStreaked: false), DayData(date: 15, isCurrentMonth: true, isStreaked: false), DayData(date: 16, isCurrentMonth: true, isStreaked: false), DayData(date: 17, isCurrentMonth: true, isStreaked: false), DayData(date: 18, isCurrentMonth: true, isStreaked: false), DayData(date: 19, isCurrentMonth: true, isStreaked: false),
                DayData(date: 20, isCurrentMonth: true, isStreaked: false), DayData(date: 21, isCurrentMonth: true, isStreaked: false), DayData(date: 22, isCurrentMonth: true, isStreaked: false), DayData(date: 23, isCurrentMonth: true, isStreaked: false), DayData(date: 24, isCurrentMonth: true, isStreaked: false), DayData(date: 25, isCurrentMonth: true, isStreaked: false), DayData(date: 26, isCurrentMonth: true, isStreaked: false),
                DayData(date: 27, isCurrentMonth: true, isStreaked: false), DayData(date: 28, isCurrentMonth: true, isStreaked: false), DayData(date: 29, isCurrentMonth: true, isStreaked: false), DayData(date: 30, isCurrentMonth: true, isStreaked: false), DayData(date: 31, isCurrentMonth: true, isStreaked: false) // Day 31 is a Friday (Index 32)
            ]

            // --- January Data (Section 2) - Starts on a Saturday ---
            let januaryDays: [DayData] = [
                // Alignment for Saturday (Sun, Mon, Tue, Wed, Thu, Fri)
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                DayData(date: 0, isCurrentMonth: false, isStreaked: false),
                
                // Days 1-31 (January has 31 days)
                DayData(date: 1, isCurrentMonth: true, isStreaked: false), DayData(date: 2, isCurrentMonth: true, isStreaked: false), DayData(date: 3, isCurrentMonth: true, isStreaked: false), DayData(date: 4, isCurrentMonth: true, isStreaked: false), DayData(date: 5, isCurrentMonth: true, isStreaked: false), DayData(date: 6, isCurrentMonth: true, isStreaked: false), DayData(date: 7, isCurrentMonth: true, isStreaked: false),
                DayData(date: 8, isCurrentMonth: true, isStreaked: false), DayData(date: 9, isCurrentMonth: true, isStreaked: false), DayData(date: 10, isCurrentMonth: true, isStreaked: false), DayData(date: 11, isCurrentMonth: true, isStreaked: false), DayData(date: 12, isCurrentMonth: true, isStreaked: false), DayData(date: 13, isCurrentMonth: true, isStreaked: false), DayData(date: 14, isCurrentMonth: true, isStreaked: false),
                DayData(date: 15, isCurrentMonth: true, isStreaked: false), DayData(date: 16, isCurrentMonth: true, isStreaked: false), DayData(date: 17, isCurrentMonth: true, isStreaked: false), DayData(date: 18, isCurrentMonth: true, isStreaked: false), DayData(date: 19, isCurrentMonth: true, isStreaked: false), DayData(date: 20, isCurrentMonth: true, isStreaked: false), DayData(date: 21, isCurrentMonth: true, isStreaked: false),
                DayData(date: 22, isCurrentMonth: true, isStreaked: false), DayData(date: 23, isCurrentMonth: true, isStreaked: false), DayData(date: 24, isCurrentMonth: true, isStreaked: false), DayData(date: 25, isCurrentMonth: true, isStreaked: false), DayData(date: 26, isCurrentMonth: true, isStreaked: false), DayData(date: 27, isCurrentMonth: true, isStreaked: false), DayData(date: 28, isCurrentMonth: true, isStreaked: false),
                DayData(date: 29, isCurrentMonth: true, isStreaked: false), DayData(date: 30, isCurrentMonth: true, isStreaked: false), DayData(date: 31, isCurrentMonth: true, isStreaked: false) // Day 31 is a Tuesday (Index 36)
            ]


            // Append all three months
            allMonths.append(Month(name: "NOVEMBER", days: novemberDays))
            allMonths.append(Month(name: "DECEMBER", days: decemberDays))
            allMonths.append(Month(name: "JANUARY", days: januaryDays)) // New scrollable month!
        }
    }

    // MARK: - UICollectionViewDataSource

    extension StreaksCalendarViewController: UICollectionViewDataSource {
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return allMonths.count
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return allMonths[section].days.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as? CalendarDayCollectionViewCell else {
                fatalError("Failed to dequeue CalendarDayCell.")
            }
            
            let dayData = allMonths[indexPath.section].days[indexPath.item]
            
            cell.configure(with: dayData)
            return cell
        }
        
        // METHOD TO PROVIDE THE MONTH HEADER CONTENT (Programmatic Fix)
        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            
            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: "MonthHeader",
                    for: indexPath)
                
                // --- 1. Cleanup: Remove any old labels before adding new ones ---
                header.subviews.forEach { $0.removeFromSuperview() }
                
                // --- 2. Create the Month Label programmatically ---
                let monthLabel = UILabel()
                monthLabel.translatesAutoresizingMaskIntoConstraints = false
                monthLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold) // Styling
                monthLabel.textColor = .label
                monthLabel.text = allMonths[indexPath.section].name // Set the text
                
                header.addSubview(monthLabel)
                
                // --- 3. Create the Day Names Stack View ---
                let dayNames = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
                let dayStackView = UIStackView()
                dayStackView.translatesAutoresizingMaskIntoConstraints = false
                dayStackView.axis = .horizontal
                dayStackView.distribution = .fillEqually
                header.addSubview(dayStackView)
                
                // Add the 7 day labels to the stack view
                for day in dayNames {
                    let label = UILabel()
                    label.text = day
                    label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
                    label.textColor = .systemGray
                    label.textAlignment = .center
                    dayStackView.addArrangedSubview(label)
                }
                
                // --- 4. Pin Constraints ---
                NSLayoutConstraint.activate([
                    // Pin Month Label to the top left
                    monthLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
                    monthLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 8),
                                
                    // Pin Day Stack View below the Month Label
                    dayStackView.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 4), // Space below month name
                    dayStackView.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 0),
                    dayStackView.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: 0),
                    dayStackView.heightAnchor.constraint(equalToConstant: 20), // Fixed height for the day names row
                    dayStackView.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -4) // Pin stack to bottom of header
                            ])
                            
                        return header
            }
            return UICollectionReusableView()
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    extension StreaksCalendarViewController: UICollectionViewDelegateFlowLayout {
        
        // METHOD TO PROVIDE THE MONTH HEADER SIZE
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            // Height for month name and day names
            return CGSize(width: collectionView.bounds.width, height: 70)
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
            
            let numberOfColumns: CGFloat = 7
            let interItemSpacing = flowLayout.minimumInteritemSpacing
            let totalHorizontalPadding: CGFloat = 0
            
            let totalSpacing = interItemSpacing * (numberOfColumns - 1)
            
            let availableWidth = collectionView.bounds.width - totalHorizontalPadding - totalSpacing
            
            let cellDimension = floor(availableWidth / numberOfColumns)
            
            return CGSize(width: cellDimension, height: cellDimension)
        }
    }
