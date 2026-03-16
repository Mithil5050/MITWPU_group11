//
//  GroupSettingsViewController.swift
//  Group_11_Revisio
//

import UIKit
import Supabase

class GroupSettingsViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var infoView:  UIView!
    @IBOutlet weak var docsView:  UIView!
    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var linksView: UIView!

    @IBOutlet weak var groupImageView:    UIImageView!
    @IBOutlet weak var groupNameLabel:    UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!

    @IBOutlet weak var membersCollectionView: UICollectionView!
    @IBOutlet weak var docsCollectionView:    UICollectionView!
    @IBOutlet weak var mediaCollectionView:   UICollectionView!
    @IBOutlet weak var linksTableView:        UITableView!
    @IBOutlet weak var hideAlertsSwitch:      UISwitch!

    var group: Group!
    weak var delegate:       LeaveGroupDelegate?
    weak var updateDelegate: GroupUpdateDelegate?

    private var members:   [SupabaseManager.GroupMember] = []
    private var inviteCode = ""
    private var documents:  [SupabaseManager.GroupFile] = []
    private var mediaFiles: [SupabaseManager.GroupFile] = []
    private var linkFiles:  [SupabaseManager.GroupFile] = []
    private var imageCache: [String: UIImage] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        guard group != nil else {
            navigationController?.popViewController(animated: true)
            return
        }

        groupNameLabel.text    = group.name
        membersCountLabel.text = "Loading..."

        segmentedControl.selectedSegmentIndex = 0
        showSegment(index: 0)

        groupImageView.contentMode   = .scaleAspectFill
        groupImageView.clipsToBounds = true
        // corner radius set in viewDidAppear after layout finishes
        groupImageView.isUserInteractionEnabled = true
        groupImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit", style: .plain,
            target: self, action: #selector(editButtonTapped)
        )

        membersCollectionView.dataSource = self
        membersCollectionView.delegate   = self
        docsCollectionView.dataSource    = self
        docsCollectionView.delegate      = self
        mediaCollectionView.dataSource   = self
        mediaCollectionView.delegate     = self
        linksTableView.dataSource        = self
        linksTableView.delegate          = self

        if let l = mediaCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            l.estimatedItemSize = .zero
        }
        if let l = docsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            l.estimatedItemSize = .zero
        }

        Task { await loadAllData() }
    }

    // safe to set corner radius here — layout is stable
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        groupImageView.layer.cornerRadius = groupImageView.bounds.width / 2
        refreshAvatarImage()
    }

    // loads from URL or falls back to the default icon
    private func refreshAvatarImage() {
        if let urlString = group.avatarUrl, !urlString.isEmpty,
           let url = URL(string: urlString) {
            groupImageView.image    = UIImage(systemName: "person.3.fill")
            groupImageView.tintColor = .systemGray3
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.groupImageView.image    = img
                    self?.groupImageView.tintColor = nil
                }
            }.resume()
        } else {
            groupImageView.image    = UIImage(systemName: "person.3.fill")
            groupImageView.tintColor = .systemGray3
        }
    }

    @objc private func avatarTapped() {
        presentAvatarOptions()
    }

    // shared by avatar tap and the Edit button's "Change Group Avatar" option
    private func presentAvatarOptions() {
        let sheet = UIAlertController(title: "Group Photo",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Choose from Library",
                                      style: .default) { [weak self] _ in
            self?.openImagePicker()
        })
        if let url = group.avatarUrl, !url.isEmpty {
            sheet.addAction(UIAlertAction(title: "Remove Photo",
                                          style: .destructive) { [weak self] _ in
                self?.removeAvatar()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func openImagePicker() {
        let picker           = UIImagePickerController()
        picker.sourceType    = .photoLibrary
        picker.allowsEditing = true
        picker.delegate      = self
        present(picker, animated: true)
    }

    private func removeAvatar() {
        group.avatarUrl           = nil
        groupImageView.image      = UIImage(systemName: "person.3.fill")
        groupImageView.tintColor  = .systemGray3
        updateDelegate?.didUpdateGroup(group)
        Task {
            do { try await SupabaseManager.shared.updateGroupAvatar(id: group.id, avatarUrl: nil) }
            catch { print("removeAvatar: \(error)") }
        }
    }

    // Edit button shows rename + avatar options
    @objc private func editButtonTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Change Group Name",
                                      style: .default) { [weak self] _ in
            self?.presentRenameAlert()
        })
        sheet.addAction(UIAlertAction(title: "Change Group Avatar",
                                      style: .default) { [weak self] _ in
            self?.presentAvatarOptions()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func presentRenameAlert() {
        let alert = UIAlertController(title: "Edit Group Name",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { $0.text = self.group.name; $0.placeholder = "Group name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self.group.name        = name
            self.groupNameLabel.text = name
            self.updateDelegate?.didUpdateGroup(self.group)
            Task {
                do { try await SupabaseManager.shared.updateGroup(id: self.group.id,
                                                                   newName: name) }
                catch { print("rename: \(error)") }
            }
        })
        present(alert, animated: true)
    }

    // runs members, invite code, and file fetches in parallel
    private func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadMembers() }
            group.addTask { await self.loadInviteCode() }
            group.addTask { await self.loadFiles() }
        }
    }

    private func loadMembers() async {
        do {
            let fetched = try await SupabaseManager.shared.fetchMembers(for: group.id)
            await MainActor.run {
                members = fetched
                membersCountLabel.text =
                    "\(fetched.count) member\(fetched.count == 1 ? "" : "s")"
                membersCollectionView.reloadData()
            }
        } catch { print("loadMembers: \(error)") }
    }

    private func loadInviteCode() async {
        do {
            let code = try await SupabaseManager.shared.fetchInviteCode(for: group.id)
            await MainActor.run { inviteCode = code }
        } catch { print("loadInviteCode: \(error)") }
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
                applyEmptyState(docsCollectionView,  isEmpty: documents.isEmpty,
                                message: "No documents shared yet")
                applyEmptyState(mediaCollectionView, isEmpty: mediaFiles.isEmpty,
                                message: "No media shared yet")
            }
        } catch { print("loadFiles: \(error)") }
    }

    private func applyEmptyState(_ cv: UICollectionView,
                                  isEmpty: Bool, message: String) {
        if isEmpty {
            let lbl           = UILabel()
            lbl.text          = message
            lbl.textColor     = .secondaryLabel
            lbl.font          = .systemFont(ofSize: 15)
            lbl.textAlignment = .center
            lbl.numberOfLines = 0
            cv.backgroundView = lbl
        } else {
            cv.backgroundView = nil
        }
    }

    // remote image with in-memory cache
    private func loadRemoteImage(from urlString: String, into iv: UIImageView) {
        if let cached = imageCache[urlString] { iv.image = cached; return }
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.imageCache[urlString] = img; iv.image = img }
        }.resume()
    }

    // draws a circle with an initial letter for members without avatars
    private func initialsImage(_ initial: String) -> UIImage {
        let sz = CGSize(width: 44, height: 44)
        UIGraphicsBeginImageContextWithOptions(sz, false, 0)
        UIColor.systemGray4.setFill()
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: sz)).fill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let s    = initial as NSString
        let sSz  = s.size(withAttributes: attrs)
        s.draw(at: CGPoint(x: (sz.width  - sSz.width)  / 2,
                           y: (sz.height - sSz.height) / 2),
               withAttributes: attrs)
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        showSegment(index: sender.selectedSegmentIndex)
    }

    private func showSegment(index: Int) {
        UIView.animate(withDuration: 0.2) {
            self.infoView.isHidden  = index != 0
            self.docsView.isHidden  = index != 1
            self.mediaView.isHidden = index != 2
            self.linksView.isHidden = index != 3
        }
        if index == 1 { docsCollectionView.collectionViewLayout.invalidateLayout() }
        if index == 2 { mediaCollectionView.collectionViewLayout.invalidateLayout() }
    }

    @IBAction func leaveButtonTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Leave Group",
                                   message: "Are you sure?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            self.performLeave()
        })
        present(ac, animated: true)
    }

    private func performLeave() {
        Task {
            do {
                guard let uid = SupabaseManager.shared.client.auth.currentUser?.id,
                      let gid = UUID(uuidString: group.id) else { return }
                try await SupabaseManager.shared.client.from("group_members").delete()
                    .eq("user_id",  value: uid)
                    .eq("group_id", value: gid)
                    .execute()
            } catch { print("leave: \(error)") }
        }
        delegate?.didLeaveGroup(group)
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension GroupSettingsViewController:
    UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let img  = info[.editedImage]   as? UIImage
                      ?? info[.originalImage] as? UIImage,
              let data = img.jpegData(compressionQuality: 0.7) else { return }

        groupImageView.image    = img
        groupImageView.tintColor = nil

        Task {
            do {
                let url = try await SupabaseManager.shared.uploadGroupAvatar(
                    groupId: group.id, imageData: data)
                group.avatarUrl = url
                try await SupabaseManager.shared.updateGroupAvatar(
                    id: group.id, avatarUrl: url)
                updateDelegate?.didUpdateGroup(group)
            } catch { print("uploadGroupAvatar: \(error)") }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Collection View (Members / Docs / Media)

extension GroupSettingsViewController:
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if cv == membersCollectionView  { return members.count + 1 }
        if cv == docsCollectionView     { return documents.count   }
        if cv == mediaCollectionView    { return mediaFiles.count  }
        return 0
    }

    func collectionView(_ cv: UICollectionView,
                        cellForItemAt ip: IndexPath) -> UICollectionViewCell {

        if cv == membersCollectionView {
            let cell = cv.dequeueReusableCell(
                withReuseIdentifier: "MemberCellIdentifier", for: ip) as! MemberCell
            if ip.item == members.count {
                cell.nameLabel.text        = "Add"
                cell.avatarImageView.image  = UIImage(systemName: "plus.circle.fill")
                cell.avatarImageView.tintColor = .systemGray4
                return cell
            }
            let m    = members[ip.item]
            let isMe = m.userId ==
                SupabaseManager.shared.client.auth.currentUser?.id.uuidString
            cell.configure(name: isMe ? "You" : m.username)
            if let u = m.avatarUrl, !u.isEmpty {
                loadRemoteImage(from: u, into: cell.avatarImageView)
            } else {
                cell.avatarImageView.image = initialsImage(
                    String(m.username.prefix(1)).uppercased())
            }
            return cell
        }

        if cv == docsCollectionView {
            let cell = cv.dequeueReusableCell(
                withReuseIdentifier: "DocumentCellIdentifier", for: ip) as! DocumentCell
            cell.configure(filename: documents[ip.item].fileName)
            return cell
        }

        if cv == mediaCollectionView {
            let cell = cv.dequeueReusableCell(
                withReuseIdentifier: "MediaCell", for: ip) as! MediaCell
            let file = mediaFiles[ip.item]
            cell.configure(image: UIImage(systemName: "photo"))
            if let url = URL(string: file.fileUrl) {
                URLSession.shared.dataTask(with: url) { d, _, _ in
                    if let d = d, let img = UIImage(data: d) {
                        DispatchQueue.main.async { cell.configure(image: img) }
                    }
                }.resume()
            }
            return cell
        }

        return UICollectionViewCell()
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // add member cell → show invite code sheet
        if cv == membersCollectionView, ip.item == members.count {
            let sb = UIStoryboard(name: "Groups", bundle: nil)
            guard let codeVC = sb.instantiateViewController(
                withIdentifier: "GroupCodeVC") as? GroupCodeViewController else { return }
            codeVC.configure(withGroupName: group?.name ?? "Group", code: inviteCode)
            codeVC.isFromCreateGroup = false
            let nav = UINavigationController(rootViewController: codeVC)
            nav.modalPresentationStyle = .pageSheet
            present(nav, animated: true)
            return
        }

        if cv == mediaCollectionView {
            let file = mediaFiles[ip.item]
            guard let url = URL(string: file.fileUrl) else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    let vc  = MediaPreviewViewController()
                    vc.image = img
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self?.present(nav, animated: true)
                }
            }.resume()
            return
        }

        if cv == docsCollectionView {
            let file = documents[ip.item]
            guard let url = URL(string: file.fileUrl) else { return }
            let vc  = DocumentPreviewViewController()
            vc.documentURL = url
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    func collectionView(_ cv: UICollectionView,
                        layout _: UICollectionViewLayout,
                        sizeForItemAt ip: IndexPath) -> CGSize {
        if cv == membersCollectionView {
            let w = (cv.bounds.width - 48) / 3; return CGSize(width: w, height: w + 12)
        }
        if cv == mediaCollectionView {
            let w = (cv.bounds.width - 40) / 3; return CGSize(width: w, height: w)
        }
        if cv == docsCollectionView {
            let w = (cv.bounds.width - 36) / 3; return CGSize(width: w, height: w)
        }
        return .zero
    }

    func collectionView(_ cv: UICollectionView,
                        layout _: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        cv == docsCollectionView ? 6 : 0
    }

    func collectionView(_ cv: UICollectionView,
                        layout _: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        if cv == docsCollectionView  { return 6 }
        if cv == mediaCollectionView { return 8 }
        return 0
    }

    func collectionView(_ cv: UICollectionView,
                        layout _: UICollectionViewLayout,
                        insetForSectionAt _: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
}

// MARK: - Links Table View

extension GroupSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if linkFiles.isEmpty {
            let lbl           = UILabel()
            lbl.text          = "No links shared yet"
            lbl.textColor     = .secondaryLabel
            lbl.font          = .systemFont(ofSize: 15)
            lbl.textAlignment = .center
            tableView.backgroundView = lbl
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
        return linkFiles.count
    }

    func tableView(_ tv: UITableView,
                   heightForRowAt ip: IndexPath) -> CGFloat { 60 }

    func tableView(_ tv: UITableView,
                   cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "LinkCell", for: ip)
        let item = linkFiles[ip.row]
        cell.textLabel?.text            = item.fileName
        cell.textLabel?.font            = .systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.text      = item.fileUrl
        cell.detailTextLabel?.font      = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image           = UIImage(systemName: "link")
        cell.imageView?.tintColor       = .systemBlue
        cell.accessoryType              = .disclosureIndicator
        cell.selectionStyle             = .none
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        guard let url = URL(string: linkFiles[ip.row].fileUrl) else { return }
        UIApplication.shared.open(url)
    }
}
