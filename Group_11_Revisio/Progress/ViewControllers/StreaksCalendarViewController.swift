//
//  StreaksCalendarViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 13/12/25.
//

import UIKit

class StreaksCalendarViewController: UIViewController {

    private let scrollView            = UIScrollView()
    private let contentStack          = UIStackView()
    private let streakInfoCardView    = UIView()
    private let calendarContainerView = UIView()
    private let streakCountLabel      = UILabel()
    private let streakSuffixLabel     = UILabel()

    private let monthLabel            = UILabel()
    private var calendarCollection: UICollectionView!

    private var displayedYear: Int  = Calendar.current.component(.year, from: Date())
    private var displayedMonth: Int = Calendar.current.component(.month, from: Date())
    private var streakDateSet: Set<String> = []
    private var selectedDay: Int? = nil

    private let calendar   = Calendar.current
    private let daySymbols = ["SUN","MON","TUE","WED","THU","FRI","SAT"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = "Streaks"

        loadStreakDates()
        setupLayout()
        buildInfoCard()
        buildCalendarHeader()
        buildCalendarGrid()
        refreshStreakDisplay()

        NotificationCenter.default.addObserver(self, selector: #selector(onXPUpdate),
                                               name: .xpDidUpdate, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStreakDates()
        refreshStreakDisplay()
        calendarCollection?.reloadData()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyCardShadow(to: streakInfoCardView)
            applyCardShadow(to: calendarContainerView)
            calendarCollection?.reloadData()
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Data

    private func loadStreakDates() {
        let formatter = ISO8601DateFormatter()
        let raw = UserDefaults.standard.stringArray(forKey: "streak_dot_dates") ?? []
        streakDateSet = Set(raw.compactMap { str -> String? in
            guard let date = formatter.date(from: str) else { return nil }
            return dayKey(date)
        })
    }

    private func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }

    private func isStreakDay(_ day: Int) -> Bool {
        var c = DateComponents()
        c.year = displayedYear; c.month = displayedMonth; c.day = day
        guard let date = calendar.date(from: c) else { return false }
        return streakDateSet.contains(dayKey(date))
    }

    private func isToday(_ day: Int) -> Bool {
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        return displayedYear == today.year! && displayedMonth == today.month! && day == today.day!
    }

    // MARK: - Calendar math

    private func daysInMonth() -> Int {
        var c = DateComponents(); c.year = displayedYear; c.month = displayedMonth
        guard let date = calendar.date(from: c) else { return 30 }
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private func firstWeekdayOfMonth() -> Int {
        var c = DateComponents(); c.year = displayedYear; c.month = displayedMonth; c.day = 1
        guard let date = calendar.date(from: c) else { return 0 }
        return (calendar.component(.weekday, from: date) - 1 + 7) % 7
    }

    private func monthTitle() -> String {
        var c = DateComponents(); c.year = displayedYear; c.month = displayedMonth
        guard let date = calendar.date(from: c) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }

    // MARK: - Shadow

    private func applyCardShadow(to view: UIView) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        view.layer.shadowColor   = UIColor.black.cgColor
        view.layer.shadowOpacity = isDark ? 0.30 : 0.06
        view.layer.shadowOffset  = CGSize(width: 0, height: 2)
        view.layer.shadowRadius  = isDark ? 8 : 3
        view.layer.masksToBounds = false
    }

    // MARK: - Layout

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

        streakInfoCardView.backgroundColor   = UIColor.systemOrange.withAlphaComponent(0.12)
        streakInfoCardView.layer.cornerRadius = 16
        streakInfoCardView.clipsToBounds      = false
        applyCardShadow(to: streakInfoCardView)
        contentStack.addArrangedSubview(streakInfoCardView)

        calendarContainerView.backgroundColor   = .secondarySystemGroupedBackground
        calendarContainerView.layer.cornerRadius = 16
        calendarContainerView.clipsToBounds      = true
        applyCardShadow(to: calendarContainerView)
        contentStack.addArrangedSubview(calendarContainerView)
    }

