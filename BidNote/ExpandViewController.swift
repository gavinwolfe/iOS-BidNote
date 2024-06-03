//
//  ExpandViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/24/23.
//

import UIKit
import Kingfisher
import Firebase
import FirebaseStorage
import WeScan
import UniformTypeIdentifiers
import PDFKit
protocol changeImages {
    func updateInQueue()
}

class ExpandViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIDocumentPickerDelegate, ImageScannerControllerDelegate {
    
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var images: [String]?
    let swipe = UISwipeGestureRecognizer()
    var solid: String?
    var imgDict = [String: String]()
    var editMode: Bool?
    var addedDict = [String: UIImage]()
    var removedUrls = [String: String]()
    var addedUrls: [String]?
    let activity = UIActivityIndicatorView()
    let addButton = UIButton()
    var delegate: changeImages?
    var scannerViewController = ImageScannerController()
    let supportedDocs = [UTType.pdf]
    var saveNow = false
    override func viewDidLoad() {
        super.viewDidLoad()
        //collectionView.frame = CGRect(x: 0, y: 60, width: view.frame.width, height: view.frame.height - 60)
        collectionView.delegate = self
        collectionView.dataSource = self
        if let solid = self.solid {
            let ref = Database.database().reference()
            ref.child("solutions").child(solid).child("images").observeSingleEvent(of: .value, with: { snap in
                if let values = snap.value as? [String: AnyObject] {
                    for (_,each) in values {
                        if let key = each["key"] as? String, let url = each["urlPhoto"] as? String {
                            self.imgDict[url] = key
                        }
                    }
                }
            })
        }
        if let images = self.images {
            collectionView.reloadData()
        }
        if let editModeOn = self.editMode, editModeOn == true {
            addButton.frame = CGRect(x: 50, y: view.frame.height - 100, width: view.frame.width - 100, height: 40)
            addButton.backgroundColor = .systemBlue
            addButton.setTitleColor(.white, for: .normal)
            addButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
            addButton.setTitle("Add / Delete Images", for: .normal)
            addButton.layer.cornerRadius = 8.0
            addButton.addTarget(self, action: #selector(addImages), for: .touchUpInside)
            view.addSubview(addButton)
        }
        
        swipe.direction = .down
        swipe.addTarget(self, action: #selector(self.dismissView))
        view.addGestureRecognizer(swipe)
        backButton.frame = CGRect(x: view.frame.width - 100, y: 40, width: 80, height: 30)
        backButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    var scaleStart = 1
    var widthStart = 0
    var originalNumberOfCellsToOffset = 0
    var originalContentOffset = 0
    
    @objc func dismissView() {
        self.dismiss(animated: true)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellExpand", for: indexPath) as? expandCell
        if let images = self.images {
            if images[indexPath.row].contains("imager-local") {
                if let image = addedDict[images[indexPath.row]] {
                    cell?.imageView.image = image
                }
            } else {
                if let url = URL(string: images[indexPath.row]) {
                    cell?.imageView.kf.setImage(with: url)
                }
            }
            cell?.imageView.clipsToBounds = true
        }
        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ref = Database.database().reference()
        guard editMode == false else {
            if let imgs = self.images {
                var alert = UIAlertController(title: "Delete Image", message: "", preferredStyle: .actionSheet)
                if UIDevice().userInterfaceIdiom == .pad {
                    alert = UIAlertController(title: "Delete Image", message: "", preferredStyle: .alert)
                }
                let act1 = UIAlertAction(title: "Delete", style: .default, handler: { alert -> Void in
                    if imgs[indexPath.row].contains("imager-local") {
                        self.addedDict.removeValue(forKey: imgs[indexPath.row])
                        self.images?.removeAll(where: { $0 == imgs[indexPath.row]})
                        self.collectionView.reloadData()
                    } else {
                       //get key from img dict
                        if let key = self.imgDict[imgs[indexPath.row]], self.imgDict.count >= 2, let solid = self.solid {
                            self.removedUrls[key] = imgs[indexPath.row]
                            ref.child("solutions").child(solid).child("images").child(key).removeValue()
                            self.imgDict.removeValue(forKey: imgs[indexPath.row])
                            self.images?.removeAll(where: {$0 == imgs[indexPath.row]})
                            self.collectionView.reloadData()
                        }
                    }
                })
                let cancel = UIAlertAction(title: "Cancel", style: .cancel)
                alert.addAction(act1)
                alert.addAction(cancel)
                self.present(alert, animated: true)
                
            }
            return
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? expandCell {
            if let image = cell.imageView.image {
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "zoomVC") as? ZoomViewController {
                    vc.image = image
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }
    }

    @objc func dismissVC() {
        self.dismiss(animated: true)
    }
    
    @objc func addImages() {
        guard !self.saveNow else {
            self.addButton.isEnabled = false
            let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
            let ref = Database.database().reference().child("adminQueue")
            if let images = self.images, self.addedDict.count != 0,images.count >= 1, let myUid = Auth.auth().currentUser?.uid, let solid = self.solid, images.count < 35 {
                let update = ["creatorId": myUid, "solId": solid, "adminUpdate": "imageUpdate", "time": timeStamp] as [String : Any]
                ref.child(solid).updateChildValues(update)
                activity.frame = view.frame
                activity.color = .systemBlue
                activity.backgroundColor = .opaqueSeparator
                activity.startAnimating()
                view.addSubview(activity)
                var count = 0;
                for (tempKey,each) in addedDict {
                    count+=1
                    if let key = Database.database().reference().child("solutions").child(solid).child("images").childByAutoId().key {
                        let storage = Storage.storage().reference().child("images").child(myUid).child(key)
                        if let uploadData = each.jpegData(compressionQuality: 0.6) {
                            storage.putData(uploadData, metadata: nil, completion:
                                                { (metadata, error) in
                                print("at least here")
                                guard let metadata = metadata else {
                                    // Uh-oh, an error occurred!
                                    print(error!)
                                    self.navigationController?.navigationBar.isHidden = false
                                    return
                                }
                                let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                                storage.downloadURL { url, error in
                                    guard let downloadURL = url else {
                                        print("erroor downl")
                                        return
                                    }
                                    let urlLoad = downloadURL.absoluteString
                                    var order = 0
                                    if tempKey[1] != "-" {
                                        order = Int(tempKey[0..<2]) ?? 0
                                        if tempKey[2] != "-" {
                                            order = Int(tempKey[0..<3]) ?? 0
                                        }
                                    } else if tempKey[0] != "-" {
                                        order = Int(tempKey[0]) ?? 0
                                    }
                                    let result = ["urlPhoto" : urlLoad, "time" : timeStamp, "key" : key, "postedByUid" : myUid, "order": order] as [String : Any]
                                    let update = [key : result]
                                    ref.child(solid).child("images").updateChildValues(update)
                                    if count == self.addedDict.count {
                                        count = 0
                                        self.activity.stopAnimating()
                                        self.activity.removeFromSuperview()
                                        self.delegate?.updateInQueue()
                                        self.dismissVC()
                                    }
                                    
                                }
                                
                            })
                        }
                    }
                }
            }
            return
        }
        let alert = UIAlertController(title: "Add Images", message: "Select how you'd like to add an image. TO DELETE AN IMAGE: Simply tap on the image you want to delete.", preferredStyle: .alert)
        let act1 = UIAlertAction(title: "Scanner", style: .default, handler: { alert -> Void in
            self.scannerViewController.modalPresentationStyle = .fullScreen
            self.scannerViewController.imageScannerDelegate = self
            self.present(self.scannerViewController, animated: true)
        })
        let act2 =  UIAlertAction(title: "PDF Upload", style: .default, handler: { alert -> Void in
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: self.supportedDocs, asCopy: true)
                documentPicker.delegate = self
                documentPicker.allowsMultipleSelection = false
                documentPicker.shouldShowFileExtensions = true
            self.present(documentPicker, animated: true, completion: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(act1)
        alert.addAction(act2)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        // You are responsible for carefully handling the error
        print(error)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        // The user successfully scanned an image, which is available in the ImageScannerResults
        // You are responsible for dismissing the ImageScannerController
        let selectedImage = results.croppedScan.image
        scanner.dismiss(animated: true)
        self.scannerViewController = ImageScannerController()
        
        if let key = Database.database().reference().child("solutionUpdates").childByAutoId().key {
            let sortNum = self.addedDict.count + self.imgDict.count
            self.addedDict["\(sortNum)-imager-local-\(key)"] = selectedImage
            self.images?.append("\(sortNum)-imager-local-\(key)")
        }
        self.saveNow = true
        self.addButton.setTitle("SAVE", for: .normal)
        self.addButton.backgroundColor = UIColor(red: 0.9569, green: 0.6863, blue: 0, alpha: 1.0)
        self.collectionView.reloadData()
    }
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        // The user tapped 'Cancel' on the scanner
        // You are responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let myURL = urls.first else {
                return
            }
        let images = convertPDFToImages(pdfURL: myURL)
         
         // Process the array of images as desired
         if let images = images {
         for image in images {
             if let key = Database.database().reference().child("solutionUpdates").childByAutoId().key {
                 let sortNum = self.addedDict.count + self.imgDict.count
                 self.addedDict["\(sortNum)-imager-local-\(key)"] = image
                 self.images?.append("\(sortNum)-imager-local-\(key)")
             }
         }
             self.saveNow = true
             self.addButton.setTitle("SAVE", for: .normal)
             self.addButton.backgroundColor = UIColor(red: 0.9569, green: 0.6863, blue: 0, alpha: 1.0)
             self.collectionView.reloadData()
         }
        print("added images :\(addedDict.count) \(addedDict)")
    }
    func convertPDFToImages(pdfURL: URL) -> [UIImage]? {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            return nil
        }
        
        var images: [UIImage] = []
        
        for pageNum in 0..<pdfDocument.pageCount {
            if let pdfPage = pdfDocument.page(at: pageNum) {
                let pdfPageSize = pdfPage.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pdfPageSize.size)
                
                let image = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(pdfPageSize)
                    ctx.cgContext.translateBy(x: 0.0, y: pdfPageSize.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    
                    pdfPage.draw(with: .mediaBox, to: ctx.cgContext)
                }
                
                images.append(image)
            }
        }
        
        return images
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

class expandCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func layoutSubviews() {
        imageView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        imageView.clipsToBounds = true
    }
    
}
extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
