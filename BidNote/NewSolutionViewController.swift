//
//  NewSolutionViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 8/6/23.
//
import WeScan
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import PDFKit

protocol addNewPhoto {
    func present()
    func present2()
    func viewPhoto(img: UIImage)
}
protocol updateArray {
    func addItem(photo_new: photo)
    func addLink(link_new: String)
}
protocol deletePhoto {
    func deleteItem(photo: Int)
}
protocol addTag {
    func addTagAlert()
}
protocol updateTags {
    func addTag(tag: String)
}
protocol deleteTag {
    func deleteT(index: Int)
}
protocol removeLibrary {
    func removeLibrary()
}
protocol updateKeyborad {
    func insetKeyboard()
    func desetKeyboard()
}
protocol updateNewSVCTags {
    func deletedTag(index: Int)
}
protocol updateNewSVCImages {
    func deletedImage(index: Int)
}
protocol updateNewSVCTitlePrice {
    func changedTitle(new: String)
    func changePrice(new: Double)
}
protocol updateNewSVCDescript {
    func changedDescription(new: String)
}
protocol doneClicked {
    func donePressed()
}


class NewSolutionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, addNewPhoto, ImageScannerControllerDelegate, addTag, updateKeyborad, UIImagePickerControllerDelegate, UINavigationBarDelegate, UINavigationControllerDelegate, updateNewSVCTags, updateNewSVCImages, updateNewSVCDescript, updateNewSVCTitlePrice, doneClicked, dismissNewSolVC, UIDocumentPickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var prices = [0.99, 1.99, 2.99, 3.99, 4.99, 5.99, 6.99, 7.99, 9.99, 12.99, 14.99, 19.99]
    
    var keyboardTextView = false
    var delegate2: updateArray?
    var delegate3: updateTags?
    let cameraButton = UIButton()
    @IBOutlet weak var tableViewNewSolution: UITableView!
    var scannerViewController = ImageScannerController()
    
    var chosenScans = [UIImage]()
    var titleString: String?
    var price: Double?
    var link: String?
    var tags = [String]()
    var descriptString: String?
    let supportedDocs = [UTType.pdf]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.traitCollection.userInterfaceStyle == .light {
            self.navigationController?.navigationBar.tintColor = .black
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraButton.imageView?.contentMode = .scaleAspectFill
        self.cameraButton.setImage(UIImage(named: "addImage"), for: .normal)
        self.tableViewNewSolution.delegate = self
        self.tableViewNewSolution.dataSource = self
        self.tableViewNewSolution.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        NotificationCenter.default
            .addObserver(self,
                         selector:#selector(removeLibrary(_:)),
                         name: NSNotification.Name ("removeLibrary"),                                           object: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Tips/Help", style: .plain, target: self, action: #selector(self.tipsJump))
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.tableViewNewSolution.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
                self.tableViewNewSolution.reloadData()
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.tableViewNewSolution.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
                    self.tableViewNewSolution.reloadData()
                })
            }
        }
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    @objc func tipsJump() {
        if let url = URL(string: "https://bidnoteapp.com/helpful-tips") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    @objc func removeLibrary(_ notification: Notification) {
        self.cameraButton.isHidden = true
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell6PostSolution", for: indexPath) as? tbCell6PostSolution
            return cell ?? UITableViewCell()
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell1PostSolution", for: indexPath) as? tbCell1PostSolution
            cell?.delegate = self
            cell?.del = self
            cell?.updateVCDel = self
            return cell ?? UITableViewCell()
        } else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell2PostSolution", for: indexPath) as? tbCell2PostSolution
            cell?.delegateUpdateVC = self
            cell?.priceOf = price
            cell?.titleTextField.text = self.titleString
            if self.price == 0.0 {
                cell?.freeMode = true
                cell?.freeButton.backgroundColor = .systemBlue
                cell?.priceTextField.text = "$0.00"
            } else {
                cell?.priceTextField.text = priceString()
                cell?.freeMode = false
                cell?.freeButton.backgroundColor = .opaqueSeparator
            }
            return cell ?? UITableViewCell()
        } else if indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell3PostSolution", for: indexPath) as? tbCell3PostSolution
            cell?.delegate = self
            cell?.delegateUpdateVC = self
            cell?.del = self
            return cell ?? UITableViewCell()
        } else if indexPath.row == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell4PostSolution", for: indexPath) as? tbCell4PostSolution
            cell?.updateNewSvcDelegate = self
            cell?.delegate = self
            return cell ?? UITableViewCell()
        } else if indexPath.row == 5 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell5PostSolution", for: indexPath) as? tbCell5PostSolution
            cell?.updateNewScDelegate = self
            return cell ?? UITableViewCell()
        }
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
           return 55
        } else if indexPath.row == 1 {
            return (view.frame.width / 3) + 60
            
        } else if indexPath.row == 2 {
            return 115
            
        } else if indexPath.row == 3 {
            return (view.frame.width / 3.2) + 60
           
        } else if indexPath.row == 4 {
            return 145
        }
        return 60
    }
    func priceString() -> String {
        if let price = self.price {
            return "$\(price)"
        } else {
            return ""
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let tempImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let new_photo = photo()
        new_photo.imager = tempImage
        delegate2?.addItem(photo_new: new_photo)
        self.dismiss(animated: true, completion: nil)
        self.chosenScans.append(tempImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: {
            
        })
    }
    
    func present() {
        scannerViewController.modalPresentationStyle = .fullScreen
        scannerViewController.imageScannerDelegate = self
        present(scannerViewController, animated: true)
        
        self.cameraButton.frame = CGRect(x: view.frame.width - 100, y: view.frame.height - 105, width: 60, height: 60)
        self.cameraButton.isHidden = false
        self.cameraButton.tintColor = .white
        
        self.cameraButton.addTarget(self, action: #selector(self.openLibrary), for: .touchUpInside)
        scannerViewController.view.addSubview(self.cameraButton)
    }
    @objc func openLibrary() {
        scannerViewController.dismiss(animated: true)
        let imgPick = UIImagePickerController()
        imgPick.delegate = self
        imgPick.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        
        self.present(imgPick, animated: true, completion: {
            
        })
    }
    func presentAlert1() {
        let alertController = UIAlertController(title: "Add a link", message: "", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Paste LINK here..."
            textField.autocorrectionType = .default
            textField.keyboardType = .twitter
            textField.keyboardAppearance = .dark
            textField.autocapitalizationType = .sentences
            textField.tintColor = .blue
        }
        let attributedString = NSAttributedString(string: "Add a link", attributes: [
            NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
            NSAttributedString.Key.foregroundColor : UIColor.systemBlue
        ])
        alertController.setValue(attributedString, forKey: "attributedTitle")
        
        
        
        let saveAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { alert -> Void in
            guard alertController.textFields?[0].text?.count ?? 0 > 5 else {
                let alert = UIAlertController(title: "Format", message: "Please have at least 5 characters for links.", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "okay", style: .cancel)
                alert.addAction(cancel)
                self.present(alert, animated: true)
                return
            }
            if let linkInputted = alertController.textFields?[0].text {
                self.link = linkInputted
                self.delegate2?.addLink(link_new: linkInputted)
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(saveAction)
        alertController.addAction(cancel)
        alertController.preferredAction = saveAction
        self.present(alertController, animated: true)
    }
    func present2() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: self.supportedDocs, asCopy: true)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            documentPicker.shouldShowFileExtensions = true
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func addTagAlert() {
        
        let alertTag = UIAlertController(title: "Add a tag", message: "Type out each tag and press done. Try and add at least 2. Help people find your material, ie Physics, BIO, tutoring, etc..", preferredStyle: UIAlertController.Style.alert)
        alertTag.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Type a tag here...ie: BIO"
            textField.autocorrectionType = .default
            textField.keyboardType = .twitter
            textField.keyboardAppearance = .dark
            textField.autocapitalizationType = .sentences
        }
        let attributedString = NSAttributedString(string: "Add a tag", attributes: [
            NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
            NSAttributedString.Key.foregroundColor : UIColor.systemBlue
        ])
        alertTag.setValue(attributedString, forKey: "attributedTitle")
        
        
        
        let saveAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { [self] alert -> Void in
            if let text = alertTag.textFields?[0].text, text.count > 2, !text.contains("  "), !text.contains("*"), !text.contains("["), !text.contains("]"), !text.contains(",") {
                delegate3?.addTag(tag: text)
                tags.append(text)
            } else {
                let alert = UIAlertController(title: "Format", message: "Please no double spaces or characters like * [ ] or ,", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "okay", style: .cancel)
                alert.addAction(cancel)
                self.present(alert, animated: true)
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertTag.addAction(saveAction)
        alertTag.addAction(cancel)
        alertTag.preferredAction = saveAction
        self.present(alertTag, animated: true)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        // You are responsible for carefully handling the error
        print(error)
    }
    
    
    @IBAction func cancelAct(_ sender: Any) {
        self.cameraButton.isHidden = true
        self.dismiss(animated: true)
    }
    
    func insetKeyboard() {
        keyboardTextView = true
    }
    @objc func keyboardWillShow(notification: Notification) {
        guard keyboardTextView == true else { return }
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            print("Notification: Keyboard will show")
            tableViewNewSolution.setBottomInset(to: keyboardHeight)
            tableViewNewSolution.scrollToRow(at: IndexPath(row: 4, section: 0), at: .middle, animated: true)
        }
    }
    func desetKeyboard() {
        keyboardTextView = false
    }
    @objc func keyboardWillHide(notification: Notification) {
        print("Notification: Keyboard will hide")
        tableViewNewSolution.setBottomInset(to: 0.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        // The user successfully scanned an image, which is available in the ImageScannerResults
        // You are responsible for dismissing the ImageScannerController
        let selectedImage = results.croppedScan.image
        let new_photo = photo()
        new_photo.imager = selectedImage
        delegate2?.addItem(photo_new: new_photo)
        scanner.dismiss(animated: true)
        self.scannerViewController = ImageScannerController()
        
        self.chosenScans.append(selectedImage)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        // The user tapped 'Cancel' on the scanner
        // You are responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
    }
    func deletedTag(index: Int) {
        tags.remove(at: index)
        print(tags)
    }
    
    func deletedImage(index: Int) {
        chosenScans.remove(at: index)
    }
    
    func changedDescription(new: String) {
        self.descriptString = new
    }
    
    func changedTitle(new: String) {
        self.titleString = new
    }
    let screenWidth = UIScreen.main.bounds.width - 10
    let screenHeight = UIScreen.main.bounds.height / 2
    var selectedRow = 0
    func changePrice(new: Double) {
        print("called")
        if new != 0.0 {
            guard UIDevice().userInterfaceIdiom == .phone else {
                ipadPrice()
                return
            }
            let vc = UIViewController()
            vc.preferredContentSize = CGSize(width: screenWidth, height: screenHeight)
            let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: screenWidth, height:screenHeight))
            pickerView.dataSource = self
            pickerView.delegate = self
            
            pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
            //pickerView.selectRow(selectedRowTextColor, inComponent: 1, animated: false)
            
            vc.view.addSubview(pickerView)
            pickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
            pickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
            
            var alert = UIAlertController(title: "Select Price", message: "", preferredStyle: .actionSheet)
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = self.view.bounds
            
            alert.setValue(vc, forKey: "contentViewController")
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
            }))
            
            alert.addAction(UIAlertAction(title: "Select", style: .default, handler: { (UIAlertAction) in
                self.selectedRow = pickerView.selectedRow(inComponent: 0)
                //self.selectedRowTextColor = pickerView.selectedRow(inComponent: 1)
                let selected = self.prices[self.selectedRow]
                print(selected)
                self.price = selected
                self.tableViewNewSolution.reloadRows(at: [IndexPath(item: 2, section: 0)], with: .automatic)
                
                //let selectedTextColor = Array(self.backGroundColours)[self.selectedRowTextColor]
                //self.pickerViewButton.setTitleColor(selectedTextColor.value, for: .normal)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.price = new
        }
    }
    var priceView = UIView()
    var pickerView = UIPickerView()
    func ipadPrice() {
        priceView = UIView(frame: CGRect(x: 100, y: view.frame.height / 2 - 200, width: view.frame.width - 200, height: 400))
        priceView.backgroundColor = .opaqueSeparator
        let priceLab = UILabel(frame: CGRect(x: 50, y: 8, width: priceView.frame.width - 100, height: 25))
        priceLab.text = "Select a Price"
        priceLab.textAlignment = .center
        priceLab.font = UIFont(name: "HelveticaNeue-Medium", size: 17)
        priceView.addSubview(priceLab)
        pickerView = UIPickerView(frame: CGRect(x: 0, y: 30, width: priceView.frame.width, height:priceView.frame.height - 80))
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
        priceView.addSubview(pickerView)
        let doneButton = UIButton(frame: CGRect(x: 50, y: priceView.frame.height - 45, width: priceView.frame.width - 100, height: 40))
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.textColor = .systemBlue
        doneButton.setTitleColor(.systemBlue, for: .normal)
        doneButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        priceView.addSubview(doneButton)
        doneButton.addTarget(self, action: #selector(ipadDone), for: .touchUpInside)
        view.addSubview(priceView)
    }
    
    @objc func ipadDone() {
        self.selectedRow = pickerView.selectedRow(inComponent: 0)
        //self.selectedRowTextColor = pickerView.selectedRow(inComponent: 1)
        let selected = self.prices[self.selectedRow]
        print(selected)
        self.price = selected
        self.tableViewNewSolution.reloadRows(at: [IndexPath(item: 2, section: 0)], with: .automatic)
        self.priceView.removeFromSuperview()
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
        {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 30))
            label.text = "$" + String(prices[row])
            label.sizeToFit()
            return label
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int
        {
            return 1 //return 2
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
        {
            prices.count
        }
        
        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
        {
            return 60
        }
    
    func donePressed() {
        guard let price = self.price, let descript = self.descriptString, chosenScans.count >= 1, let titleSol = self.titleString, self.tags.count >= 1 else {
            let alertMore = UIAlertController(title: "Error!", message: "You must have:\n 1) At least 1 image added. \n 2) A title longer than 5 characters.\n 3) You must select free or enter price.\n 4) Must have a description that is at least 6 characters long.\n 5) You must have at least 1 tag!", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return
        }
        if descript.count < 4 {
            let alertMore = UIAlertController(title: "Error!", message: "Your description must be at least 6 characters!", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return
        } else if titleSol.count < 6 {
            let alertMore = UIAlertController(title: "Error!", message: "Your title must be at least 6 characters!", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return
        } else if  (0.01...0.98).contains(price) {
            let alertMore = UIAlertController(title: "Error!", message: "If not free, your material must be atleast 99 cents!", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return
        } else if price > 20.0 {
            let alertMore = UIAlertController(title: "Error!", message: "Material can be a maximum price of $20!", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return
        } else if titleSol.contains("*") || titleSol.contains("  ") || titleSol.contains("[") || titleSol.contains("]") || titleSol.contains(" , ") {
            let alertMore = UIAlertController(title: "Error!", message: "Please no double spaces or characters like * [ ] or spaces between commas in your Title", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return
        } else if self.chosenScans.count > 35 {
            let alertMore = UIAlertController(title: "Error!", message: "Please only add up to 35 images/pages.", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return
        }
        self.performSegue(withIdentifier: "showPreview", sender: self)
        
    //move to next screen
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPreview" {
            if let destinationVC = segue.destination as? NewSolutionPreviewViewController {
                destinationVC.solutionImages = self.chosenScans
                destinationVC.solutionTitle = self.titleString
                destinationVC.solutionDes = self.descriptString
                destinationVC.solutionTags = self.tags
                destinationVC.solutionPrice = self.price
                destinationVC.delegateVC = self
            }
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let myURL = urls.first else {
                return
            }
        let images = convertPDFToImages(pdfURL: myURL)
         
         // Process the array of images as desired
         if let images = images {
         for image in images {
             let new_photo = photo()
             new_photo.imager = image
             delegate2?.addItem(photo_new: new_photo)
             self.chosenScans.append(image)
         }
         }
    }
    
    func dismissVC() {
        self.dismiss(animated: false)
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
    
    func viewPhoto(img: UIImage) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "scanPreviewVC") as? scanPreviewVC {
            vc.imageToView = img
            self.present(vc, animated: true)
        }
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
extension UITableView {
    
    func setBottomInset(to value: CGFloat) {
        let edgeInset = UIEdgeInsets(top: 0, left: 0, bottom: value, right: 0)

        self.contentInset = edgeInset
        self.scrollIndicatorInsets = edgeInset
    }
}
extension ScannerViewController {
    public override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default
            .post(name: NSNotification.Name("removeLibrary"),
                  object: nil)
    }
}
class tbCell1PostSolution: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, updateArray, deletePhoto  {
    
   
    
    
    @IBOutlet weak var collectionViewLayout: UICollectionViewFlowLayout!
    
    var del: NewSolutionViewController?
    
    var delegate: addNewPhoto!
    var updateVCDel: updateNewSVCImages!
    var photos = [photo]()
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttonAddLink: UIButton!
    var productVC: NewSolutionViewController?
    
    
    @IBAction func newLink(_ sender: Any) {
        del?.delegate2 = self
        delegate.present2()
    }
    
    func addItem(photo_new: photo) {
        photos.append(photo_new)
        print("photos \(photos.count)")
        collectionView.reloadData()
    }
    func addLink(link_new: String) {
        buttonAddLink.setTitle(link_new, for: .normal)
    }
    func deleteItem(photo: Int) {
        photos.remove(at: photo-1)
        collectionView.reloadData()
        updateVCDel.deletedImage(index: photo-1)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.delegate = self
        collectionView.dataSource = self
       
        // Initialization code
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.layer.borderColor = UIColor.gray.cgColor
        collectionView.layer.borderWidth = 1.0
        collectionView.layer.cornerRadius = 3.0
        collectionView.frame = CGRect(x: 10, y: 10, width: contentView.frame.width - 10, height: (contentView.frame.width / 3) + 10)
        buttonAddLink.frame = CGRect(x: 10, y: contentView.frame.height - 35, width: 220, height: 30)
        buttonAddLink.layer.cornerRadius = 3.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            del?.delegate2 = self
            self.delegate.present()
        } else {
            if let image = photos[indexPath.item-1].imager {
                self.delegate.viewPhoto(img: image)
            }
        }
//        productVC?.selectedIndx = indexPath.row
//        productVC?.tagOrPub = whatSection
//        productVC?.performSegue(withIdentifier: "segueSelectedSearch", sender: nil)
//
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
           return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: contentView.frame.width / 3, height: contentView.frame.width / 3)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
    
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return photos.count+1
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCV2", for: indexPath) as? cellCV2
            cell?.imageViewPhoto.image = photos[indexPath.row-1].imager
            cell?.buttonDelete.tag = indexPath.row
            cell?.delegateDelete = self
            return cell ?? UICollectionViewCell()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCV1", for: indexPath) as? cellCV1
        
        return cell ?? UICollectionViewCell()
    }
    
}
class tbCell2PostSolution: UITableViewCell, UITextFieldDelegate {
    
    
    @IBOutlet weak var editPriceButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField! {
        didSet { priceTextField?.addDoneCancelToolbar() }
    }
    @IBOutlet weak var freeButton: UIButton!
    var currentString = ""
    var freeMode = false
    var delegateUpdateVC: updateNewSVCTitlePrice!
    var priceOf: Double?
    override func layoutSubviews() {
        super.layoutSubviews()
        titleTextField.translatesAutoresizingMaskIntoConstraints = true
        priceTextField.translatesAutoresizingMaskIntoConstraints = true
        titleTextField.setLeftPaddingPoints(5)
        priceTextField.setLeftPaddingPoints(5)
        titleTextField.frame = CGRect(x: 15, y: 10, width: contentView.frame.width - 30, height: 45)
        priceTextField.frame = CGRect(x: 15, y: 65, width: contentView.frame.width - 140, height: 45)
        priceTextField.isUserInteractionEnabled = false
        freeButton.frame = CGRect(x: contentView.frame.width - 110, y: 65, width: 95, height: 45)
        titleTextField.delegate = self
        priceTextField.delegate = self
        titleTextField.layer.borderColor = UIColor.gray.cgColor
        titleTextField.layer.borderWidth = 1.0
        priceTextField.layer.borderColor = UIColor.gray.cgColor
        priceTextField.layer.borderWidth = 1.0
        priceTextField.layer.cornerRadius = 3.0
        titleTextField.layer.cornerRadius = 3.0
        titleTextField.clipsToBounds = true
        priceTextField.clipsToBounds = true
        freeButton.layer.cornerRadius = 3.0
        editPriceButton.frame = CGRect(x: 15, y: 65, width: contentView.frame.width - 140, height: 45)
        titleTextField.addTarget(self, action: #selector(self.textFieldDidChangeTitle(_:)), for: .editingChanged)
        
    }
    @objc func textFieldDidChangeTitle(_ textField: UITextField) {
        delegateUpdateVC.changedTitle(new: textField.text ?? "")
    }
    
    @IBAction func editPriceAction(_ sender: Any) {
        delegateUpdateVC.changePrice(new: 1.0)
    }
    
    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        // return NO to not change text
//        guard textField == priceTextField else {
//
//            return true
//        }
//        if textField == priceTextField {
//            switch string {
//            case "0","1","2","3","4","5","6","7","8","9":
//                currentString += string
//                formatCurrency(string: currentString)
//            default:
//                if string.count == 0 && currentString.count != 0 {
//                    currentString = String(currentString.dropLast())
//                    formatCurrency(string: currentString)
//                }
//            }
//        }
//        return false
//    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
    }
    
    
    
    

    func formatCurrency(string: String) {
        print("format \(string)")
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.locale = NSLocale(localeIdentifier: "en_US") as Locale
        let numberFromField = (NSString(string: currentString).doubleValue)/100
        //replace billTextField with your text field name
        priceOf = numberFromField
       // delegateUpdateVC.changedPrice(new: numberFromField)
        self.priceTextField.text = formatter.string(from: NSNumber(value: numberFromField))
        print(self.priceTextField.text ?? "" )
    }
    
    @IBAction func freeAction(_ sender: Any) {
        freeMode = !freeMode
        if freeMode {
            freeButton.backgroundColor = UIColor.systemBlue
            currentString = ""
            self.priceTextField.text = "$0"
            delegateUpdateVC.changePrice(new: 0)
            self.priceTextField.resignFirstResponder()
        } else {
            self.priceTextField.text = ""
            delegateUpdateVC.changePrice(new: 0)
            freeButton.backgroundColor = .opaqueSeparator
        }
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField == priceTextField else {
            return
        }
        freeMode = false
        self.priceTextField.text = ""
        freeButton.backgroundColor = .opaqueSeparator
    }
    
   
}
extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}
class tbCell3PostSolution: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, updateTags, deleteTag  {
  
    
    var tags = [String]()
    
    var del: NewSolutionViewController?
    var delegate: addTag?
    var delegateUpdateVC: updateNewSVCTags!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var labelCourseNameTags: UILabel!
    
    @IBOutlet weak var collectionViewLayout: UICollectionViewFlowLayout!
    
    func addTag(tag: String) {
        tags.append(tag)
        collectionView.reloadData()
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.delegate = self
        collectionView.dataSource = self
        // Initialization code
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        labelCourseNameTags.frame = CGRect(x: 15, y: 5, width: 200, height: 30)
        collectionView.frame = CGRect(x: 15, y: 40, width: contentView.frame.width - 30, height: (contentView.frame.width / 3.2) + 10)
        collectionView.layer.borderColor = UIColor.gray.cgColor
        collectionView.layer.borderWidth = 1.0
        collectionView.layer.cornerRadius = 3.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            del?.delegate3 = self
            self.delegate?.addTagAlert()
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: 0)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: contentView.frame.width / 3.2, height: contentView.frame.width / 3.2)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func deleteT(index: Int) {
        self.tags.remove(at: index-1)
        collectionView.reloadData()
        delegateUpdateVC.deletedTag(index: index-1)
    }
  
    
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if whatSection == 2 {
//            return tags.count
//        }
        
        return tags.count + 1
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCV4", for: indexPath) as? cellCV4
            cell?.labelTagTitle.text = tags[indexPath.row-1]
            cell?.deleteButton.tag = indexPath.row
            cell?.delegate = self
            return cell ?? UICollectionViewCell()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCV3", for: indexPath) as? cellCV3
        return cell ?? UICollectionViewCell()
    }
    
}
class tbCell4PostSolution: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    var delegate: updateKeyborad?
    var updateNewSvcDelegate: updateNewSVCDescript!
    @IBOutlet weak var descriptLabel: UILabel!
    var textInputted = ""
    
    override func layoutSubviews() {
        super.layoutSubviews()
        descriptLabel.frame = CGRect(x: 15, y: 2, width: 200, height: 30)
        textView.frame = CGRect(x: 15, y: 37, width: contentView.frame.width - 30, height: contentView.frame.height - 45)
        textView.layer.cornerRadius = 3.0
        textView.delegate = self
        addDoneCancelToolbar()
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 2, bottom: 4, right: 2)
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.insetKeyboard()
        if textInputted == "" {
            textView.text = ""
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        textInputted = textView.text
        updateNewSvcDelegate.changedDescription(new: textView.text)
    }
    func addDoneCancelToolbar(onDone: (target: Any, action: Selector)? = nil, onCancel: (target: Any, action: Selector)? = nil) {
        let onCancel = onCancel ?? (target: self, action: #selector(cancelButtonTapped))
        let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))

        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(title: "Cancel", style: .plain, target: onCancel.target, action: onCancel.action),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        toolbar.sizeToFit()

        self.textView.inputAccessoryView = toolbar
    }
    

    // Default actions:
    @objc func doneButtonTapped() {
        delegate?.desetKeyboard()
        self.textView.resignFirstResponder()
        
    }
    @objc func cancelButtonTapped() {
        delegate?.desetKeyboard()
        self.textView.resignFirstResponder()
    }
    
}
class tbCell5PostSolution: UITableViewCell {
    
    var updateNewScDelegate: doneClicked!
    
    @IBOutlet weak var doneButton: UIButton!
    
    @IBAction func doneAction(_ sender: Any) {
        updateNewScDelegate.donePressed()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        doneButton.frame = CGRect(x: 35, y: 10, width: contentView.frame.width - 70, height: 50)
        doneButton.layer.cornerRadius = 5.0
    }
}
class tbCell6PostSolution: UITableViewCell {
   
    @IBOutlet weak var infoIcon: UIImageView!
    
    @IBOutlet weak var plagLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        infoIcon.frame = CGRect(x: 10, y: 15, width: 30, height: 30)
        plagLabel.frame = CGRect(x: 48, y: 0, width: contentView.frame.width - 50, height: 60)
    }
    
    
    
}



class cellCV1: UICollectionViewCell {
    
    @IBOutlet weak var labelAddNewPhoto: UILabel!
    
    @IBOutlet weak var newPhotoIcon: UIImageView!
    
    @IBOutlet weak var backView: UIView!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        newPhotoIcon.frame = CGRect(x: (contentView.frame.width / 2) - ((contentView.frame.width / 2)-10)/2, y: 20, width: ((contentView.frame.width / 2)-10), height: ((contentView.frame.width / 2)-10))
        backView.layer.cornerRadius = 3.0
        newPhotoIcon.layer.cornerRadius = 3.0
        labelAddNewPhoto.frame = CGRect(x: 5, y: ((contentView.frame.width / 2)-10) + 25, width: contentView.frame.width - 10, height: 25)
    }
    
}
class cellCV2: UICollectionViewCell {
    
    @IBOutlet weak var imageViewPhoto: UIImageView!
    
    @IBOutlet weak var buttonDelete: UIButton!
    
    @IBOutlet weak var backView: UIView!
    
    var delegateDelete: deletePhoto?
   
    override func layoutSubviews() {
        super.layoutSubviews()
        backView.layer.cornerRadius = 3.0
        imageViewPhoto.layer.cornerRadius = 3.0
        imageViewPhoto.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.width)
        backView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        buttonDelete.frame = CGRect(x: contentView.frame.width - 30, y: 10, width: 20, height: 20)
        buttonDelete.setTitle("", for: .normal)
    }
    
    @IBAction func deleteAction(_ sender: UIButton) {
        delegateDelete?.deleteItem(photo: sender.tag)
    }
    
    
}
class cellCV3: UICollectionViewCell {
    
    @IBOutlet weak var imageViewNewTag: UIImageView!
    
    @IBOutlet weak var labelNewTag: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageViewNewTag.frame = CGRect(x: (contentView.frame.width / 2) - ((contentView.frame.width / 2)-10)/2, y: 20, width: ((contentView.frame.width / 2)-10), height: ((contentView.frame.width / 2)-10))
        labelNewTag.frame = CGRect(x: 5, y: ((contentView.frame.width / 2)-10) + 25, width: contentView.frame.width - 10, height: 25)
        
    }
    
}
class cellCV4: UICollectionViewCell {
    
