import UIKit
import UniformTypeIdentifiers

// MARK: - Data Model

enum FileSourceType {
    case document
    case link
    case note
    case image
}

struct UploadedFileModel {
    let url: URL
    let type: FileSourceType
    
    var isAnalyzing: Bool = false
    var isWaiting: Bool = true
    var isExpanded: Bool = false
    var topics: [String] = []
    var selectedTopicIndices: Set<Int> = []
    
    var iconName: String {
        switch type {
        case .link: return "link"
        case .note: return "textformat"
        case .image: return "photo"
        case .document: return "doc.text"
        }
    }
}

class UploadConfirmationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ExpandableFileCellDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var UploadedContent: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    // MARK: - Properties
    var incomingDataPath: String?
    var filesData: [UploadedFileModel] = []
    
    // 🚦 RATE LIMIT QUEUE
    private var analysisQueue: [Int] = []
    private var isProcessingQueue: Bool = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
        processIncomingData()
        updateNextButtonState()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        if let btn = doneButton {
            btn.layer.cornerRadius = 12
            btn.clipsToBounds = true
        }
    }
    
    private func setupTable() {
        guard let table = UploadedContent else { return }
        table.dataSource = self
        table.delegate = self
        table.register(ExpandableFileCell.self, forCellReuseIdentifier: ExpandableFileCell.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .clear
    }
    
    // MARK: - Button State Validation
    private func updateNextButtonState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let isProcessing = self.filesData.contains { $0.isAnalyzing || $0.isWaiting }
            let totalSelectedTopics = self.filesData.reduce(0) { $0 + $1.selectedTopicIndices.count }
            
            // Disable if analyzing or if no topics are selected
            if isProcessing {
                self.doneButton.isEnabled = false
                self.doneButton.alpha = 0.5
                self.doneButton.setTitle("Analyzing...", for: .normal)
            } else if totalSelectedTopics > 0 {
                self.doneButton.isEnabled = true
                self.doneButton.alpha = 1.0
                self.doneButton.setTitle("Next", for: .normal)
            } else {
                self.doneButton.isEnabled = false
                self.doneButton.alpha = 0.5
                self.doneButton.setTitle("Next", for: .normal)
            }
        }
    }
    
    // MARK: - Data Processing
    func processIncomingData() {
        guard let dataString = incomingDataPath else { return }
        
        if FileManager.default.fileExists(atPath: dataString) {
            let url = URL(fileURLWithPath: dataString)
            let type: FileSourceType = ["jpg","png","jpeg"].contains(url.pathExtension.lowercased()) ? .image : .document
            addFile(url: url, type: type)
        } else {
            processTextOrLinkInput(text: dataString)
        }
    }
    
    private func processTextOrLinkInput(text: String) {
        let tempDir = FileManager.default.temporaryDirectory
        let isLink = text.lowercased().hasPrefix("http") || text.lowercased().hasPrefix("www")
        
        let safeName = text.prefix(20).replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "")
        let fileName = isLink ? "Link_\(safeName).txt" : "Note_\(safeName).txt"
        
        let tempFileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try text.write(to: tempFileURL, atomically: true, encoding: .utf8)
            addFile(url: tempFileURL, type: isLink ? .link : .note)
        } catch {
            print("❌ Failed to create temp file: \(error)")
        }
    }
    
    private func addFile(url: URL, type: FileSourceType) {
        ProgressDataManager.shared.totalDocumentsUploaded += 1
        var newFile = UploadedFileModel(url: url, type: type)
        newFile.isWaiting = true
        newFile.isAnalyzing = false
        
        let newIndex = filesData.count
        filesData.append(newFile)
        
        analysisQueue.append(newIndex)
        UploadedContent.reloadData()
        updateNextButtonState()
        
        processNextInQueue()
    }
    
    private func processNextInQueue() {
        guard !isProcessingQueue, !analysisQueue.isEmpty else { return }
        
        isProcessingQueue = true
        let fileIndex = analysisQueue.removeFirst()
        
        DispatchQueue.main.async {
            if fileIndex < self.filesData.count {
                self.filesData[fileIndex].isWaiting = false
                self.filesData[fileIndex].isAnalyzing = true
                self.UploadedContent.reloadRows(at: [IndexPath(row: fileIndex, section: 0)], with: .none)
                self.updateNextButtonState()
            }
        }
        
        Task {
            if fileIndex < self.filesData.count {
                let fileURL = self.filesData[fileIndex].url
                await analyzeTopics(for: fileURL, index: fileIndex)
            }
            
            try? await Task.sleep(nanoseconds: 4 * 1_000_000_000)
            
            self.isProcessingQueue = false
            self.processNextInQueue()
        }
    }
    
    // MARK: - AI Topic Extraction
    private func analyzeTopics(for url: URL, index: Int, attempt: Int = 1) async {
        let text = await ContentExtractor.shared.extractContent(from: url)
        
        let prompt = """
        Analyze the following text and identify 4 to 6 main topics.
        Return ONLY the list of topic names, one per line. Do NOT use emojis, bullet points, or numbering.
        TEXT TO ANALYZE:
        \(String(text.prefix(4000)))
        """
        
        do {
            let aiResponse = try await AIContentManager.shared.generateContent(
                topic: prompt,
                type: "Notes",
                count: 5,
                difficulty: "Medium"
            )
            
            let rawTopics = aiResponse.components(separatedBy: .newlines)
            let extractedTopics = rawTopics
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { $0.replacingOccurrences(of: "^[0-9]+\\.\\s*", with: "", options: .regularExpression) }
                .map { $0.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression) }
                .filter { !$0.isEmpty && $0.count < 60 }
            
            DispatchQueue.main.async {
                if index < self.filesData.count {
                    self.filesData[index].topics = extractedTopics.isEmpty ? ["General Content"] : extractedTopics
                    self.filesData[index].selectedTopicIndices = Set(0..<self.filesData[index].topics.count)
                    self.filesData[index].isAnalyzing = false
                    self.UploadedContent.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.updateNextButtonState()
                }
            }
            
        } catch {
            if attempt < 3 {
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                await analyzeTopics(for: url, index: index, attempt: attempt + 1)
            } else {
                DispatchQueue.main.async {
                    if index < self.filesData.count {
                        self.filesData[index].topics = ["General Content"]
                        self.filesData[index].selectedTopicIndices = [0]
                        self.filesData[index].isAnalyzing = false
                        self.UploadedContent.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        self.updateNextButtonState()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func DoneTapped(_ sender: Any) {
        var finalFiles: [URL] = []
        for fileData in filesData {
            if !fileData.topics.isEmpty && fileData.selectedTopicIndices.count < fileData.topics.count {
                let selectedNames = fileData.selectedTopicIndices.map { fileData.topics[$0] }
                let instructions = "SOURCE FILE: \(fileData.url.lastPathComponent)\nTOPICS: \(selectedNames.joined(separator: ", "))"
                let tempDir = FileManager.default.temporaryDirectory
                let filteredName = "Filtered_\(fileData.url.deletingPathExtension().lastPathComponent).txt"
                let filteredURL = tempDir.appendingPathComponent(filteredName)
                try? instructions.write(to: filteredURL, atomically: true, encoding: .utf8)
                finalFiles.append(filteredURL)
            } else {
                finalFiles.append(fileData.url)
            }
        }
        performSegue(withIdentifier: "showSelectMaterial", sender: finalFiles)
    }
    
    @IBAction func didTapAddButton(_ sender: Any) {
        let alert = UIAlertController(title: "Add Material", message: "Choose a source", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Document", style: .default, handler: { _ in self.openDocumentPicker() }))
        alert.addAction(UIAlertAction(title: "Photo / Media", style: .default, handler: { _ in self.openPhotoPicker() }))
        alert.addAction(UIAlertAction(title: "Web Link", style: .default, handler: { _ in self.showTextInput(title: "Add Web Link", placeholder: "https://example.com") }))
        alert.addAction(UIAlertAction(title: "Text Note", style: .default, handler: { _ in self.showTextInput(title: "Add Quick Note", placeholder: "Enter note title...") }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - TableView Data Source & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExpandableFileCell.identifier, for: indexPath) as? ExpandableFileCell else {
            return UITableViewCell()
        }
        
        let file = filesData[indexPath.row]
        
        // ✅ FIXED: Removed 'customName' argument to match ExpandableFileCell's original signature
        cell.configure(with: file, index: indexPath.row)
        
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var file = filesData[indexPath.row]
        if !file.isAnalyzing && !file.isWaiting && !file.topics.isEmpty {
            file.isExpanded.toggle()
            filesData[indexPath.row] = file
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func didToggleTopic(fileIndex: Int, topicIndex: Int) {
        var file = filesData[fileIndex]
        if file.selectedTopicIndices.contains(topicIndex) {
            file.selectedTopicIndices.remove(topicIndex)
        } else {
            file.selectedTopicIndices.insert(topicIndex)
        }
        filesData[fileIndex] = file
        UploadedContent.reloadRows(at: [IndexPath(row: fileIndex, section: 0)], with: .none)
        updateNextButtonState()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSelectMaterial" {
            if let destVC = segue.destination as? SelectMaterialViewController,
               let files = sender as? [URL] {
                destVC.filesToSave = files
            }
        }
    }
    
    // MARK: - Helper Methods
    private func openDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText, .image], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func openPhotoPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showTextInput(title: String, placeholder: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = placeholder }
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.processTextOrLinkInput(text: text)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func cleanDisplayName(for url: URL) -> String {
        let rawName = url.lastPathComponent
        return rawName.replacingOccurrences(of: ".txt", with: "")
                      .replacingOccurrences(of: "Note_", with: "")
                      .replacingOccurrences(of: "Link_", with: "")
                      .replacingOccurrences(of: "Image_", with: "")
                      .replacingOccurrences(of: "Filtered_", with: "")
                      .replacingOccurrences(of: "_", with: " ")
    }
}

// MARK: - Delegates Extension
extension UploadConfirmationViewController: UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            let tempDir = FileManager.default.temporaryDirectory
            let destURL = tempDir.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: destURL)
            addFile(url: destURL, type: .document)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.8) else { return }
            
            let filename = "Image_\(Int(Date().timeIntervalSince1970)).jpg"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? data.write(to: tempURL)
            self.addFile(url: tempURL, type: .image)
        }
    }
}