    private func buildInfoCard() {
        let flameImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        flameImageView.image = UIImage(systemName: "flame", withConfiguration: config)
        flameImageView.tintColor   = .systemOrange
        flameImageView.contentMode = .scaleAspectFit
        flameImageView.setContentHuggingPriority(.required, for: .horizontal)

        streakCountLabel.font      = .systemFont(ofSize: 34, weight: .bold)
        streakCountLabel.textColor = .label

        let topRow = UIStackView(arrangedSubviews: [streakCountLabel, flameImageView])
        topRow.axis      = .horizontal
        topRow.spacing   = 8
        topRow.alignment = .center

        streakSuffixLabel.font      = .systemFont(ofSize: 14, weight: .regular)
        streakSuffixLabel.textColor = .secondaryLabel

        let divider = UIView()
        divider.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.25)
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let ruleLabel       = UILabel()
        ruleLabel.text      = "Earn at least 100 XP per day to keep your streak alive."
        ruleLabel.font      = .systemFont(ofSize: 13, weight: .regular)
        ruleLabel.textColor = .secondaryLabel
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

    // MARK: - Custom Calendar Header

    private func buildCalendarHeader() {
        monthLabel.font      = .systemFont(ofSize: 17, weight: .semibold)
        monthLabel.textColor = .label
        monthLabel.text      = monthTitle()

        let chevronCfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let monthChevron = UIButton(type: .system)
        monthChevron.setImage(UIImage(systemName: "chevron.right", withConfiguration: chevronCfg), for: .normal)
        monthChevron.tintColor = .systemOrange
        monthChevron.setContentHuggingPriority(.required, for: .horizontal)

        let monthRow = UIStackView(arrangedSubviews: [monthLabel, monthChevron])
        monthRow.axis      = .horizontal
        monthRow.spacing   = 4
        monthRow.alignment = .center

        let navCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let prevBtn = UIButton(type: .system)
        prevBtn.setImage(UIImage(systemName: "chevron.left", withConfiguration: navCfg), for: .normal)
        prevBtn.tintColor = .systemOrange
        prevBtn.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)

        let nextBtn = UIButton(type: .system)
        nextBtn.setImage(UIImage(systemName: "chevron.right", withConfiguration: navCfg), for: .normal)
        nextBtn.tintColor = .systemOrange
        nextBtn.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)

        let navStack = UIStackView(arrangedSubviews: [prevBtn, nextBtn])
        navStack.axis      = .horizontal
        navStack.spacing   = 16
        navStack.alignment = .center

        let headerRow = UIStackView(arrangedSubviews: [monthRow, UIView(), navStack])
        headerRow.axis      = .horizontal
        headerRow.alignment = .center

        let dayRow = UIStackView()
        dayRow.axis         = .horizontal
        dayRow.distribution = .fillEqually
        for sym in daySymbols {
            let lbl = UILabel()
            lbl.text          = sym
            lbl.font          = .systemFont(ofSize: 11, weight: .medium)
            lbl.textColor     = .secondaryLabel
            lbl.textAlignment = .center
            dayRow.addArrangedSubview(lbl)
        }

        let outerStack = UIStackView(arrangedSubviews: [headerRow, dayRow])
        outerStack.axis    = .vertical
        outerStack.spacing = 12
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.tag     = 902

        calendarContainerView.addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: calendarContainerView.topAnchor, constant: 16),
            outerStack.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor, constant: 16),
            outerStack.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor, constant: -16)
        ])
    }

    private func buildCalendarGrid() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing      = 2

        calendarCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        calendarCollection.backgroundColor  = .clear
        calendarCollection.isScrollEnabled  = false
        calendarCollection.translatesAutoresizingMaskIntoConstraints = false
        calendarCollection.dataSource       = self
        calendarCollection.delegate         = self
        calendarCollection.register(StreakDayCell.self, forCellWithReuseIdentifier: "StreakDayCell")

        calendarContainerView.addSubview(calendarCollection)

        guard let header = calendarContainerView.viewWithTag(902) else { return }
        NSLayoutConstraint.activate([
            calendarCollection.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            calendarCollection.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            calendarCollection.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
            calendarCollection.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor, constant: -12),
            calendarCollection.heightAnchor.constraint(equalToConstant: 310)
        ])
    }

    // MARK: - Month navigation

    @objc private func prevMonth() {
        selectedDay = nil
        displayedMonth -= 1
        if displayedMonth < 1 { displayedMonth = 12; displayedYear -= 1 }
        monthLabel.text = monthTitle()
        calendarCollection.reloadData()
    }

    @objc private func nextMonth() {
        selectedDay = nil
        displayedMonth += 1
        if displayedMonth > 12 { displayedMonth = 1; displayedYear += 1 }
        monthLabel.text = monthTitle()
        calendarCollection.reloadData()
    }

    @objc private func onXPUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.loadStreakDates()
            self.refreshStreakDisplay()
            self.calendarCollection.reloadData()
        }
    }

    @objc private func refreshStreakDisplay() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let streak = ProgressDataManager.shared.currentStreak
            self.streakCountLabel.text  = "\(streak)"
            self.streakSuffixLabel.text = streak == 1 ? "Day Streak" : "Days Streak"
        }
    }
}

