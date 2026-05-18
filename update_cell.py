with open("Group_11_Revisio/Home/HomeScreen/ContinueLearningCollectionViewCell.swift", "r") as f:
    content = f.read()

# 1. Background color
old_bg = 'contentView.backgroundColor = UIColor(red: 45/255, green: 46/255, blue: 54/255, alpha: 1.0)'
new_bg = '''contentView.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemGroupedBackground
            } else {
                return UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
            }
        }'''
content = content.replace(old_bg, new_bg)

# 2. Icon container color for contrast
old_icon_bg = 'view.backgroundColor = UIColor(red: 25/255, green: 26/255, blue: 33/255, alpha: 1.0)'
new_icon_bg = '''view.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .tertiarySystemGroupedBackground
            } else {
                return .white
            }
        }'''
content = content.replace(old_icon_bg, new_icon_bg)

# 3. Resume Button color for contrast
old_resume_bg = 'btn.backgroundColor = UIColor(red: 60/255, green: 62/255, blue: 74/255, alpha: 1.0)'
new_resume_bg = 'btn.backgroundColor = UIColor.systemBlue'
content = content.replace(old_resume_bg, new_resume_bg)

# 4. Spacing constraints (Top anchor for resumeButton)
old_constraints = '''            // Resume Button
            resumeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resumeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            resumeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            resumeButton.heightAnchor.constraint(equalToConstant: 44)'''
            
new_constraints = '''            // Resume Button
            resumeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resumeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            resumeButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            resumeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            resumeButton.heightAnchor.constraint(equalToConstant: 44)'''
content = content.replace(old_constraints, new_constraints)

# 5. Label and Icon config
old_config = '''        titleLabel.text = topic.parentSubjectName.isEmpty ? "Topic" : topic.parentSubjectName
        subtitleLabel.text = topic.name
        
        // Icon logic based on material type
        let typeLower = topic.materialType.lowercased()
        if typeLower.contains("quiz") {
            iconImageView.image = UIImage(systemName: "checkmark.rectangle.fill")
        } else if typeLower.contains("flashcard") {
            iconImageView.image = UIImage(systemName: "square.stack.fill")
        } else if typeLower.contains("cheatsheet") {
            iconImageView.image = UIImage(systemName: "doc.text.fill")
        } else {
            iconImageView.image = UIImage(systemName: "flask") // Default
        }'''
        
new_config = '''        titleLabel.text = topic.name
        subtitleLabel.isHidden = true
        
        // Icon logic based on material type
        let typeLower = topic.materialType.lowercased()
        if typeLower.contains("quiz") {
            iconImageView.image = UIImage(systemName: "questionmark.circle.fill")
        } else if typeLower.contains("flashcard") {
            iconImageView.image = UIImage(systemName: "rectangle.stack.fill")
        } else if typeLower.contains("cheatsheet") || typeLower.contains("note") {
            iconImageView.image = UIImage(systemName: "doc.text.fill")
        } else {
            iconImageView.image = UIImage(systemName: "book.fill") // Default
        }'''
content = content.replace(old_config, new_config)

with open("Group_11_Revisio/Home/HomeScreen/ContinueLearningCollectionViewCell.swift", "w") as f:
    f.write(content)
