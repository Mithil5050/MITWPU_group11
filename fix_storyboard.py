import re

with open('Group_11_Revisio/Home.storyboard', 'r') as f:
    content = f.read()

# Replace WordFill textField with button
content = re.sub(
    r'<textField opaque="NO" contentMode="scaleToFill" horizontalHuggingPriority="248" contentHorizontalAlignment="left" contentVerticalAlignment="center" borderStyle="roundedRect" placeholder="Enter Topic" textAlignment="center" minimumFontSize="17" translatesAutoresizingMaskIntoConstraints="NO" id="MsR-I8-GwA">[\s\S]*?</textField>',
    '''<button opaque="NO" showsMenuAsPrimaryAction="YES" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="MsR-I8-GwA">
                                <rect key="frame" x="46" y="529" width="301" height="34"/>
                                <state key="normal" title="Select Topic"/>
                                <buttonConfiguration key="configuration" style="tinted" title="Select Topic"/>
                            </button>''',
    content
)

# Replace Connections textField with button
content = re.sub(
    r'<textField opaque="NO" contentMode="scaleToFill" horizontalHuggingPriority="248" contentHorizontalAlignment="left" contentVerticalAlignment="center" borderStyle="roundedRect" placeholder="Enter Topic" textAlignment="center" minimumFontSize="17" translatesAutoresizingMaskIntoConstraints="NO" id="kPK-yn-sA6">[\s\S]*?</textField>',
    '''<button opaque="NO" showsMenuAsPrimaryAction="YES" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="kPK-yn-sA6">
                                <rect key="frame" x="46" y="549" width="301" height="34"/>
                                <state key="normal" title="Select Topic"/>
                                <buttonConfiguration key="configuration" style="tinted" title="Select Topic"/>
                            </button>''',
    content
)

# Replace DiagramDash textField with button
content = re.sub(
    r'<textField opaque="NO" contentMode="scaleToFill" horizontalHuggingPriority="248" contentHorizontalAlignment="left" contentVerticalAlignment="center" borderStyle="roundedRect" placeholder="Enter Topic" textAlignment="center" minimumFontSize="17" translatesAutoresizingMaskIntoConstraints="NO" id="ivW-2o-lqc">[\s\S]*?</textField>',
    '''<button opaque="NO" showsMenuAsPrimaryAction="YES" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="ivW-2o-lqc">
                                <rect key="frame" x="46" y="525" width="301" height="34"/>
                                <state key="normal" title="Select Topic"/>
                                <buttonConfiguration key="configuration" style="tinted" title="Select Topic"/>
                            </button>''',
    content
)

with open('Group_11_Revisio/Home.storyboard', 'w') as f:
    f.write(content)
