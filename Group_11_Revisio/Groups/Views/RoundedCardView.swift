//
//  RoundedCardView.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 26/11/25.
//

import UIKit

class RoundedCardView: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private func setupView() {
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
    }
}
