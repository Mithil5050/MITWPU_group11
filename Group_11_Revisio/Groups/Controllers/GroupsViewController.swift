//
//  GroupsViewController.swift
//  Group_11_Revisio
//

import UIKit

class GroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                             JoinGroupDelegate, GroupUpdateDelegate, UISearchResultsUpdating {

    @IBOutlet weak var groupsTableView: UITableView!

    var myGroups: [Group] = []
    private var lastMessages: [String: String] = [:]

    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredGroups: [Group] = []
    private var isSearching: Bool = false
    private weak var floatingMascot: UIImageView? // ref to run animation

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Groups"
        navigationController?.navigationBar.prefersLargeTitles = true

        groupsTableView.dataSource = self
        groupsTableView.delegate   = self
        groupsTableView.tableFooterView = UIView()

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Groups"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        Task { await loadGroups() }
    }

    // MARK: - Empty State
    private func makeEmptyStateView() -> UIView {
        let bg = UIView(frame: groupsTableView.bounds)
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Mascot
        let mascot = UIImageView(image: UIImage(named: "bot_pencil"))
        mascot.contentMode = .scaleAspectFit
        mascot.translatesAutoresizingMaskIntoConstraints = false
        floatingMascot = mascot

        // Title
        let title = UILabel()
        title.text = "No Groups Yet!"
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.textColor = .label
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        let subtitle = UILabel()
        subtitle.text = "Study is better together \nJoin or create a group to get started."
        subtitle.font = .systemFont(ofSize: 15, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        // Stack
        let stack = UIStackView(arrangedSubviews: [mascot, title, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        bg.addSubview(stack)
        NSLayoutConstraint.activate([
            mascot.widthAnchor.constraint(equalToConstant: 140),
            mascot.heightAnchor.constraint(equalToConstant: 140),

            stack.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: bg.centerYAnchor, constant: -20),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: bg.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: bg.trailingAnchor, constant: -32),
        ])

        return bg
    }

    private func startMascotFloat() {
        guard let mascot = floatingMascot else { return }
        mascot.layer.removeAllAnimations()
        UIView.animate(
            withDuration: 1.6, delay: 0,
            options: [.repeat, .autoreverse, .allowUserInteraction]
        ) { mascot.transform = CGAffineTransform(translationX: 0, y: -10) }
    }

    private func loadGroups() async {
        do {
            let groups = try await SupabaseManager.shared.fetchGroups()
            await MainActor.run {
                myGroups = groups
                groupsTableView.reloadData()
                updateEmptyState()
            }
            await loadLastMessages()
        } catch {
            print("Failed to fetch groups: \(error)")
        }
    }

    private func loadLastMessages() async {
        await withTaskGroup(of: (String, String).self) { taskGroup in
            for g in myGroups {
                taskGroup.addTask {
                    let msg = await SupabaseManager.shared.fetchLastMessage(for: g.id)
                    return (g.id, msg)
                }
            }
            for await (groupId, msg) in taskGroup {
                lastMessages[groupId] = msg
            }
        }
        await MainActor.run {
            groupsTableView.reloadData()
            updateEmptyState()
        }
    }

    func didUpdateGroup(_ group: Group) {
        if let index = myGroups.firstIndex(where: { $0.id == group.id }) {
            myGroups[index] = group
            groupsTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }

    // MARK: - Empty State
    private func updateEmptyState() {
        let isEmpty = myGroups.isEmpty && !isSearching
        if isEmpty {
            groupsTableView.backgroundView = makeEmptyStateView()
            startMascotFloat()
        } else {
            groupsTableView.backgroundView = nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredGroups.count : myGroups.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "GroupCellIdentifier", for: indexPath) as? GroupCell else {
            return UITableViewCell()
        }
        let group = isSearching ? filteredGroups[indexPath.row] : myGroups[indexPath.row]

        cell.groupNameLabel.text = group.name
        cell.groupNameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        cell.lastMessageLabel.text = lastMessages[group.id] ?? "Loading..."
        cell.lastMessageLabel.textColor = .secondaryLabel
        cell.lastMessageLabel.font = UIFont.systemFont(ofSize: 14)

        cell.configureAvatar(group.avatarUrl)
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { return 64 }

    func tableView(_ tableView: UITableView,
                   canEditRowAt indexPath: IndexPath) -> Bool { return true }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { completion(false); return }
            self.confirmDelete(at: indexPath) { completion($0) }
        }
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "Groups", bundle: nil)
        guard let chatVC = storyboard.instantiateViewController(
            withIdentifier: "ChatVC") as? ChatViewController else { return }
        let selectedGroup = isSearching ? filteredGroups[indexPath.row] : myGroups[indexPath.row]
        chatVC.group = selectedGroup
        navigationController?.pushViewController(chatVC, animated: true)
    }

    private func confirmDelete(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let group = myGroups[indexPath.row]
        let alert = UIAlertController(title: "Delete Group",
                                      message: "Are you sure you want to delete \"\(group.name)\"?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { completion(false); return }
            let groupToDelete = self.myGroups[indexPath.row]
            self.myGroups.remove(at: indexPath.row)
            self.lastMessages.removeValue(forKey: groupToDelete.id)
            self.groupsTableView.beginUpdates()
            self.groupsTableView.deleteRows(at: [indexPath], with: .automatic)
            self.groupsTableView.endUpdates()
            completion(true)
            Task {
                do { try await SupabaseManager.shared.deleteGroup(id: groupToDelete.id) }
                catch { print("Failed to delete group: \(error)") }
            }
        })
        present(alert, animated: true)
    }

    @IBAction func joinGroupButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Groups", bundle: nil)
        guard let joinVC = storyboard.instantiateViewController(
            withIdentifier: "JoinGroupVC") as? JoinGroupViewController else { return }
        joinVC.delegate = self
        present(UINavigationController(rootViewController: joinVC), animated: true)
    }

    @IBAction func createGroupButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Groups", bundle: nil)
        guard let createNav = storyboard.instantiateViewController(
            withIdentifier: "CreateNavVC") as? UINavigationController else { return }
        if let createVC = createNav.viewControllers.first(
            where: { $0 is CreateGroupViewController }) as? CreateGroupViewController {
            createVC.delegate = self
        }
        createNav.modalPresentationStyle = .pageSheet
        present(createNav, animated: true)
    }

    func didJoinGroup(_ group: Group) {
        myGroups.insert(group, at: 0)
        groupsTableView.beginUpdates()
        groupsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        groupsTableView.endUpdates()
        updateEmptyState()
        Task {
            let msg = await SupabaseManager.shared.fetchLastMessage(for: group.id)
            await MainActor.run {
                lastMessages[group.id] = msg
                groupsTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }
        let storyboard = UIStoryboard(name: "Groups", bundle: nil)
        guard let chatVC = storyboard.instantiateViewController(
            withIdentifier: "ChatVC") as? ChatViewController else { return }
        chatVC.group = group
        chatVC.updateDelegate = self
        navigationController?.pushViewController(chatVC, animated: true)
    }

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text?.lowercased() ?? ""
        if searchText.isEmpty {
            isSearching = false
            filteredGroups.removeAll()
        } else {
            isSearching = true
            filteredGroups = myGroups.filter { $0.name.lowercased().contains(searchText) }
        }
        groupsTableView.reloadData()
        updateEmptyState()
    }
}

// MARK: - CreateGroupDelegate

extension GroupsViewController: CreateGroupDelegate {
    func didCreateGroup(_ group: Group) {
        myGroups.insert(group, at: 0)
        lastMessages[group.id] = "No messages yet"
        groupsTableView.beginUpdates()
        groupsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        groupsTableView.endUpdates()
        groupsTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        updateEmptyState()
    }
}

// MARK: - LeaveGroupDelegate

extension GroupsViewController: LeaveGroupDelegate {
    func didLeaveGroup(_ group: Group) {
        if let idx = myGroups.firstIndex(where: { $0.id == group.id }) {
            myGroups.remove(at: idx)
            lastMessages.removeValue(forKey: group.id)
            groupsTableView.beginUpdates()
            groupsTableView.deleteRows(at: [IndexPath(row: idx, section: 0)], with: .automatic)
            groupsTableView.endUpdates()
            updateEmptyState()
        }
    }
}
