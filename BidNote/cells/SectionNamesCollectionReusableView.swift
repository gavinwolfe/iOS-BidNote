//
//  SectionNamesCollectionReusableView.swift
//  BidNote
//
//  Created by Gavin Wolfe on 4/18/23.
//

import UIKit

class SectionNamesCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var divideView: UIView!
    
    @IBOutlet weak var overView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