// MARK: - UICollectionView DataSource / Delegate

extension StreaksCalendarViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return firstWeekdayOfMonth() + daysInMonth()
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "StreakDayCell", for: indexPath) as! StreakDayCell

        let offset = firstWeekdayOfMonth()
        if indexPath.item < offset {
            cell.configure(day: nil, state: .empty)
            return cell
        }

        let day = indexPath.item - offset + 1

        let state: StreakDayCell.DayState
        if isStreakDay(day) || isToday(day) {
            state = .streak
        } else if selectedDay == day {
            state = .selected
        } else {
            state = .normal
        }

        cell.configure(day: day, state: state)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let offset = firstWeekdayOfMonth()
        guard indexPath.item >= offset else { return }
        let day = indexPath.item - offset + 1

        if isStreakDay(day) || isToday(day) { return }

        let previousDay = selectedDay
        selectedDay = (selectedDay == day) ? nil : day

        var toReload: [IndexPath] = [indexPath]
        if let prev = previousDay, prev != day {
            let prevIndex = prev + offset - 1
            toReload.append(IndexPath(item: prevIndex, section: 0))
        }
        collectionView.reloadItems(at: toReload)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor(collectionView.bounds.width / 7)
        return CGSize(width: width, height: width)
    }
}

// MARK: - StreakDayCell

final class StreakDayCell: UICollectionViewCell {

    enum DayState { case streak, selected, normal, empty }

    private let circleView = UIView()
    private let dayLabel   = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        circleView.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.translatesAutoresizingMaskIntoConstraints   = false
        dayLabel.textAlignment = .center

        contentView.addSubview(circleView)
        circleView.addSubview(dayLabel)

        let size: CGFloat = 36
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: size),
            circleView.heightAnchor.constraint(equalToConstant: size),
            dayLabel.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: circleView.centerYAnchor)
        ])

        circleView.layer.cornerRadius = size / 2
        circleView.clipsToBounds      = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(day: Int?, state: DayState) {
        guard let day else {
            dayLabel.text              = ""
            circleView.backgroundColor = .clear
            return
        }
        dayLabel.text = "\(day)"
        switch state {
        case .streak:
            circleView.backgroundColor = .systemOrange
            dayLabel.textColor         = .white
            dayLabel.font              = .systemFont(ofSize: 15, weight: .semibold)
        case .selected:
            circleView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.22)
            dayLabel.textColor         = .systemOrange
            dayLabel.font              = .systemFont(ofSize: 15, weight: .semibold)
        case .normal:
            circleView.backgroundColor = .clear
            dayLabel.textColor         = .label
            dayLabel.font              = .systemFont(ofSize: 15, weight: .medium)
        case .empty:
            circleView.backgroundColor = .clear
            dayLabel.textColor         = .clear
            dayLabel.text              = ""
        }
    }
}
