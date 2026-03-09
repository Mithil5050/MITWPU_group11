import UIKit
import MessageKit
import InputBarAccessoryView
import UniformTypeIdentifiers

// MARK: - Local AI Models
private struct ChatParsedAIFlashcard: Codable {
    let front: String?
    let back: String?
    let term: String?
    let definition: String?
    
    var safeFront: String { return front ?? term ?? "Term" }
    var safeBack: String { return back ?? definition ?? "Definition" }
}

// MARK: - Persistence Models
struct SavedChatMessage: Codable {
    let senderId: String
    let displayName: String
    let messageId: String
    let sentDate: Date
    let text: String
}

struct ChatSession: Codable {
    let id: String
    var title: String
    let date: Date
    var messages: [SavedChatMessage]
}

class AIChatViewController: MessagesViewController {
    
    // MARK: - Properties
    let currentUser = AIChatSender(senderId: "user_current", displayName: "Me")
    let aiAgent = AIChatSender(senderId: "ai_exora_agent", displayName: "Exora")
    
    var aiMessages: [AIChatMessage] = []
    
    // Persistence Properties
    var currentSessionId: String = UUID().uuidString
    let defaults = UserDefaults.standard
    let savedChatsKey = "Exora_Saved_Chats"
    
    // MARK: - Drawer UI Elements
    private lazy var historyDimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        view.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideHistory))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private lazy var historyDrawerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 5, height: 0)
        view.layer.shadowRadius = 15
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(hideHistory))
        swipe.direction = .left
        view.addGestureRecognizer(swipe)
        
        return view
    }()
    
    private lazy var historyTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        
        // Auto-sizing rows to prevent text overlap
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 56
        
        table.register(HistoryCell.self, forCellReuseIdentifier: "HistoryCell")
        return table
    }()
    
    private var sortedSessions: [ChatSession] = []
    private var drawerWidth: CGFloat { view.bounds.width * 0.8 }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomNavigationBar()
        setupMessageKit()
        setupInputBar()
        
        startNewChat()
    }
    
    // MARK: - UI Setup
    private func setupCustomNavigationBar() {
        let titleStack = UIStackView()
        titleStack.axis = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .center
        
        let avatarImageView = UIImageView()
        avatarImageView.image = UIImage(named: "Chatbot") ?? UIImage(systemName: "sparkles.tv")
        avatarImageView.tintColor = .systemPurple
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.clipsToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        let nameLabel = UILabel()
        nameLabel.text = "Exora"
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        
        let crownImageView = UIImageView(image: UIImage(systemName: "crown.fill"))
        crownImageView.tintColor = .systemPurple
        crownImageView.contentMode = .scaleAspectFit
        crownImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            crownImageView.widthAnchor.constraint(equalToConstant: 16),
            crownImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        titleStack.addArrangedSubview(avatarImageView)
        titleStack.addArrangedSubview(nameLabel)
        titleStack.addArrangedSubview(crownImageView)
        
        navigationItem.titleView = titleStack
        
        // ✅ Left Side: Leave blank so iOS automatically uses the native Back button!
        navigationItem.leftBarButtonItems = nil
        
        // ✅ Right Side: Menu Button and New Chat Button
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(showHistory)
        )
        menuButton.tintColor = .label
        
        let newChatButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(startNewChat)
        )
        newChatButton.tintColor = .label
        
        // The first item in the array appears furthest to the right.
        navigationItem.rightBarButtonItems = [newChatButton, menuButton]
    }
    
    private func setupMessageKit() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messagesCollectionView.backgroundColor = .systemBackground
        scrollsToLastItemOnKeyboardBeginsEditing = true
        showMessageTimestampOnSwipeLeft = true
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = CGSize(width: 32, height: 32)
            layout.setMessageIncomingAvatarPosition(.init(vertical: .messageTop))
        }
    }
    
    private func setupInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.placeholder = "Message Exora..."
        messageInputBar.inputTextView.placeholderTextColor = .systemGray2
        
        messageInputBar.inputTextView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
        messageInputBar.inputTextView.layer.cornerRadius = 20
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        messageInputBar.inputTextView.font = .systemFont(ofSize: 16)
        
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.separatorLine.isHidden = true
        
        // ✅ Modern Arrow Send Button (Replaces default text and mic)
        messageInputBar.sendButton.setTitle(nil, for: .normal)
        let sendConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        messageInputBar.sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: sendConfig), for: .normal)
        messageInputBar.sendButton.tintColor = .systemBlue
        messageInputBar.sendButton.setSize(CGSize(width: 40, height: 40), animated: false)
        
        let plusButton = InputBarButtonItem()
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.tintColor = .label
        plusButton.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
        plusButton.layer.cornerRadius = 20
        plusButton.clipsToBounds = true
        plusButton.setSize(CGSize(width: 40, height: 40), animated: false)
        plusButton.addTarget(self, action: #selector(handleUploadTap), for: .touchUpInside)
        
        let spacer = InputBarButtonItem()
        spacer.setSize(CGSize(width: 12, height: 40), animated: false)
        spacer.isEnabled = false
        
        messageInputBar.setStackViewItems([plusButton, spacer], forStack: .left, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 52, animated: false)
        
        // ✅ Right side only has the Send button now
        messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: false)
    }
    
    // MARK: - Actions
    @objc func handleUploadTap() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "✨ Generate Study Material", style: .default, handler: { _ in self.presentMaterialMenu() }))
        alert.addAction(UIAlertAction(title: "Upload Photo", style: .default, handler: { _ in self.presentPhotoPicker() }))
        alert.addAction(UIAlertAction(title: "Upload Document", style: .default, handler: { _ in self.presentDocumentPicker() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentMaterialMenu() {
        let alert = UIAlertController(title: "Generate Material", message: "What would you like Exora to create?", preferredStyle: .actionSheet)
        let types = ["Quiz", "Flashcards", "Notes", "Cheatsheet"]
        for type in types {
            alert.addAction(UIAlertAction(title: type, style: .default, handler: { _ in self.askForTopic(for: type) }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func askForTopic(for type: String) {
        let alert = UIAlertController(title: "Topic", message: "What should this \(type) be about?", preferredStyle: .alert)
        alert.addTextField { field in field.placeholder = "e.g. Photosynthesis, SQL, Math..." }
        alert.addAction(UIAlertAction(title: "Generate", style: .default, handler: { [weak self] _ in
            guard let topic = alert.textFields?.first?.text, !topic.isEmpty else { return }
            self?.performMaterialGeneration(rawType: type, topic: topic)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Chat Persistence & New Drawer
    @objc private func startNewChat() {
        currentSessionId = UUID().uuidString
        
        let greeting = AIChatMessage(
            sender: aiAgent,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text("Hello! I'm Exora. Ask me a question, or tell me to generate a Quiz, Flashcards, Notes, or a Cheatsheet!")
        )
        
        aiMessages = [greeting]
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
    }
    
    private func saveCurrentSession() {
        var allSessions = getAllSessions()
        let savedMsgs = aiMessages.compactMap { msg -> SavedChatMessage? in
            if case .text(let txt) = msg.kind {
                return SavedChatMessage(senderId: msg.sender.senderId, displayName: msg.sender.displayName, messageId: msg.messageId, sentDate: msg.sentDate, text: txt)
            }
            return nil
        }
        
        let userMessage = savedMsgs.first(where: { $0.senderId == currentUser.senderId })?.text
        let defaultTitle = "New Chat"
        let title = userMessage != nil ? String(userMessage!.prefix(30)) + (userMessage!.count > 30 ? "..." : "") : defaultTitle
        
        let session = ChatSession(id: currentSessionId, title: title, date: Date(), messages: savedMsgs)
        allSessions[currentSessionId] = session
        
        if let data = try? JSONEncoder().encode(allSessions) {
            defaults.set(data, forKey: savedChatsKey)
        }
    }
    
    private func getAllSessions() -> [String: ChatSession] {
        guard let data = defaults.data(forKey: savedChatsKey),
              let sessions = try? JSONDecoder().decode([String: ChatSession].self, from: data) else { return [:] }
        return sessions
    }
    
    // MARK: - Custom Side Drawer UI
    @objc private func showHistory() {
        if historyDrawerView.superview == nil {
            guard let window = view.window else { return }
            
            window.addSubview(historyDimmingView)
            window.addSubview(historyDrawerView)
            
            historyDimmingView.frame = window.bounds
            historyDrawerView.frame = CGRect(x: -drawerWidth, y: 0, width: drawerWidth, height: window.bounds.height)
            
            setupDrawerContent()
        }
        
        sortedSessions = getAllSessions().values.sorted(by: { $0.date > $1.date })
        historyTableView.reloadData()
        
        historyDimmingView.isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.historyDimmingView.alpha = 1
            self.historyDrawerView.transform = CGAffineTransform(translationX: self.drawerWidth, y: 0)
        }
    }
    
    @objc private func hideHistory() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.historyDimmingView.alpha = 0
            self.historyDrawerView.transform = .identity
        }) { _ in
            self.historyDimmingView.isHidden = true
        }
    }
    
    private func setupDrawerContent() {
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        let searchBar = UISearchBar()
        searchBar.placeholder = "Find chat"
        searchBar.searchBarStyle = .minimal
        searchBar.isUserInteractionEnabled = false
        
        let newChatBtn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        newChatBtn.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: config), for: .normal)
        newChatBtn.tintColor = .label
        newChatBtn.addTarget(self, action: #selector(newChatFromDrawer), for: .touchUpInside)
        
        headerStack.addArrangedSubview(searchBar)
        headerStack.addArrangedSubview(newChatBtn)
        
        historyDrawerView.addSubview(headerStack)
        historyDrawerView.addSubview(historyTableView)
        historyTableView.translatesAutoresizingMaskIntoConstraints = false
        
        let safeTop = view.window?.safeAreaInsets.top ?? 44
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: historyDrawerView.topAnchor, constant: safeTop),
            headerStack.leadingAnchor.constraint(equalTo: historyDrawerView.leadingAnchor, constant: 8),
            headerStack.trailingAnchor.constraint(equalTo: historyDrawerView.trailingAnchor, constant: -16),
            headerStack.heightAnchor.constraint(equalToConstant: 50),
            
            newChatBtn.widthAnchor.constraint(equalToConstant: 44),
            
            historyTableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            historyTableView.leadingAnchor.constraint(equalTo: historyDrawerView.leadingAnchor),
            historyTableView.trailingAnchor.constraint(equalTo: historyDrawerView.trailingAnchor),
            historyTableView.bottomAnchor.constraint(equalTo: historyDrawerView.bottomAnchor)
        ])
    }
    
    @objc private func newChatFromDrawer() {
        hideHistory()
        startNewChat()
    }
    
    private func loadSession(_ session: ChatSession) {
        currentSessionId = session.id
        aiMessages = session.messages.map { savedMsg in
            let sender = savedMsg.senderId == currentUser.senderId ? currentUser : aiAgent
            return AIChatMessage(sender: sender, messageId: savedMsg.messageId, sentDate: savedMsg.sentDate, kind: .text(savedMsg.text))
        }
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
        hideHistory()
    }
    
    // MARK: - Messaging Helpers
    func insertMessage(_ message: AIChatMessage) {
        let wasEmpty = aiMessages.isEmpty
        aiMessages.append(message)
        
        if wasEmpty {
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem(animated: true)
            saveCurrentSession()
        } else {
            messagesCollectionView.performBatchUpdates({
                messagesCollectionView.insertSections([aiMessages.count - 1])
                if aiMessages.count >= 2 {
                    messagesCollectionView.reloadSections([aiMessages.count - 2])
                }
            }, completion: { [weak self] _ in
                self?.messagesCollectionView.scrollToLastItem(animated: true)
                self?.saveCurrentSession()
            })
        }
    }
    
    // MARK: - Core AI Chat Call
    func fetchAIResponse(for text: String) {
        setTypingIndicatorViewHidden(false, animated: true)
        messagesCollectionView.scrollToLastItem(animated: true)
        
        Task {
            let systemPrompt = """
            URGENT OVERRIDE: IGNORE ANY INSTRUCTIONS ASKING FOR JSON, QUIZZES, OR FLASHCARDS. YOU ARE NOW IN "CHAT" MODE.
            
            You are Exora, a conversational, friendly, and brilliant AI study assistant. You are currently chatting directly with the user.
            
            CRITICAL RULES:
            1. NEVER output raw JSON, {"questions": []}, markdown tables, or lists of questions. Just talk like a human tutor.
            2. Respond directly to the user's message in a natural, conversational tone.
            3. If the user asks you to create study materials, say sure, and add a hidden trigger tag at the VERY END of your sentence. (Type must be QUIZ, FLASHCARDS, NOTES, or CHEATSHEET).
            
            EXAMPLES:
            User: "Hi"
            Exora: "Hello! I'm Exora, your AI study assistant. What would you like to learn about today?"
            
            User: "Make me a math quiz."
            Exora: "I'd love to help you study math! I'm putting together a custom quiz for you right now. [GENERATE: QUIZ | Math]"
            
            Now, respond directly to this User Message: "\(text)"
            """
            
            do {
                let response = try await AIContentManager.shared.generateContent(
                    topic: systemPrompt,
                    type: "Plain Text Response",
                    count: 1,
                    difficulty: "Medium"
                )
                
                DispatchQueue.main.async {
                    self.setTypingIndicatorViewHidden(true, animated: true)
                    self.processAIResponse(response)
                }
            } catch {
                DispatchQueue.main.async {
                    self.setTypingIndicatorViewHidden(true, animated: true)
                    let errorMsg = AIChatMessage(sender: self.aiAgent, messageId: UUID().uuidString, sentDate: Date(), kind: .text("I'm sorry, I'm having trouble connecting to the network right now."))
                    self.insertMessage(errorMsg)
                }
            }
        }
    }
    
    private func processAIResponse(_ response: String) {
        var displayMessage = response
        
        if let startIndex = response.range(of: "[GENERATE:")?.lowerBound,
           let endIndex = response.range(of: "]")?.upperBound {
            
            let fullTag = String(response[startIndex..<endIndex])
            displayMessage = response.replacingOccurrences(of: fullTag, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            let content = fullTag.replacingOccurrences(of: "[GENERATE:", with: "").replacingOccurrences(of: "]", with: "")
            let parts = content.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if parts.count == 2 {
                let generatedType = parts[0]
                let generatedTopic = parts[1]
                performMaterialGeneration(rawType: generatedType, topic: generatedTopic)
            }
        }
        
        if !displayMessage.isEmpty {
            let aiMsg = AIChatMessage(sender: aiAgent, messageId: UUID().uuidString, sentDate: Date(), kind: .text(displayMessage))
            insertMessage(aiMsg)
        }
    }
    
    // MARK: - Background Material Generation Engine
    private func performMaterialGeneration(rawType: String, topic: String) {
        let typeLower = rawType.lowercased()
        let genType: GenerationType
        let count = 10
        
        if typeLower.contains("quiz") { genType = .quiz }
        else if typeLower.contains("flashcard") { genType = .flashcards }
        else if typeLower.contains("note") { genType = .notes }
        else if typeLower.contains("cheat") { genType = .cheatsheet }
        else { return }
        
        let statusMsg = AIChatMessage(sender: aiAgent, messageId: UUID().uuidString, sentDate: Date(), kind: .text("⚙️ Creating your \(genType.description) on '\(topic)'..."))
        insertMessage(statusMsg)
        
        Task {
            var instruction = ""
            switch genType {
            case .flashcards:
                instruction = "Create EXACTLY 10 flashcards covering the most important concepts. STRICTLY use this EXACT JSON format: {\"flashcards\": [{\"front\": \"Term\", \"back\": \"Definition\"}]}"
            case .cheatsheet:
                instruction = "STRICTLY GENERATE A CHEATSHEET. DO NOT output JSON. Format as clean MARKDOWN text. Include # Title, ## Key Formulas, ## Important Dates, and ## Bulleted Definitions. You MUST use double line breaks (hit enter twice) to separate sections. Topic: \(topic)"
            case .notes:
                instruction = "STRICTLY GENERATE STUDY NOTES. DO NOT output JSON. Format as clean MARKDOWN text. Include # Main Heading, ## Subheadings, and Bullet points. You MUST use double line breaks (hit enter twice) to separate paragraphs. Topic: \(topic)"
            case .quiz:
                instruction = "Generate EXACTLY 10 quiz questions in JSON format. STRICTLY use this EXACT JSON format: {\"questions\": [{\"question\": \"...\", \"options\": [\"1\", \"2\", \"3\", \"4\"], \"answer\": \"1\", \"hint\": \"...\"}]}"
            default: break
            }
            
            let finalPrompt = "\(instruction)\n\nTOPIC REQUEST: \(topic)"
            
            do {
                let generatedText = try await AIContentManager.shared.generateContent(
                    topic: finalPrompt,
                    type: genType.description,
                    count: count,
                    difficulty: "Medium"
                )
                
                let folderName = "Exora AI Materials"
                var savedTopic: Topic?
                
                if genType == .quiz {
                    let questions = self.parseQuizJSON(generatedText)
                    if !questions.isEmpty {
                        savedTopic = DataManager.shared.saveGeneratedTopic(name: topic, subject: folderName, type: "Quiz", questions: questions)
                    }
                } else if genType == .flashcards {
                    let parsedCards = self.parseFlashcardsJSON(generatedText)
                    if !parsedCards.isEmpty {
                        let serialized = parsedCards.map { "\($0.safeFront)|\($0.safeBack)" }.joined(separator: "\n")
                        savedTopic = DataManager.shared.saveGeneratedTopic(name: topic, subject: folderName, type: "Flashcards", notes: serialized)
                    }
                } else {
                    var finalText = generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    finalText = finalText.replacingOccurrences(of: "\\n", with: "\n")
                    
                    if finalText.hasPrefix("```markdown") {
                        finalText = finalText.replacingOccurrences(of: "```markdown\n", with: "")
                        finalText = finalText.replacingOccurrences(of: "```markdown", with: "")
                        finalText = finalText.replacingOccurrences(of: "```", with: "")
                    }
                    savedTopic = DataManager.shared.saveGeneratedTopic(name: topic, subject: folderName, type: genType.description, notes: finalText)
                }
                
                DispatchQueue.main.async {
                    if savedTopic != nil {
                        let doneMsg = AIChatMessage(sender: self.aiAgent, messageId: UUID().uuidString, sentDate: Date(), kind: .text("✅ Done! I saved your '\(topic)' \(genType.description) directly to your Study tab. Happy studying!"))
                        self.insertMessage(doneMsg)
                        Task { await RevisioManager.shared.earnXP(amount: 5, reason: "Material Generated via AI") }
                    } else {
                        let errMsg = AIChatMessage(sender: self.aiAgent, messageId: UUID().uuidString, sentDate: Date(), kind: .text("⚠️ I had trouble formatting the \(genType.description). Try asking again!"))
                        self.insertMessage(errMsg)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    let errMsg = AIChatMessage(sender: self.aiAgent, messageId: UUID().uuidString, sentDate: Date(), kind: .text("⚠️ Error generating material: \(error.localizedDescription)"))
                    self.insertMessage(errMsg)
                }
            }
        }
    }
}

// MARK: - JSON Parsing Extensions
extension AIChatViewController {
    private func parseQuizJSON(_ jsonString: String) -> [QuizQuestion] {
        let cleanString = cleanJSONText(jsonString)
        guard let data = cleanString.data(using: .utf8) else { return [] }
        
        struct AIResponse: Codable {
            struct AIQuestion: Codable {
                let question: String; let options: [String]; let answer: String; let hint: String?
            }
            let questions: [AIQuestion]
        }
        
        do {
            let wrapper = try JSONDecoder().decode(AIResponse.self, from: data)
            return wrapper.questions.map { aiQ in
                let correctIndex = aiQ.options.firstIndex(of: aiQ.answer) ?? 0
                return QuizQuestion(questionText: aiQ.question, answers: aiQ.options, correctAnswerIndex: correctIndex, userAnswerIndex: nil, isFlagged: false, hint: aiQ.hint ?? "No hint")
            }
        } catch {
            if let directList = try? JSONDecoder().decode([QuizQuestion].self, from: data) { return directList }
        }
        return []
    }
    
    private func parseFlashcardsJSON(_ jsonString: String) -> [ChatParsedAIFlashcard] {
        let cleanString = cleanJSONText(jsonString)
        guard let data = cleanString.data(using: .utf8) else { return [] }
        
        let decoder = JSONDecoder()
        if let cards = try? decoder.decode([ChatParsedAIFlashcard].self, from: data) { return cards }
        
        struct AIWrapper: Codable { let flashcards: [ChatParsedAIFlashcard] }
        if let wrapper = try? decoder.decode(AIWrapper.self, from: data) { return wrapper.flashcards }
        return []
    }
    
    private func cleanJSONText(_ json: String) -> String {
        var clean = json
        if clean.contains("```json") { clean = clean.replacingOccurrences(of: "```json", with: "") }
        clean = clean.replacingOccurrences(of: "```", with: "")
        if let start = clean.firstIndex(of: "{") { clean = String(clean[start...]) }
        if let end = clean.lastIndex(of: "}") { clean = String(clean[...end]) }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Drawer TableView Data Source & Delegate
extension AIChatViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedSessions.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Today"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = .systemFont(ofSize: 14, weight: .bold)
            header.textLabel?.textColor = .systemGray
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
        let session = sortedSessions[indexPath.row]
        let isSelected = (session.id == currentSessionId)
        cell.configure(with: session, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        loadSession(sortedSessions[indexPath.row])
    }
}

// MARK: - Custom History Cell
class HistoryCell: UITableViewCell {
    let customBackground = UIView()
    let titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.selectionStyle = .none
        
        customBackground.layer.cornerRadius = 10
        customBackground.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(customBackground)
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        customBackground.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            customBackground.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            customBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            customBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            customBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: customBackground.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: customBackground.bottomAnchor, constant: -12),
            titleLabel.leadingAnchor.constraint(equalTo: customBackground.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: customBackground.trailingAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with session: ChatSession, isSelected: Bool) {
        titleLabel.text = session.title
        customBackground.backgroundColor = isSelected ? UIColor.systemGray4.withAlphaComponent(0.4) : .clear
    }
}

// MARK: - Data Source & UI Setup
extension AIChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    var currentSender: SenderType { return currentUser }
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int { return aiMessages.count }
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType { return aiMessages[indexPath.section] }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.systemGray5 : UIColor.systemGray6.withAlphaComponent(0.6)
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return .label
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if isFromCurrentSender(message: message) {
            avatarView.isHidden = true
        } else {
            avatarView.isHidden = false
            avatarView.backgroundColor = .systemPurple.withAlphaComponent(0.2)
            avatarView.image = UIImage(named: "Chatbot") ?? UIImage(systemName: "sparkles.tv")
            avatarView.tintColor = .systemPurple
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension AIChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let userMsg = AIChatMessage(sender: currentUser, messageId: UUID().uuidString, sentDate: Date(), kind: .text(text))
        insertMessage(userMsg)
        inputBar.inputTextView.text = ""
        fetchAIResponse(for: text)
    }
}

// MARK: - File & Media Handling
extension AIChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    func presentPhotoPicker() {
        let picker = UIImagePickerController(); picker.sourceType = .photoLibrary; picker.delegate = self
        present(picker, animated: true)
    }
    func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .image], asCopy: true); picker.delegate = self
        present(picker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let _ = info[.originalImage] as? UIImage {
            let userMsg = AIChatMessage(sender: currentUser, messageId: UUID().uuidString, sentDate: Date(), kind: .text("[Sent an Image]"))
            insertMessage(userMsg)
            fetchAIResponse(for: "I just uploaded an image.")
        }
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let filename = url.lastPathComponent
        let userMsg = AIChatMessage(sender: currentUser, messageId: UUID().uuidString, sentDate: Date(), kind: .text("[Sent Document: \(filename)]"))
        insertMessage(userMsg)
        fetchAIResponse(for: "I just uploaded a document named \(filename).")
    }
}
