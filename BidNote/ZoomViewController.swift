//
//  ZoomViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/25/23.
//

import UIKit

class ZoomViewController: UIViewController, UIScrollViewDelegate {

    var image: UIImage?
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        if let image = self.image {
            imageView.image = image
        }
        // Do any additional setup after loading the view.
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
