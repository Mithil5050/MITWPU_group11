//
//  XPDetailsViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 05/03/26.
//

import UIKit

// MARK: - XP History Model

struct XPEvent {
    let description: String   // e.g. "Quiz Completed"
    let amount: Int           // e.g. 50
    let date: Date
}

// MARK: - XPDetailsViewController

class XPDetailsViewController: UIViewController {

    private let scrollView    = UIScrollView()
    private let contentView   = UIView()
    private let contentStack  = UIStackView()

    private let levelCard      = UIView()
    private let levelLabel     = UILabel()
    private let xpValueLabel   = UILabel()
    private let progressBar    = UIProgressView(progressViewStyle: .default)
    private let nextLevelLabel = UILabel()

    private let historyTableView = UITableView(frame: .zero, style: .plain)
    private var historyTableHeightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "XP Progress"
        navigationController?.navigationBar.prefersLargeTitles = false
        setupLayout()
        refreshData()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshData),
            name: .xpDidUpdate,
            object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

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

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        let widthConstraint = contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        widthConstraint.priority = .required

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            widthConstraint
        ])

        contentStack.axis    = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        // Level card — blue tint works in both light and dark
        levelCard.backgroundColor    = UIColor.systemBlue.withAlphaComponent(0.1)
        levelCard.layer.cornerRadius = 16

        // Subtle border so the card has definition in light mode
        levelCard.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        levelCard.layer.borderWidth = 0.5

        let cardStack = UIStackView()
        cardStack.axis    = .vertical
        cardStack.spacing = 10
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        levelCard.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: levelCard.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: levelCard.leadingAnchor, constant: 18),
            cardStack.trailingAnchor.constraint(equalTo: levelCard.trailingAnchor, constant: -18),
            cardStack.bottomAnchor.constraint(equalTo: levelCard.bottomAnchor, constant: -18)
        ])

        levelLabel.font      = .systemFont(ofSize: 28, weight: .bold)
        levelLabel.textColor = .systemBlue

        xpValueLabel.font      = .systemFont(ofSize: 14, weight: .regular)
        xpValueLabel.textColor = .secondaryLabel   // adaptive

        progressBar.progressTintColor  = .systemBlue
        progressBar.trackTintColor     = UIColor.systemBlue.withAlphaComponent(0.15)
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds      = true

        nextLevelLabel.font          = .systemFont(ofSize: 13, weight: .regular)
        nextLevelLabel.textColor     = .tertiaryLabel   // adaptive
        nextLevelLabel.textAlignment = .right

        cardStack.addArrangedSubview(levelLabel)
        cardStack.addArrangedSubview(xpValueLabel)
        cardStack.addArrangedSubview(progressBar)
        cardStack.addArrangedSubview(nextLevelLabel)

        contentStack.addArrangedSubview(levelCard)

        // Section header
        contentStack.addArrangedSubview(makeSectionHeader("Recent XP Activity"))

        // History table
        historyTableView.dataSource      = self
        historyTableView.delegate        = self
        historyTableView.register(XPHistoryCell.self, forCellReuseIdentifier: "XPHistoryCell")
        historyTableView.isScrollEnabled = false
        historyTableView.backgroundColor = .clear   // let parent background show through
        historyTableView.separatorStyle  = .none
        historyTableView.translatesAutoresizingMaskIntoConstraints = false

        historyTableHeightConstraint = historyTableView.heightAnchor.constraint(equalToConstant: 0)
        historyTableHeightConstraint?.isActive = true

        contentStack.addArrangedSubview(historyTableView)
    }

    // MARK: - Data

    @objc private func refreshData() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let manager = ProgressDataManager.shared

            self.levelLabel.text   = "Level \(manager.userLevel)"
            self.xpValueLabel.text = "\(manager.currentLevelXP) / \(manager.requiredXPForCurrentLevel) XP"
            self.progressBar.setProgress(manager.progressToNextLevel, animated: true)

            let remaining = max(0, manager.requiredXPForCurrentLevel - manager.currentLevelXP)
            self.nextLevelLabel.text = "\(remaining) XP to Level \(manager.userLevel + 1)"

            self.historyTableView.reloadData()
            self.view.layoutIfNeeded()
            self.historyTableHeightConstraint?.constant = self.historyTableView.contentSize.height
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.scrollView.contentSize = self.contentView.frame.size
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.view.setNeedsUpdateConstraints()
            // We reload data to trigger intrinsic content size updates
            self.historyTableView.reloadData()
            self.refreshData()
        })
    }

    // MARK: - Helpers

    private func makeSectionHeader(_ title: String) -> UILabel {
        let label       = UILabel()
        label.text      = title
        label.font      = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label   // adaptive
        return label
    }
}

// MARK: - UITableViewDataSource / Delegate

extension XPDetailsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let events = ProgressDataManager.shared.xpHistory
        return events.isEmpty ? 1 : events.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let events = ProgressDataManager.shared.xpHistory

        if events.isEmpty {
            let cell = UITableViewCell()
            cell.textLabel?.text          = "No XP activity yet. Start learning!"
            cell.textLabel?.textColor     = .secondaryLabel
            cell.textLabel?.font          = .systemFont(ofSize: 14)
            cell.textLabel?.textAlignment = .center
            // Adaptive: secondarySystemGroupedBackground is light grey in light, dark grey in dark
            cell.backgroundColor          = .secondarySystemGroupedBackground
            cell.layer.cornerRadius       = 8
            cell.selectionStyle           = .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "XPHistoryCell", for: indexPath
        ) as! XPHistoryCell
        cell.configure(with: events[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { 52 }

    func tableView(_ tableView: UITableView,
                   viewForFooterInSection section: Int) -> UIView? { UIView() }

    func tableView(_ tableView: UITableView,
                   heightForFooterInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
        let verticalPadding: CGFloat = 6
        let maskLayer = CALayer()
        maskLayer.cornerRadius    = 8
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(
            x: cell.bounds.origin.x,
            y: cell.bounds.origin.y + verticalPadding / 2,
            width: cell.bounds.width,
            height: cell.bounds.height - verticalPadding
        )
        cell.layer.mask = maskLayer
    }
}

// MARK: - XPHistoryCell

final class XPHistoryCell: UITableViewCell {

    private let amountLabel = UILabel()
    private let descLabel   = UILabel()
    private let dateLabel   = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        // Adaptive card background — light grey in light mode, dark grey in dark mode
        backgroundColor    = .secondarySystemGroupedBackground
        layer.cornerRadius = 8
        setupCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        amountLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        amountLabel.textColor = .systemGreen
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        descLabel.font      = .systemFont(ofSize: 15, weight: .regular)
        descLabel.textColor = .label   // adaptive

        dateLabel.font           = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor      = .tertiaryLabel   // adaptive
        dateLabel.textAlignment  = .right
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)

        let leftStack = UIStackView(arrangedSubviews: [amountLabel, descLabel])
        leftStack.axis      = .horizontal
        leftStack.spacing   = 10
        leftStack.alignment = .center

        let row = UIStackView(arrangedSubviews: [leftStack, dateLabel])
        row.axis         = .horizontal
        row.distribution = .fill
        row.alignment    = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            row.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with event: XPEvent) {
        amountLabel.text = "+\(event.amount) XP"
        descLabel.text   = event.description

        let formatter        = DateFormatter()
        formatter.dateFormat = "d MMM"
        dateLabel.text       = formatter.string(from: event.date)
    }
}