    var delegate: deleteTag?
    
    @IBOutlet weak var deleteButton: UIButton!
    
    
    @IBOutlet weak var labelTagTitle: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        labelTagTitle.frame = CGRect(x: 5, y: 20 , width: contentView.frame.width - 10, height: contentView.frame.height - 40)
        labelTagTitle.layer.cornerRadius = 3.0
        labelTagTitle.clipsToBounds = true
        deleteButton.frame = CGRect(x: contentView.frame.width - 30, y: 25, width: 20, height: 20)
        deleteButton.setTitle("", for: .normal)
        
    }
    
    
    @IBAction func deleteAction(_ sender: UIButton) {
        delegate?.deleteT(index: sender.tag)
    }
    
}
extension UITextField {
    func addDoneCancelToolbar(onDone: (target: Any, action: Selector)? = nil, onCancel: (target: Any, action: Selector)? = nil) {
        let onCancel = onCancel ?? (target: self, action: #selector(cancelButtonTapped))
        let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))

        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(title: "Cancel", style: .plain, target: onCancel.target, action: onCancel.action),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        toolbar.sizeToFit()

        self.inputAccessoryView = toolbar
    }

    // Default actions:
    @objc func doneButtonTapped() { self.resignFirstResponder() }
    @objc func cancelButtonTapped() { self.resignFirstResponder() }
}

class scanPreviewVC: UIViewController {
    var imageToView: UIImage?
    
    @IBOutlet weak var imageViewScan: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = self.imageToView {
            self.imageViewScan.image = image
        }
    }
}
