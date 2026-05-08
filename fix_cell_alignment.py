import re

with open("Group_11_Revisio/Home/HomeScreen/ContinueLearningCollectionViewCell.swift", "r") as f:
    content = f.read()

# 1. Update Subtitle text and unhide it to show Material Type
old_config = '''        titleLabel.text = topic.name
        subtitleLabel.isHidden = true'''
        
new_config = '''        titleLabel.text = topic.name
        subtitleLabel.text = topic.materialType
        subtitleLabel.isHidden = false'''
content = content.replace(old_config, new_config)

# 2. Make resume button indigo
old_resume_bg = 'btn.backgroundColor = UIColor.systemBlue'
new_resume_bg = 'btn.backgroundColor = .systemIndigo'
content = content.replace(old_resume_bg, new_resume_bg)

# 3. Fix material name alignment
# Old constraints:
#             titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
#             titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
#             titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
#             
#             subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
#             subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
#             subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

# We want to center the title and subtitle together relative to the iconContainer.
# We can do this by wrapping them in a stack view, or just adjusting constraints.
# Let's adjust constraints:
# titleLabel.bottomAnchor = iconContainer.centerYAnchor (or slightly above)
# subtitleLabel.topAnchor = titleLabel.bottomAnchor + 2
# Or just tie titleLabel to top of icon container.
# Let's replace the constraints directly.

old_constraints = '''            // Title & Subtitle
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),'''

new_constraints = '''            // Title & Subtitle
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: iconContainer.centerYAnchor, constant: 2),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),'''

content = content.replace(old_constraints, new_constraints)

with open("Group_11_Revisio/Home/HomeScreen/ContinueLearningCollectionViewCell.swift", "w") as f:
    f.write(content)
