import xml.etree.ElementTree as ET
import sys

file_path = '/Users/mithil/Desktop/MITWPU_group11/Group_11_Revisio/Home.storyboard'
tree = ET.parse(file_path)
root = tree.getroot()

# Fix Card and Card Label (yve-am-CLl and vNK-cQ-DFA)
for view in root.iter('view'):
    if view.get('id') == 'vNK-cQ-DFA':
        if 'ambiguous' in view.attrib:
            del view.attrib['ambiguous']
        
        # Give it a height constraint
        constraints = view.find('constraints')
        if constraints is not None:
            ET.SubElement(constraints, 'constraint', {
                'firstAttribute': 'height',
                'constant': '350',
                'id': 'FIX-CARD-HEIGHT'
            })
            
for label in root.iter('label'):
    if label.get('id') == 'yve-am-CLl':
        if 'misplaced' in label.attrib:
            del label.attrib['misplaced']

# Fix Stack Views (WSx-Ca-D1K and jdM-qD-uvo)
for stack in root.iter('stackView'):
    if stack.get('id') == 'WSx-Ca-D1K':
        if 'ambiguous' in stack.attrib:
            del stack.attrib['ambiguous']
        constraints = stack.find('constraints')
        if constraints is None:
            constraints = ET.SubElement(stack, 'constraints')
        ET.SubElement(constraints, 'constraint', {
            'firstAttribute': 'height',
            'constant': '200',
            'id': 'FIX-GRID-HEIGHT'
        })
    elif stack.get('id') == 'jdM-qD-uvo':
        if 'ambiguous' in stack.attrib:
            del stack.attrib['ambiguous']
        constraints = stack.find('constraints')
        if constraints is None:
            constraints = ET.SubElement(stack, 'constraints')
        ET.SubElement(constraints, 'constraint', {
            'firstAttribute': 'height',
            'constant': '240',
            'id': 'FIX-KEYBOARD-HEIGHT'
        })

# Remove the conflicting top constraint 1zq-YO-L1a on jdM-qD-uvo
for constraint in root.iter('constraint'):
    if constraint.get('id') == '1zq-YO-L1a':
        parent = root.find(f".//constraint[@id='1zq-YO-L1a']/..")
        if parent is not None:
            parent.remove(constraint)

# Write back
tree.write(file_path, encoding='UTF-8', xml_declaration=True)
print("Updated storyboard.")
