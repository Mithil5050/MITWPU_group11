import re

with open('/Users/ashika/Desktop/Group_11_Revisio/Group_11_Revisio/Progress.storyboard', 'r') as f:
    content = f.read()

start_tag = '<viewController id="SZh-hW-Isu"'
end_tag = '</viewController>'

start_idx = content.find(start_tag)
end_idx = content.find(end_tag, start_idx) + len(end_tag)

new_vc = """<viewController id="SZh-hW-Isu" customClass="ProgressViewContoller" customModule="Group_11_Revisio" customModuleProvider="target" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="ezR-DV-9D6">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <scrollView clipsSubviews="YES" multipleTouchEnabled="YES" contentMode="scaleToFill" alwaysBounceVertical="YES" contentInsetAdjustmentBehavior="always" translatesAutoresizingMaskIntoConstraints="NO" id="cUM-KL-7fJ">
                                <rect key="frame" x="0.0" y="59" width="393" height="710"/>
                                <subviews>
                                    <view contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="CVW-11-REV" userLabel="contentView">
                                        <rect key="frame" x="0.0" y="0.0" width="393" height="608"/>
                                        <subviews>
                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Hours Studied" textAlignment="natural" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="utD-CW-oiC">
                                                <rect key="frame" x="20" y="8" width="353" height="20"/>
                                                <constraints>
                                                    <constraint firstAttribute="height" constant="20" id="dsY-OD-gjc"/>
                                                </constraints>
                                                <fontDescription key="fontDescription" style="UICTFontTextStyleTitle1"/>
                                                <nil key="textColor"/>
                                                <nil key="highlightedColor"/>
                                            </label>
                                            
                                            <view contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="u2V-jt-7yc">
                                                <rect key="frame" x="20" y="36" width="353" height="300"/>
                                                <color key="backgroundColor" systemColor="systemGray6Color"/>
                                                <constraints>
                                                    <constraint firstAttribute="height" priority="999" constant="300" id="PcE-sZ-AmP"/>
                                                </constraints>
                                            </view>
                                            
                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Achievements" textAlignment="natural" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" preferredMaxLayoutWidth="376" translatesAutoresizingMaskIntoConstraints="NO" id="flK-i9-NOb">
                                                <rect key="frame" x="20" y="360" width="353" height="34"/>
                                                <fontDescription key="fontDescription" style="UICTFontTextStyleTitle1"/>
                                                <nil key="textColor"/>
                                                <nil key="highlightedColor"/>
                                            </label>
                                            
                                            <stackView opaque="NO" contentMode="scaleToFill" distribution="fillEqually" spacing="16" translatesAutoresizingMaskIntoConstraints="NO" id="dzb-oj-u2D">
                                                <rect key="frame" x="20" y="402" width="353" height="190"/>
                                                <subviews>
                                                    <view contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="eru-Lt-hP1">
                                                        <rect key="frame" x="0.0" y="0.0" width="168.5" height="190"/>
                                                        <subviews>
                                                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" horizontalHuggingPriority="251" verticalHuggingPriority="251" image="flame" catalog="system" translatesAutoresizingMaskIntoConstraints="NO" id="7wm-F2-vrV">
                                                                <rect key="frame" x="12" y="47.5" width="30" height="30"/>
                                                                <color key="tintColor" systemColor="systemOrangeColor"/>
                                                                <constraints>
                                                                    <constraint firstAttribute="width" constant="30" id="LG5-kW-YkJ"/>
                                                                    <constraint firstAttribute="height" constant="30" id="r7a-gO-MEC"/>
                                                                </constraints>
                                                                <preferredSymbolConfiguration key="preferredSymbolConfiguration" scale="large" weight="light"/>
                                                            </imageView>
                                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Label" textAlignment="natural" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="BGu-G9-1h7">
                                                                <rect key="frame" x="12" y="168.5" width="28.5" height="13.5"/>
                                                                <fontDescription key="fontDescription" style="UICTFontTextStyleCaption2"/>
                                                                <color key="textColor" red="0.63257284110000001" green="0.63830078130000001" blue="0.59638181899999998" alpha="0.84705882349999995" colorSpace="custom" customColorSpace="displayP3"/>
                                                                <nil key="highlightedColor"/>
                                                            </label>
                                                            <stackView opaque="NO" contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="KXo-Sr-ZbO">
                                                                <rect key="frame" x="12" y="8" width="148.5" height="24"/>
                                                                <subviews>
                                                                    <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Streaks" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontForContentSizeCategory="YES" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="dyt-Tg-q8U">
                                                                        <rect key="frame" x="0.0" y="0.0" width="124.5" height="24"/>
                                                                        <fontDescription key="fontDescription" style="UICTFontTextStyleTitle3"/>
                                                                        <nil key="textColor"/>
                                                                        <nil key="highlightedColor"/>
                                                                    </label>
                                                                    <button opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="0Fr-v9-4WU">
                                                                        <rect key="frame" x="124.5" y="0.0" width="24" height="24"/>
                                                                        <constraints>
                                                                            <constraint firstAttribute="width" constant="24" id="4WU-width"/>
                                                                        </constraints>
                                                                        <color key="tintColor" white="0.66666666669999997" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                                                                        <state key="normal" title="Button"/>
                                                                        <buttonConfiguration key="configuration" style="plain" image="chevron.right.circle.fill" catalog="system"/>
                                                                        <connections>
                                                                            <segue destination="wN2-Ig-61i" kind="show" identifier="ShowStreaks" id="AiF-fl-MfQ"/>
                                                                        </connections>
                                                                    </button>
                                                                </subviews>
                                                                <constraints>
                                                                    <constraint firstAttribute="height" constant="24" id="WSC-Xi-SRO"/>
                                                                </constraints>
                                                            </stackView>
                                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalCompressionResistancePriority="749" text="Label" textAlignment="natural" lineBreakMode="tailTruncation" numberOfLines="0" adjustsLetterSpacingToFitWidth="YES" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="xo9-0e-UVe">
                                                                <rect key="frame" x="12" y="93.5" width="136.5" height="33.5"/>
                                                                <fontDescription key="fontDescription" style="UICTFontTextStyleTitle1"/>
                                                                <nil key="textColor"/>
                                                                <nil key="highlightedColor"/>
                                                            </label>
                                                        </subviews>
                                                        <color key="backgroundColor" systemColor="systemGray6Color"/>
                                                        <constraints>
                                                            <constraint firstItem="KXo-Sr-ZbO" firstAttribute="top" secondItem="eru-Lt-hP1" secondAttribute="top" constant="8" id="3Tf-b2-bc3"/>
                                                            <constraint firstItem="7wm-F2-vrV" firstAttribute="top" secondItem="KXo-Sr-ZbO" secondAttribute="bottom" constant="16" id="7Ny-u9-wAR"/>
                                                            <constraint firstItem="7wm-F2-vrV" firstAttribute="leading" secondItem="eru-Lt-hP1" secondAttribute="leading" constant="12" id="Ira-qq-R8M"/>
                                                            <constraint firstItem="BGu-G9-1h7" firstAttribute="leading" secondItem="eru-Lt-hP1" secondAttribute="leading" constant="12" id="MbU-9r-djO"/>
                                                            <constraint firstItem="xo9-0e-UVe" firstAttribute="leading" secondItem="eru-Lt-hP1" secondAttribute="leading" constant="12" id="Y2j-Gi-926"/>
                                                            <constraint firstItem="xo9-0e-UVe" firstAttribute="top" secondItem="7wm-F2-vrV" secondAttribute="bottom" constant="16" id="ePX-06-8Ug"/>
                                                            <constraint firstItem="KXo-Sr-ZbO" firstAttribute="leading" secondItem="eru-Lt-hP1" secondAttribute="leading" constant="12" id="meN-Lw-dYe"/>
                                                            <constraint firstAttribute="trailing" secondItem="xo9-0e-UVe" secondAttribute="trailing" constant="20" id="qZv-kV-cLl"/>
                                                            <constraint firstAttribute="bottom" secondItem="BGu-G9-1h7" secondAttribute="bottom" constant="8" id="wfC-s8-Xpb"/>
                                                            <constraint firstAttribute="trailing" secondItem="KXo-Sr-ZbO" secondAttribute="trailing" constant="8" id="ywr-WW-8Lk"/>
                                                        </constraints>
                                                    </view>
                                                    <view contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="S9a-ix-YCl">
                                                        <rect key="frame" x="184.5" y="0.0" width="168.5" height="190"/>
                                                        <subviews>
                                                            <stackView opaque="NO" contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="wQs-ce-EUb">
                                                                <rect key="frame" x="12" y="8" width="148.5" height="24"/>
                                                                <subviews>
                                                                    <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Awards" textAlignment="natural" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="Yda-Uv-Ly0">
                                                                        <rect key="frame" x="0.0" y="0.0" width="124.5" height="24"/>
                                                                        <fontDescription key="fontDescription" style="UICTFontTextStyleTitle3"/>
                                                                        <nil key="textColor"/>
                                                                        <nil key="highlightedColor"/>
                                                                    </label>
                                                                    <button opaque="NO" contentMode="center" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="GqW-0P-qcj">
                                                                        <rect key="frame" x="124.5" y="0.0" width="24" height="24"/>
                                                                        <constraints>
                                                                            <constraint firstAttribute="width" constant="24" id="qcj-width"/>
                                                                        </constraints>
                                                                        <color key="tintColor" white="0.66666666669999997" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                                                                        <state key="normal" title="Button"/>
                                                                        <buttonConfiguration key="configuration" style="plain" image="chevron.forward.circle.fill" catalog="system"/>
                                                                        <connections>
                                                                            <segue destination="Iz6-9K-uFj" kind="show" identifier="ShowAwards" id="5Vv-xt-RH1"/>
                                                                        </connections>
                                                                    </button>
                                                                </subviews>
                                                                <constraints>
                                                                    <constraint firstAttribute="height" constant="24" id="fMr-hD-QVd"/>
                                                                </constraints>
                                                            </stackView>
                                                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFill" horizontalHuggingPriority="251" verticalHuggingPriority="251" translatesAutoresizingMaskIntoConstraints="NO" id="cp2-Rr-eit">
                                                                <rect key="frame" x="44.5" y="48" width="80" height="80"/>
                                                                <constraints>
                                                                    <constraint firstAttribute="width" constant="80" id="9ZQ-x5-14i"/>
                                                                    <constraint firstAttribute="height" constant="80" id="hO8-oe-Fyh"/>
                                                                </constraints>
                                                            </imageView>
                                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Label" textAlignment="natural" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="FdA-6X-G8m">
                                                                <rect key="frame" x="69" y="136" width="31" height="14.5"/>
                                                                <fontDescription key="fontDescription" style="UICTFontTextStyleCaption1"/>
                                                                <nil key="textColor"/>
                                                                <nil key="highlightedColor"/>
                                                            </label>
                                                        </subviews>
                                                        <color key="backgroundColor" systemColor="systemGray6Color"/>
                                                        <constraints>
                                                            <constraint firstItem="cp2-Rr-eit" firstAttribute="centerX" secondItem="S9a-ix-YCl" secondAttribute="centerX" id="2Fw-5b-pLM"/>
                                                            <constraint firstItem="wQs-ce-EUb" firstAttribute="top" secondItem="S9a-ix-YCl" secondAttribute="top" constant="8" id="2lj-dl-Lum"/>
                                                            <constraint firstAttribute="trailing" secondItem="wQs-ce-EUb" secondAttribute="trailing" constant="8" id="UBL-e2-sCe"/>
                                                            <constraint firstItem="cp2-Rr-eit" firstAttribute="top" secondItem="wQs-ce-EUb" secondAttribute="bottom" constant="16" id="WDj-Bj-fX5"/>
                                                            <constraint firstItem="wQs-ce-EUb" firstAttribute="leading" secondItem="S9a-ix-YCl" secondAttribute="leading" constant="12" id="bcU-4N-xd8"/>
                                                            <constraint firstItem="FdA-6X-G8m" firstAttribute="centerX" secondItem="S9a-ix-YCl" secondAttribute="centerX" id="lTs-0J-ceE"/>
                                                            <constraint firstItem="FdA-6X-G8m" firstAttribute="top" secondItem="cp2-Rr-eit" secondAttribute="bottom" constant="8" id="qQe-aR-b9N"/>
                                                        </constraints>
                                                    </view>
                                                </subviews>
                                                <constraints>
                                                    <constraint firstAttribute="height" constant="190" id="dzb-height"/>
                                                </constraints>
                                            </stackView>
                                        </subviews>
                                        <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                                        <constraints>
                                            <constraint firstItem="utD-CW-oiC" firstAttribute="top" secondItem="CVW-11-REV" secondAttribute="top" constant="8" id="H8-top-8"/>
                                            <constraint firstItem="utD-CW-oiC" firstAttribute="leading" secondItem="CVW-11-REV" secondAttribute="leading" constant="20" id="H8-leading"/>
                                            <constraint firstAttribute="trailing" secondItem="utD-CW-oiC" secondAttribute="trailing" constant="20" id="H8-trailing"/>
                                            
                                            <constraint firstItem="u2V-jt-7yc" firstAttribute="top" secondItem="utD-CW-oiC" secondAttribute="bottom" constant="8" id="u2V-top"/>
                                            <constraint firstItem="u2V-jt-7yc" firstAttribute="leading" secondItem="CVW-11-REV" secondAttribute="leading" constant="20" id="u2V-leading"/>
                                            <constraint firstAttribute="trailing" secondItem="u2V-jt-7yc" secondAttribute="trailing" constant="20" id="u2V-trailing"/>
                                            
                                            <constraint firstItem="flK-i9-NOb" firstAttribute="top" secondItem="u2V-jt-7yc" secondAttribute="bottom" constant="24" id="flK-top"/>
                                            <constraint firstItem="flK-i9-NOb" firstAttribute="leading" secondItem="CVW-11-REV" secondAttribute="leading" constant="20" id="flK-leading"/>
                                            <constraint firstAttribute="trailing" secondItem="flK-i9-NOb" secondAttribute="trailing" constant="20" id="flK-trailing"/>
                                            
                                            <constraint firstItem="dzb-oj-u2D" firstAttribute="top" secondItem="flK-i9-NOb" secondAttribute="bottom" constant="8" id="dzb-top"/>
                                            <constraint firstItem="dzb-oj-u2D" firstAttribute="leading" secondItem="CVW-11-REV" secondAttribute="leading" constant="20" id="dzb-leading"/>
                                            <constraint firstAttribute="trailing" secondItem="dzb-oj-u2D" secondAttribute="trailing" constant="20" id="dzb-trailing"/>
                                            
                                            <constraint firstAttribute="bottom" secondItem="dzb-oj-u2D" secondAttribute="bottom" constant="16" id="anchor-bottom"/>
                                        </constraints>
                                    </view>
                                </subviews>
                                <constraints>
                                    <constraint firstItem="CVW-11-REV" firstAttribute="top" secondItem="O8W-X8-qcb" secondAttribute="top" id="top-0"/>
                                    <constraint firstItem="CVW-11-REV" firstAttribute="leading" secondItem="O8W-X8-qcb" secondAttribute="leading" id="leading-0"/>
                                    <constraint firstItem="CVW-11-REV" firstAttribute="trailing" secondItem="O8W-X8-qcb" secondAttribute="trailing" id="trailing-0"/>
                                    <constraint firstItem="CVW-11-REV" firstAttribute="bottom" secondItem="O8W-X8-qcb" secondAttribute="bottom" id="bottom-0"/>
                                    <constraint firstItem="CVW-11-REV" firstAttribute="width" secondItem="QWY-xq-HvK" secondAttribute="width" id="width-equal"/>
                                </constraints>
                                <viewLayoutGuide key="contentLayoutGuide" id="O8W-X8-qcb"/>
                                <viewLayoutGuide key="frameLayoutGuide" id="QWY-xq-HvK"/>
                            </scrollView>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="37l-OI-p6n"/>
                        <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                        <constraints>
                            <constraint firstItem="cUM-KL-7fJ" firstAttribute="leading" secondItem="37l-OI-p6n" secondAttribute="leading" id="6G3-aq-lZI"/>
                            <constraint firstItem="cUM-KL-7fJ" firstAttribute="trailing" secondItem="37l-OI-p6n" secondAttribute="trailing" id="Viy-ug-CXH"/>
                            <constraint firstItem="cUM-KL-7fJ" firstAttribute="top" secondItem="37l-OI-p6n" secondAttribute="top" id="w66-JB-d6i"/>
                            <constraint firstItem="cUM-KL-7fJ" firstAttribute="bottom" secondItem="37l-OI-p6n" secondAttribute="bottom" id="xvQ-a5-tdY"/>
                        </constraints>
                    </view>
                    <navigationItem key="navigationItem" title="Progress" leftItemsSupplementBackButton="YES" largeTitleDisplayMode="always" id="y1Y-XM-Z8h"/>
                    <simulatedTabBarMetrics key="simulatedBottomBarMetrics"/>
                    <freeformSimulatedSizeMetrics key="simulatedDestinationMetrics"/>
                    <size key="freeformSize" width="393" height="852"/>
                    <connections>
                        <outlet property="achievementsHeaderLabel" destination="flK-i9-NOb" id="K5M-IV-sGg"/>
                        <outlet property="awardsCard" destination="S9a-ix-YCl" id="dKQ-IZ-Nh0"/>
                        <outlet property="awardsLabel" destination="Yda-Uv-Ly0" id="y5x-TZ-47e"/>
                        <outlet property="chartContainerView" destination="u2V-jt-7yc" id="zlp-Cz-NpL"/>
                        <outlet property="hoursStudiedHeaderLabel" destination="utD-CW-oiC" id="HG1-ha-0hP"/>
                        <outlet property="mainMonthBagdeImageView" destination="cp2-Rr-eit" id="yDJ-gP-Fbf"/>
                        <outlet property="monthNameLabel" destination="FdA-6X-G8m" id="8db-1O-om2"/>
                        <outlet property="scrollView" destination="cUM-KL-7fJ" id="hUQ-FB-2xy"/>
                        <outlet property="streaksCard" destination="eru-Lt-hP1" id="TXx-Db-03X"/>
                        <outlet property="streaksCountLabel" destination="xo9-0e-UVe" id="ERA-c8-hog"/>
                        <outlet property="streaksDateLabel" destination="BGu-G9-1h7" id="c32-dq-Kum"/>
                        <outlet property="streaksLabel" destination="dyt-Tg-q8U" id="QkO-Ji-G6m"/>
                    </connections>
                </viewController>"""

new_content = content[:start_idx] + new_vc + content[end_idx:]

with open('/Users/ashika/Desktop/Group_11_Revisio/Group_11_Revisio/Progress.storyboard', 'w') as f:
    f.write(new_content)

print("Updated Progress.storyboard")
