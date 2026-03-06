//
//  GroupSettingsViewController.swift
//  Group_11_Revisio
//

import UIKit
import Supabase

class GroupSettingsViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var docsView: UIView!
    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var linksView: UIView!

    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!

    @IBOutlet weak var membersCollectionView: UICollectionView!
    @IBOutlet weak var docsCollectionView: UICollectionView!
    @IBOutlet weak var mediaCollectionView: UICollectionView!
    @IBOutlet weak var linksTableView: UITableView!
    @IBOutlet weak var hideAlertsSwitch: UISwitch!

    // MARK: - Data
    var group: Group!
    weak var delegate: LeaveGroupDelegate?
    weak var updateDelegate: GroupUpdateDelegate?

    private var members:   [SupabaseManager.GroupMember] = []
    private var inviteCode: String = ""
    private var documents:  [SupabaseManager.GroupFile] = []
    private var mediaFiles: [SupabaseManager.GroupFile] = []
    private var linkFiles:  [SupabaseManager.GroupFile] = []
    private var imageCache: [String: UIImage] = [:]

    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        guard group != nil else {
            print("❌ Group is NIL in GroupSettingsViewController")
            navigationController?.popViewController(animated: true)
            return
        }

        segmentedControl.selectedSegmentIndex = 0
        showSegment(index: 0)

        groupNameLabel.text    = group.name
        membersCountLabel.text = "Loading..."
        configureGroupAvatar()

        // Tap on avatar to change/remove
        groupImageView.isUserInteractionEnabled = true
        groupImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit", style: .plain, target: self, action: #selector(editButtonTapped)
        )

        membersCollectionView.dataSource = self
        membersCollectionView.delegate   = self
        docsCollectionView.dataSource    = self
        docsCollectionView.delegate      = self
        mediaCollectionView.dataSource   = self
        mediaCollectionView.delegate     = self
        linksTableView.dataSource        = self
        linksTableView.delegate          = self

        if let layout = mediaCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
        }
        if let layout = docsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
        }

        Task { await loadAllData() }
    }

    // MARK: - Avatar Display
    private func configureGroupAvatar() {
        groupImageView.contentMode = .scaleAspectFill
        groupImageView.clipsToBounds = true
        if let urlString = group.avatarUrl, !urlString.isEmpty, let url = URL(string: urlString) {
            groupImageView.image = UIImage(systemName: "person.3.fill")
            groupImageView.tintColor = .systemGray3
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.groupImageView.image = img
                    self?.groupImageView.tintColor = nil
                }
            }.resume()
        } else {
            groupImageView.image = UIImage(systemName: "person.3.fill")
            groupImageView.tintColor = .systemGray3
        }
    }

    // MARK: - Avatar Tap
    @objc private func avatarTapped() {
        let sheet = UIAlertController(title: "Group Photo", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Choose Photo", style: .default) { [weak self] _ in
            self?.presentImagePicker()
        })
        if group.avatarUrl != nil {
            sheet.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { [weak self] _ in
                self?.removeAvatar()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate   = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func removeAvatar() {
        group.avatarUrl = nil
        configureGroupAvatar()
        updateDelegate?.didUpdateGroup(group)
        Task {
            do { try await SupabaseManager.shared.updateGroupAvatar(id: group.id, avatarUrl: nil) }
            catch { print("❌ Failed to remove avatar: \(error)") }
        }
    }

    // MARK: - Load All Data
    private func loadAllData() async {
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask { await self.loadMembers() }
            taskGroup.addTask { await self.loadInviteCode() }
            taskGroup.addTask { await self.loadFiles() }
        }
    }

    private func loadMembers() async {
        do {
            let fetched = try await SupabaseManager.shared.fetchMembers(for: group.id)
            await MainActor.run {
                members = fetched
                membersCountLabel.text = "\(fetched.count) member\(fetched.count == 1 ? "" : "s")"
                membersCollectionView.reloadData()
            }
        } catch { print("❌ Failed to load members: \(error)") }
    }

    private func loadInviteCode() async {
        do {
            let code = try await SupabaseManager.shared.fetchInviteCode(for: group.id)
            await MainActor.run { inviteCode = code }
        } catch { print("❌ Failed to load invite code: \(error)") }
    }

    private func loadFiles() async {
        do {
            let all = try await SupabaseManager.shared.fetchGroupFiles(for: group.id)
            await MainActor.run {
                documents  = all.filter { $0.fileType == "document" }
                mediaFiles = all.filter { $0.fileType == "image" }
                linkFiles  = all.filter { $0.fileType == "link" }
                docsCollectionView.reloadData()
                mediaCollectionView.reloadData()
                linksTableView.reloadData()
                setEmptyState(for: docsCollectionView,
                              isEmpty: documents.isEmpty,
                              message: "No documents shared yet")
                setEmptyState(for: mediaCollectionView,
                              isEmpty: mediaFiles.isEmpty,
                              message: "No media shared yet")
            }
        } catch { print("❌ Failed to load files: \(error)") }
    }

    private func setEmptyState(for collectionView: UICollectionView,
                                isEmpty: Bool, message: String) {
        if isEmpty {
            let label = UILabel()
            label.text          = message
            label.textColor     = .secondaryLabel
            label.font          = UIFont.systemFont(ofSize: 15)
            label.textAlignment = .center
            label.numberOfLines = 0
            collectionView.backgroundView = label
        } else {
            collectionView.backgroundView = nil
        }
    }

    // MARK: - Image Loading Helpers
    private func loadImage(from urlString: String, into imageView: UIImageView) {
        if let cached = imageCache[urlString] { imageView.image = cached; return }
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageCache[urlString] = img
                imageView.image = img
            }
        }.resume()
    }

    private func makeInitialsImage(_ initials: String) -> UIImage {
        let size = CGSize(width: 44, height: 44)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.systemGray4.setFill()
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let str = initials as NSString
        let strSize = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: (size.width - strSize.width) / 2,
                             y: (size.height - strSize.height) / 2),
                 withAttributes: attrs)
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }

    // MARK: - Edit Button (name only)
    @objc private func editButtonTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Change Group Name", style: .default) { [weak self] _ in
            self?.presentRenameGroup()
        })
        sheet.addAction(UIAlertAction(title: "Change Group Avatar", style: .default) { [weak self] _ in
            self?.presentImagePicker()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func presentRenameGroup() {
        let alert = UIAlertController(title: "Edit Group Name", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Group name"; $0.text = self.group.name }
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text,
                  !newName.isEmpty else { return }
            self.group.name = newName
            self.groupNameLabel.text = newName
            self.updateDelegate?.didUpdateGroup(self.group)
            Task {
                do { try await SupabaseManager.shared.updateGroup(id: self.group.id, newName: newName) }
                catch { print("❌ Failed to update group name: \(error)") }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Segment Control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        showSegment(index: sender.selectedSegmentIndex)
    }

    private func showSegment(index: Int) {
        UIView.animate(withDuration: 0.2) {
            self.infoView.isHidden  = index != 0
            self.docsView.isHidden  = index != 1
            self.mediaView.isHidden = index != 2
            self.linksView.isHidden = index != 3
            if index == 1 {
                self.docsCollectionView.reloadData()
                self.docsCollectionView.collectionViewLayout.invalidateLayout()
            }
            if index == 2 {
                self.mediaCollectionView.reloadData()
                self.mediaCollectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }

    // MARK: - Leave Group
    @IBAction func leaveButtonTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Leave Group",
                                   message: "Are you sure you want to leave this group?",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in self.performLeave() })
        present(ac, animated: true)
    }

    private func performLeave() {
        guard let group = self.group else {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        Task {
            do {
                guard let userId    = SupabaseManager.shared.client.auth.currentUser?.id,
                      let groupUUID = UUID(uuidString: group.id) else { return }
                try await SupabaseManager.shared.client
                    .from("group_members").delete()
                    .eq("user_id",  value: userId)
                    .eq("group_id", value: groupUUID)
                    .execute()
            } catch { print("❌ Failed to leave group: \(error)") }
        }
        delegate?.didLeaveGroup(group)
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension GroupSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.7) else { return }

        groupImageView.image = image
        groupImageView.tintColor = nil

        Task {
            do {
                let url = try await SupabaseManager.shared.uploadGroupAvatar(groupId: group.id, imageData: data)
                group.avatarUrl = url
                updateDelegate?.didUpdateGroup(group)
                try await SupabaseManager.shared.updateGroupAvatar(id: group.id, avatarUrl: url)
            } catch { print("❌ Failed to upload avatar: \(error)") }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Collection View
extension GroupSettingsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if collectionView == membersCollectionView { return members.count + 1 }
        if collectionView == docsCollectionView    { return documents.count }
        if collectionView == mediaCollectionView   { return mediaFiles.count }
        return 0
    }

    // Empty state for docs and media
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // MARK: Members
        if collectionView == membersCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "MemberCellIdentifier", for: indexPath) as! MemberCell
            if indexPath.item == members.count {
                cell.nameLabel.text = "Add"
                cell.avatarImageView.image = UIImage(systemName: "plus.circle.fill")
                cell.avatarImageView.tintColor = .systemGray4
                return cell
            }
            let member = members[indexPath.item]
            let isCurrentUser = member.userId ==
                SupabaseManager.shared.client.auth.currentUser?.id.uuidString
            cell.configure(name: isCurrentUser ? "You" : member.username)
            if let avatarUrl = member.avatarUrl, !avatarUrl.isEmpty {
                cell.avatarImageView.image = nil
                loadImage(from: avatarUrl, into: cell.avatarImageView)
            } else {
                cell.avatarImageView.image = makeInitialsImage(
                    String(member.username.prefix(1)).uppercased()
                )
            }
            return cell
        }

        // MARK: Documents
        if collectionView == docsCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "DocumentCellIdentifier", for: indexPath) as! DocumentCell
            cell.configure(filename: documents[indexPath.item].fileName)
            return cell
        }

        // MARK: Media
        if collectionView == mediaCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
            let file = mediaFiles[indexPath.item]
            cell.configure(image: UIImage(systemName: "photo"))
            if let url = URL(string: file.fileUrl) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let img = UIImage(data: data) {
                        DispatchQueue.main.async { cell.configure(image: img) }
                    }
                }.resume()
            }
            return cell
        }

        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if collectionView == membersCollectionView, indexPath.item == members.count {
            let storyboard = UIStoryboard(name: "Groups", bundle: nil)
            guard let codeVC = storyboard.instantiateViewController(
                withIdentifier: "GroupCodeVC") as? GroupCodeViewController else { return }
            codeVC.configure(withGroupName: group?.name ?? "Group", code: inviteCode)
            codeVC.isFromCreateGroup = false
            let nav = UINavigationController(rootViewController: codeVC)
            nav.modalPresentationStyle = .pageSheet
            present(nav, animated: true)
            return
        }

        if collectionView == mediaCollectionView {
            let file = mediaFiles[indexPath.item]
            guard let url = URL(string: file.fileUrl) else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    let previewVC = MediaPreviewViewController()
                    previewVC.image = img
                    let nav = UINavigationController(rootViewController: previewVC)
                    nav.modalPresentationStyle = .fullScreen
                    self?.present(nav, animated: true)
                }
            }.resume()
            return
        }

        if collectionView == docsCollectionView {
            let file = documents[indexPath.item]
            guard let url = URL(string: file.fileUrl) else { return }
            let previewVC = DocumentPreviewViewController()
            previewVC.documentURL = url
            let nav = UINavigationController(rootViewController: previewVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionView == docsCollectionView ? 6 : 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == docsCollectionView  { return 6 }
        if collectionView == mediaCollectionView { return 8 }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == membersCollectionView {
            let w = (collectionView.bounds.width - 48) / 3
            return CGSize(width: w, height: w + 12)
        }
        if collectionView == mediaCollectionView {
            let w = (collectionView.bounds.width - 40) / 3
            return CGSize(width: w, height: w)
        }
        if collectionView == docsCollectionView {
            let w = (collectionView.bounds.width - 36) / 3
            return CGSize(width: w, height: w)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
}

// MARK: - Links Table View
extension GroupSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if linkFiles.isEmpty {
            let label = UILabel()
            label.text          = "No links shared yet"
            label.textColor     = .secondaryLabel
            label.font          = UIFont.systemFont(ofSize: 15)
            label.textAlignment = .center
            tableView.backgroundView = label
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
        return linkFiles.count
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { return 60 }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LinkCell", for: indexPath)
        let item = linkFiles[indexPath.row]
        cell.textLabel?.text            = item.fileName
        cell.textLabel?.font            = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.text      = item.fileUrl
        cell.detailTextLabel?.font      = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType              = .disclosureIndicator
        cell.selectionStyle             = .none
        cell.imageView?.image           = UIImage(systemName: "link")
        cell.imageView?.tintColor       = .systemBlue
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let url = URL(string: linkFiles[indexPath.row].fileUrl) else { return }
        UIApplication.shared.open(url)
    }
}
