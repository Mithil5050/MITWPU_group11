//
//  HeaderViewCollectionReusableView.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/11/25.
//

import UIKit

class HeaderViewCollectionReusableView: UICollectionReusableView {

    @IBOutlet weak var TitleName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func configureHeader(with title: String) {
        // Implement the logic to set the title text
        TitleName.text = title
        // If you want the title to appear bold, set a bold font:
        if let currentSize = TitleName?.font?.pointSize {
            TitleName.font = UIFont.boldSystemFont(ofSize: currentSize)
        } else {
            TitleName.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        }
        // If you also want it uppercased, uncomment the next line:
        // TitleName.text = title.uppercased()
    }
    
}
