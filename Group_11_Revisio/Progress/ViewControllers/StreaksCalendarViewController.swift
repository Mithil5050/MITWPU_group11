//
//  StreaksCalendarViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 13/12/25.
//


import UIKit

class StreaksCalendarViewController: UIViewController,
                                     UICalendarSelectionSingleDateDelegate,
                                     UICalendarViewDelegate {

    private let scrollView             = UIScrollView()
    private let contentStack           = UIStackView()
    private let streakInfoCardView     = UIView()
    private let calendarContainerView  = UIView()
    private let streakCountLabel       = UILabel()
    private let streakSuffixLabel      = UILabel()
    private var calendarView: UICalendarView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.title = "Streaks"

        setupLayout()
        buildInfoCard()
        setupCalendar()
        refreshStreakDisplay()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshStreakDisplay),
                                               name: .xpDidUpdate, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshStreakDisplay()
        calendarView?.reloadDecorations(forDateComponents: [], animated: true)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis    = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        streakInfoCardView.backgroundColor   = UIColor.systemOrange.withAlphaComponent(0.1)
        streakInfoCardView.layer.cornerRadius = 16
        streakInfoCardView.clipsToBounds      = true
        contentStack.addArrangedSubview(streakInfoCardView)

        calendarContainerView.backgroundColor = .clear
        contentStack.addArrangedSubview(calendarContainerView)
    }


    private func buildInfoCard() {

        let flameImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        flameImageView.image = UIImage(systemName: "flame", withConfiguration: config)
        flameImageView.tintColor = .systemOrange
        flameImageView.contentMode = .scaleAspectFit
        flameImageView.setContentHuggingPriority(.required, for: .horizontal)

        streakCountLabel.font      = .systemFont(ofSize: 34, weight: .bold)
        streakCountLabel.textColor = .label

        let topRow = UIStackView(arrangedSubviews: [streakCountLabel, flameImageView])
        topRow.axis       = .horizontal
        topRow.spacing    = 8
        topRow.alignment = .center

        streakSuffixLabel.font      = .systemFont(ofSize: 14, weight: .regular)
        streakSuffixLabel.textColor = .secondaryLabel

        let divider = UIView()
        divider.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.25)
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let ruleLabel       = UILabel()
        ruleLabel.text      = "Earn at least 100 XP per day to keep your streak alive."
        ruleLabel.font      = .systemFont(ofSize: 13, weight: .regular)
        ruleLabel.textColor = .tertiaryLabel
        ruleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [topRow, streakSuffixLabel, divider, ruleLabel])
        stack.axis       = .vertical
        stack.spacing    = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        streakInfoCardView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: streakInfoCardView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: streakInfoCardView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: streakInfoCardView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: streakInfoCardView.bottomAnchor, constant: -16)
        ])
    }
    
//  Streak display
    @objc private func refreshStreakDisplay() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let streak = ProgressDataManager.shared.currentStreak
            self.streakCountLabel.text  = "\(streak)"
            self.streakSuffixLabel.text = streak == 1 ? "Day Streak" : "Days Streak"
        }
    }

    private func setupCalendar() {
        calendarView = UICalendarView()
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarContainerView.addSubview(calendarView)

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

//Calendar delegate

    func calendarView(_ calendarView: UICalendarView,
                      decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        let calendar  = Calendar.current
        guard let date = calendar.date(from: dateComponents) else { return nil }
        let formatter  = ISO8601DateFormatter()
        let streakDates = UserDefaults.standard.stringArray(forKey: "streak_dot_dates") ?? []
        let hasStreak  = streakDates.compactMap { formatter.date(from: $0) }.contains {
            calendar.isDate($0, inSameDayAs: date)
        }
        return hasStreak ? .default(color: .systemOrange, size: .medium) : nil
    }

    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                       didSelectDate dateComponents: DateComponents?) { }
}
