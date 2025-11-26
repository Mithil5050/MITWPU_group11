//
//  RoundedCardView.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 26/11/25.
//

import UIKit

class RoundedCardView: UIView {

    //Called when the view is loaded from the Storyboard
        override func awakeFromNib() {
            super.awakeFromNib()
            setupView()
        }

        private func setupView() {
            // Forces the rounded corners and clipping
            self.layer.cornerRadius = 15
            self.clipsToBounds = true
        }

}
