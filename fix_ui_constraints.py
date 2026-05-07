import re
import glob

swift_files = [
    'Group_11_Revisio/Home/Games/WordFillLaunchViewController.swift',
    'Group_11_Revisio/Home/Games/ConnectionsLaunchingScreenViewController.swift',
    'Group_11_Revisio/Home/Games/DiagramGameLaunchViewController.swift'
]

constraint_code = """
        // Update button constraints programmatically
        if let topicBtn = topicDropdownButton, let startBtn = startButton {
            topicBtn.translatesAutoresizingMaskIntoConstraints = false
            startBtn.translatesAutoresizingMaskIntoConstraints = false
            
            // Remove existing constraints from superview
            view.removeConstraints(view.constraints.filter { 
                ($0.firstItem as? UIView == topicBtn) || ($0.secondItem as? UIView == topicBtn) ||
                ($0.firstItem as? UIView == startBtn) || ($0.secondItem as? UIView == startBtn)
            })
            // Remove intrinsic constraints
            topicBtn.removeConstraints(topicBtn.constraints)
            startBtn.removeConstraints(startBtn.constraints)
            
            NSLayoutConstraint.activate([
                startBtn.heightAnchor.constraint(equalToConstant: 52),
                startBtn.widthAnchor.constraint(equalToConstant: 353),
                startBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                startBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                
                topicBtn.heightAnchor.constraint(equalToConstant: 52),
                topicBtn.widthAnchor.constraint(equalToConstant: 353),
                topicBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                topicBtn.bottomAnchor.constraint(equalTo: startBtn.topAnchor, constant: -16)
            ])
        }
"""

for file_path in swift_files:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # insert before "setupDropdownMenu()"
    if "// Update button constraints programmatically" not in content:
        content = content.replace("setupDropdownMenu()", constraint_code + "\n        setupDropdownMenu()")
        with open(file_path, 'w') as f:
            f.write(content)
