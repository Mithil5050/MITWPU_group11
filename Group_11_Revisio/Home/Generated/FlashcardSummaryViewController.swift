import UIKit

class FlashcardSummaryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var summaryItems: [(term: String, definition: String)] = []

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .black
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let blueColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Session Summary"
        view.backgroundColor = .black

        setupUI()
        setupHeader()
    }

    private func setupUI() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupHeader() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        let label = UILabel()
        label.text = "List of Terms"
        label.font = .systemFont(ofSize: 13, weight: .bold) // Stronger white header
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])

        tableView.tableHeaderView = headerView
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return summaryItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TermCell") ?? UITableViewCell(style: .default, reuseIdentifier: "TermCell")
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        // Clean up subviews to prevent overlapping on reuse
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let item = summaryItems[indexPath.row]

        // Card Container (Themed to Term Blue)
        let container = UIView()
        container.backgroundColor = blueColor.withAlphaComponent(0.12)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = blueColor.withAlphaComponent(0.4).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(container)

        let termLabel = UILabel()
        termLabel.text = item.term
        termLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        termLabel.textColor = .white
        termLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(termLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
            container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),

            termLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            termLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            termLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = summaryItems[indexPath.row]
        showFlashcardDetail(term: item.term, definition: item.definition)
    }

    private func showFlashcardDetail(term: String, definition: String) {
        let detailVC = FlashcardDetailOverlayVC()
        detailVC.term = term
        detailVC.definition = definition
        detailVC.modalPresentationStyle = .overFullScreen
        detailVC.modalTransitionStyle = .crossDissolve
        present(detailVC, animated: true)
    }
}
