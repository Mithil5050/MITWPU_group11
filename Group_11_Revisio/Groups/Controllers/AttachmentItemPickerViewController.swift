//
//  AttachmentItemPickerViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 19/02/26.
//

import UIKit

// MARK: - Protocol & Transfer Model

protocol AttachmentSendDelegate: AnyObject {
    func didSendAttachments(_ items: [SentAttachment])
}

/// Lightweight struct that carries everything ChatViewController needs
/// to show an optimistic bubble and insert a row into Supabase.
struct SentAttachment {
    let displayName: String   // shown as bubble label + file_name in DB
    let content: String       // packed text body (quiz lines, flashcard lines, notes text…)
    let fileType: String      // "document" | "image" | "link"
    let topic: Topic?         // non-nil for generated materials
    let source: Source?       // non-nil for Source files
}

// MARK: - ViewController

class AttachmentItemPickerViewController: UIViewController {

    var selectedSubject: String?
    weak var sendDelegate: AttachmentSendDelegate?

    private let tableView         = UITableView(frame: .zero, style: .insetGrouped)
    private var materialItems: [StudyItem] = []
    private var sourceItems:   [StudyItem] = []
    private var selectedPaths: Set<IndexPath> = []

    private let segmentedControl  = UISegmentedControl(items: ["Materials", "Sources"])

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = selectedSubject ?? "Select Material"

        setupSegment()
        setupTableView()
        fetchItems()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Send (\(selectedPaths.count))",
            style: .done, target: self, action: #selector(sendTapped)
        )
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    // MARK: - Setup

    private func setupSegment() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        navigationItem.titleView = segmentedControl
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource  = self
        tableView.delegate    = self
        tableView.allowsMultipleSelection = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func fetchItems() {
        guard let subject = selectedSubject else { return }
        let data       = DataManager.shared.savedMaterials[subject] ?? [:]
        materialItems  = data[DataManager.materialsKey] ?? []
        sourceItems    = data[DataManager.sourcesKey]   ?? []
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        selectedPaths.removeAll()
        updateSendButton()
        tableView.reloadData()
    }

    private func updateSendButton() {
        let btn = navigationItem.rightBarButtonItem
        btn?.isEnabled = !selectedPaths.isEmpty
        btn?.title     = selectedPaths.isEmpty
            ? "Send"
            : "Send (\(selectedPaths.count))"
    }

    @objc private func sendTapped() {
        let isMaterials = segmentedControl.selectedSegmentIndex == 0
        let items       = isMaterials ? materialItems : sourceItems
        var attachments: [SentAttachment] = []

        for ip in selectedPaths.sorted(by: { $0.row < $1.row }) {
            guard ip.row < items.count else { continue }
            switch items[ip.row] {
            case .topic(let topic):
                attachments.append(SentAttachment(
                    displayName: "\(topic.name) · \(topic.materialType)",
                    content:     packedContent(for: topic),
                    fileType:    "document",
                    topic:       topic,
                    source:      nil
                ))
            case .source(let source):
                let ft = source.fileType.lowercased()
                let fileType: String
                if ["jpg","jpeg","png","gif","heic","image"].contains(ft) { fileType = "image" }
                else if ["link","url","http","https"].contains(ft)        { fileType = "link" }
                else                                                       { fileType = "document" }
                attachments.append(SentAttachment(
                    displayName: source.name,
                    content:     source.name,
                    fileType:    fileType,
                    topic:       nil,
                    source:      source
                ))
            }
        }

        sendDelegate?.didSendAttachments(attachments)
        // Dismiss the whole nav stack (FolderVC + this VC)
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: - Content Packing

    /// Returns the full text body of a Topic to store in messages.content
    private func packedContent(for topic: Topic) -> String {
        switch topic.materialType {
        case "Notes":      return topic.notesContent      ?? topic.largeContentBody ?? topic.name
        case "Cheatsheet": return topic.cheatsheetContent ?? topic.largeContentBody ?? topic.name
        case "Flashcards": return topic.largeContentBody  ?? topic.name
        case "Quiz":       return topic.largeContentBody  ?? topic.name
        default:           return topic.largeContentBody  ?? topic.name
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension AttachmentItemPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        let items = segmentedControl.selectedSegmentIndex == 0 ? materialItems : sourceItems
        return items.count
    }

    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        if segmentedControl.selectedSegmentIndex == 0 {
            return materialItems.isEmpty ? "No materials saved yet" : "Tap items to select"
        }
        return sourceItems.isEmpty ? "No sources saved yet" : "Tap items to select"
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // Use subtitle style for material type sub-label
        if cell.detailTextLabel == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        let items = segmentedControl.selectedSegmentIndex == 0 ? materialItems : sourceItems
        let item  = items[indexPath.row]

        switch item {
        case .topic(let topic):
            cell.textLabel?.text = topic.name
            cell.detailTextLabel?.text = topic.materialType
            cell.detailTextLabel?.textColor = .secondaryLabel
            switch topic.materialType {
            case "Quiz":
                cell.imageView?.image = UIImage(systemName: "timer")
                cell.imageView?.tintColor = .systemGreen
            case "Notes":
                cell.imageView?.image = UIImage(systemName: "book.pages")
                cell.imageView?.tintColor = UIColor(hex: "FFC445", alpha: 0.9)
            case "Flashcards":
                cell.imageView?.image = UIImage(systemName: "rectangle.on.rectangle.angled")
                cell.imageView?.tintColor = .systemBlue
            case "Cheatsheet":
                cell.imageView?.image = UIImage(systemName: "list.clipboard")
                cell.imageView?.tintColor = .systemPurple
            default:
                cell.imageView?.image = UIImage(systemName: "doc")
                cell.imageView?.tintColor = .systemGray
            }
        case .source(let source):
            cell.textLabel?.text = source.name
            cell.detailTextLabel?.text = source.fileType
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.imageView?.image = UIImage(systemName: "paperclip")
            cell.imageView?.tintColor = .systemIndigo
        }

        cell.accessoryType = selectedPaths.contains(indexPath) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedPaths.contains(indexPath) {
            selectedPaths.remove(indexPath)
        } else {
            selectedPaths.insert(indexPath)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateSendButton()
    }
}
