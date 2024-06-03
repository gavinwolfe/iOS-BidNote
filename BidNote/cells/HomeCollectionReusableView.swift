//
//  HomeCollectionReusableView.swift
//  BidNote
//
//  Created by Gavin Wolfe on 4/11/23.
//

import UIKit
protocol openSearch {
    func goToSearch()
}

class HomeCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var divideView: UIView!
    
    @IBOutlet weak var searchView: UIView!
    
    @IBOutlet weak var tutorinLabel: UILabel!
    
    @IBOutlet weak var searchImage: UIImageView!
    
    var delegate: openSearch?
   
    @IBOutlet weak var searchL: UILabel!
    
    @IBOutlet weak var searchButton: UIButton!
    
    @IBOutlet weak var overView: UIView!
    
    @IBOutlet weak var bidnoteLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    @IBAction func searchAction(_ sender: Any) {
        delegate?.goToSearch()
    }
    
    
    override func layoutSubviews() {
        searchView.frame = CGRect(x: 30, y: overView.bounds.height - 60, width: overView.bounds.width - 60, height: 50)
        searchButton.frame = CGRect(x: 30, y: overView.bounds.height - 60, width: overView.bounds.width - 60, height: 52)
        searchImage.frame = CGRect(x: 10, y: 10, width: 30, height: 30)
        bidnoteLabel.frame = CGRect(x: 15, y: 15, width: 300, height: 50)
        searchL.frame = CGRect(x: 50, y: 10, width: searchView.bounds.width - 70, height: 30)
        divideView.frame = CGRect(x: 0, y:  overView.bounds.height - 35, width: overView.bounds.width, height: 40)
        tutorinLabel.frame = CGRect(x: 15, y: 50, width: 350, height: 75)
        searchView.layer.cornerRadius = 12.0
        tutorinLabel.text = "• Tutoring \n• Educational Material \n• New Content Added Daily"
    }
    
}
