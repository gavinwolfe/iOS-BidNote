//
//  NewSolutionPreviewViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 8/6/23.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseFunctions
protocol dismissNewSolVC {
    func dismissVC()
}
protocol completedTax {
    func allCheckedComplete()
}
protocol addZoomLink {
    func addZoom()
}
protocol unblurPreview {
    func unblurFirstPreview()
}

class NewSolutionPreviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, completedTax, addZoomLink, unblurPreview, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!

    var payoutID: String?
    var solutionTitle: String?
    var solutionDes: String?
    var solutionPrice: Double?
    var solutionTags: [String]?
    var solutionImages: [UIImage]?
    var solutionLink: String?
    var viewShowPayouts = UIView()
    var delegateVC: dismissNewSolVC?
    var tempPayId: String?
    var enteredPayoutType: String?
    var viewingTaxInfo = false
    var blurredImages: [UIImage]?
    var orderImages = [imageObj]()
    var zoomLink: String?
    var unBlurFirstPreview = false
    var editingPhone = false
    var urlForFreeOrPreview = ""
    lazy var functions = Functions.functions()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.traitCollection.userInterfaceStyle == .light {
            self.navigationController?.navigationBar.tintColor = .white
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.estimatedRowHeight = 68.0
        tableView.rowHeight = UITableView.automaticDimension
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        view.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        tableView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        if let images = solutionImages {
            var indent = 0
            for each in images {
                var newImgObject = imageObj()
                newImgObject.img = each
                newImgObject.order = indent
                if !orderImages.contains( where: { $0.order == indent } ) {
                    orderImages.append(newImgObject)
                }
                indent += 1
            }
        }
        // Do any additional setup after loading the view.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let images = self.solutionImages, let titleS = self.solutionTitle, let solDes = self.solutionDes, let tags = self.solutionTags, let price = self.solutionPrice {
            if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionPreviewCell1", for: indexPath) as? tableViewCell1SolutionPreview
                var tagsString = "Tags/Course Name: "
                var start = 1
                for each in tags {
                    if start == tags.count {
                        tagsString = tagsString + "\(each) "
                    } else {
                        tagsString = tagsString + "\(each), "
                    }
                    start = start + 1
                }
                cell?.tagsLabel.attributedText = tagsString.withBoldText(text: "Tags/Course Name:", font: UIFont(name: "HelveticaNeue", size: 16))
                cell?.labelTitle.text = titleS
                return cell ?? UITableViewCell()
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionPreviewCell2", for: indexPath) as? tableViewCell2SolutionPreview
                cell?.images = images
                return cell ?? UITableViewCell()
            } else if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionPreviewCell3", for: indexPath) as? segmentTbPreview
                return cell ?? UITableViewCell()
            } else if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionPreviewCell4", for: indexPath) as? tableViewCell4SolutionPreview
                cell?.descriptLabel.text = solDes
                return cell ?? UITableViewCell()
            } else if indexPath.row == 4 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionPreviewCell5", for: indexPath) as? tableViewCell5SolutionPreview
                if price.decimalCount() == 1 {
                    cell?.priceButton.setTitle("View for $\(price)0", for: .normal)
                } else if price.decimalCount() == 0 {
                    cell?.priceButton.setTitle("View for $\(price)0", for: .normal)
                } else if price.decimalCount() == 2 {
                    cell?.priceButton.setTitle("View for $\(price)", for: .normal)
                }
                if price == 0.0 {
                    cell?.unblurPrev.isHidden = true
                } else {
                    cell?.unblurPrev.isHidden = false
                    cell?.delegate2 = self
                }
                cell?.delegate = self
                return cell ?? UITableViewCell()
            }
        }
        return UITableViewCell()
    }
    
    func showUserPayout() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        viewShowPayouts = UIView()
        viewShowPayouts.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        viewShowPayouts.backgroundColor = UIColor(white: 0.3, alpha: 0.8)
        let offersView = UIView(frame: CGRect(x: 10, y: view.frame.height - 305, width: view.frame.width - 20, height: 270))
        offersView.backgroundColor = .white
        offersView.layer.cornerRadius = 10
        let gestureView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 305))
        gestureView.backgroundColor = .clear
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(removePayoutsView))
        gestureView.addGestureRecognizer(gesture)
        viewShowPayouts.addSubview(gestureView)
        let labelTitle = UILabel(frame: CGRect(x: 10, y: 15, width: offersView.frame.width - 20, height: 30))
        labelTitle.textColor = .black
        labelTitle.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        labelTitle.text = "Add a Venmo or PayPal"
        labelTitle.textAlignment = .center
        let subLabel = UILabel(frame: CGRect(x: 10, y: 55, width: offersView.frame.width - 20, height: 100))
        subLabel.textColor = .gray
        subLabel.text = "Please add your Venmo or PayPal in order to recieve payouts from BidNote for comissions on your content. Your account information is NEVER shared publicly. Commissions are paid by BidNote to you directly."
        subLabel.numberOfLines = 0
        subLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 16)
        subLabel.textAlignment = .center
        let paypalButton = UIButton(frame: CGRect(x: 30, y: 165, width: offersView.frame.width - 60, height: 40))
        let venmoButton = UIButton(frame: CGRect(x: 30, y: 215, width: offersView.frame.width - 60, height: 40))
        paypalButton.setTitle("PayPal", for: .normal)
        venmoButton.setTitle("Venmo", for: .normal)
        venmoButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        paypalButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        paypalButton.backgroundColor = UIColor(red: 0, green: 0.2941, blue: 0.9294, alpha: 1.0)
        paypalButton.addTarget(self, action: #selector(selectedPayPal), for: .touchUpInside)
        venmoButton.addTarget(self, action: #selector(selectedVenmo), for: .touchUpInside)
        venmoButton.backgroundColor = .systemBlue
        paypalButton.layer.cornerRadius = 10
        venmoButton.layer.cornerRadius = 10
        offersView.addSubview(labelTitle)
        offersView.addSubview(subLabel)
        offersView.addSubview(paypalButton)
        offersView.addSubview(venmoButton)
        viewShowPayouts.addSubview(offersView)
        self.view.addSubview(viewShowPayouts)
    }
    @objc func removePayoutsView() {
        viewShowPayouts.removeFromSuperview()
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    @objc func selectedVenmo() {
        let alert = UIAlertController(title: "Venmo Payouts/Commissions", message: "Add the Phone Number or Email associated with your Venmo. Again: BidNote does not provide this information to any users/purchasers.", preferredStyle: .alert)
       
        let action1 = UIAlertAction(title: "Phone Number", style: .default, handler: { alert -> Void in
            let alert2 = UIAlertController(title: "Phone Number", message: "Enter the U.S. phone number connected to your Venmo account. We will send commissions to this Venmo account. *PLEASE* make sure you entered the correct phone number before continuing!", preferredStyle: .alert)
            alert2.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Ie: 805.."
                textField.keyboardAppearance = .dark
                textField.font = UIFont(name: "HelveticaNeue-Medium", size: 17)
                textField.autocorrectionType = .default
                textField.keyboardType = .phonePad
                self.editingPhone = true
                textField.delegate = self
            }
            let attributedString = NSAttributedString(string: "Phone Number", attributes: [
                NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
                NSAttributedString.Key.foregroundColor : UIColor.systemBlue
                ])
            alert2.setValue(attributedString, forKey: "attributedTitle")
          
            let saveAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { alert -> Void in
                guard var text = alert2.textFields?[0].text?.westernArabicNumeralsOnly, text.count >= 10, text.count <= 11, !text.contains(" ") else {
                    let alertMore = UIAlertController(title: "Invalid Phone Entry", message: "Please make sure your phone number is a valid 10-11 digits phone number. ie: 8001234567", preferredStyle: .alert)
                    let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                    alertMore.addAction(cancel2)
                    self.present(alertMore, animated: true, completion: nil)
                    self.editingPhone = false
                    return
                }
                if let lettersFound = text.rangeOfCharacter(from: NSCharacterSet.letters) {
                    print("found characters maybe pasted")
                    
                    return
                }
                var phoneText = text
                if text.count == 11 {
                    phoneText = String(phoneText.dropFirst())
                }
                if self.checkIfCorrectPunctuationPhone(entered: phoneText) {
                    
                    self.checkIfBanned(idEntered: phoneText, type: "venmophone")
                        
                } else {
                    print("failed phone")
                }
                self.editingPhone = false
            })
            let cancel2 = UIAlertAction(title: "Cancel", style: .cancel, handler: { alert -> Void in
                self.editingPhone = false
            })
            alert2.addAction(cancel2)
            alert2.addAction(saveAction)
            alert2.preferredAction = saveAction
            self.present(alert2, animated: true)
            
        })
        let action2 = UIAlertAction(title: "Email", style: .default, handler: { alert -> Void in
            let alert3 = UIAlertController(title: "Enter Email", message: "Please enter the email linked to your Venmo account. We will use this to send commission payouts.", preferredStyle: .alert)
            alert3.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Email here..."
                textField.autocorrectionType = .no
                textField.keyboardType = .emailAddress
                textField.autocapitalizationType = .none
                textField.keyboardAppearance = .dark
                textField.font = UIFont(name: "HelveticaNeue-Medium", size: 17)
            }
            let attributedString = NSAttributedString(string: "Enter Email", attributes: [
                NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
                NSAttributedString.Key.foregroundColor : UIColor.systemBlue
                ])
            alert3.setValue(attributedString, forKey: "attributedTitle")
          
            let saveAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { alert -> Void in
                if let text = alert3.textFields?[0].text {
                    if self.checkIfCorrectPunctuationEmail(entered: text) {
                        //user entered a venmo account and it is formatted correctly, now check if they are banned, then post this account, then solution to admin queue
                         self.checkIfBanned(idEntered: text, type: "venmoemail")
                        
                    }
                }
            })
            let cancel2 = UIAlertAction(title: "Cancel", style: .cancel)
            alert3.addAction(saveAction)
            alert3.addAction(cancel2)
            alert3.preferredAction = saveAction
            self.present(alert3, animated: true)
            
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(action1)
        alert.addAction(action2)
        alert.preferredAction = action1
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    @objc func selectedPayPal() {
        let alert = UIAlertController(title: "PayPal Payouts/Commissions", message: "Add the Email associated with your PayPal. Again: BidNote does not provide this information to any users/purchasers.", preferredStyle: .alert)
       
        let action1 = UIAlertAction(title: "Email", style: .default, handler: { alert -> Void in
            let alert2 = UIAlertController(title: "Email linked to your PayPal", message: "Please enter your email that is linked to your PayPal account. We will use this to send you commission payouts.", preferredStyle: .alert)
            alert2.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Email here..."
                textField.autocorrectionType = .no
                textField.keyboardType = .emailAddress
                textField.autocapitalizationType = .none
                textField.font = UIFont(name: "HelveticaNeue-Medium", size: 17)
            }
            let attributedString = NSAttributedString(string: "Email", attributes: [
                NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
                NSAttributedString.Key.foregroundColor : UIColor.systemBlue
                ])
            alert2.setValue(attributedString, forKey: "attributedTitle")
          
            let saveAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { alert -> Void in
                if let text = alert2.textFields?[0].text {
                    if self.checkIfCorrectPunctuationEmail(entered: text) {
                        //user entered a paypal account and it is formatted correctly, now check if they are banned, then post this account, then solution to admin queue
                        self.checkIfBanned(idEntered: text, type: "paypalemail")
                    }
                }
            })
            let cancel2 = UIAlertAction(title: "Cancel", style: .cancel)
            alert2.addAction(saveAction)
            alert2.addAction(cancel2)
            alert2.preferredAction = saveAction
            self.present(alert2, animated: true)
            
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(action1)
        alert.preferredAction = action1
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    //check steps from done clicked
    var doneClicking = true
    @objc func doneTapped() {
        if viewingTaxInfo {
            doneClicking = true
            viewingTaxInfo = false
        }
        guard doneClicking else {
            return
        }
        self.doneClicking = false
        if let uid = Auth.auth().currentUser?.uid, let solPrice = solutionPrice, solPrice > 0 {
           getUserPayoutVenmo(uid: uid, completion: {(result) -> Void in
               if result != "" {
                   //user has a valid venmo account
                   self.checkIfBannedUserID()
               } else {
                   self.getUserPayoutPayPal(uid: uid, completion: {(result1) -> Void in
                       if result1 != "" {
                           //user has valid paypal
                           self.checkIfBannedUserID()
                       } else {
                           //user does not have valid paypal or venmo so ask them for one
                           self.showUserPayout()
                       }
                       
                   })
               }
          })
        } else if let solPrice = solutionPrice, solPrice == 0 {
            //price is 0 so doesnt matter
            self.checkIfBannedForFreePost()
        }
    }
    
    func getUserPayoutVenmo(uid: String, completion: @escaping (String) -> Void) {
        let ref = Database.database().reference().child("users").child(uid)
        ref.child("venmoPhone").observeSingleEvent(of: .value, with: { snapshot in
            if let dataReturned = snapshot.value as? String {
               completion(dataReturned)
            } else {
                ref.child("venmoEmail").observeSingleEvent(of: .value, with: { snapshot in
                    if let dataBack = snapshot.value as? String {
                       completion(dataBack)
                    } else {
                        completion("")
                    }
                })
            }
        })
    }
    
    func getUserPayoutPayPal(uid: String, completion: @escaping (String) -> Void) {
        let ref = Database.database().reference().child(uid).child("paypalEmail")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if let dataReturned = snapshot.value as? String {
               completion(dataReturned)
            } else {
                completion("")
            }
        })
    }
    
    func checkIfCorrectPunctuationEmail(entered: String) -> Bool {
        if entered.contains(" ") {
            let alertMore = UIAlertController(title: "Error!", message: "The PayPal/Venmo email you entered contains a space. This is not a correct email format. Please re enter a correct PayPal account email!", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return false
        } else if !entered.contains("@") || entered.count >= 127 {
            let alertMore = UIAlertController(title: "Error!", message: "The PayPal email you entered is not a correct format: must include an @", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return false
        } else if !entered.contains(".") || entered.contains("/") {
            let alertMore = UIAlertController(title: "Error!", message: "The PayPal email you entered is not a correct format: must include a .net .com .org etc", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return false
        }
        return true
    }
    func checkIfCorrectPunctuationPhone(entered: String) -> Bool {
        if entered.contains(" ") || entered.count >= 127 {
            let alertMore = UIAlertController(title: "Error!", message: "The PayPal/Venmo email you entered contains a space. This is not a correct email format. Please re enter a correct PayPal account email!", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
            return false
        }
        return true
    }
    func checkIfBannedForFreePost() {
        //check if the user id is banned for someone posting free
        let bannedRef = Database.database().reference().child("banned")
        if let uid = Auth.auth().currentUser?.uid {
            bannedRef.child(uid).observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    self.doneClicking = true
                    return
                } else {
                    self.checkIfSolutionIsComplete()
                }
            })
            
        }
    }
    func checkIfBanned(idEntered: String, type: String) {
        let bannedRef = Database.database().reference().child("banned")
        if let uid = Auth.auth().currentUser?.uid {
            bannedRef.child(uid).observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    print("banned")
                    return
                } else {
                    let res = idEntered.lowercased().filter{!$0.isWhitespace}
                    self.checkIfBannedPaymentAccount(idEntered: res, type: type)
                }
            })
        }
    }
    func checkIfBannedPaymentAccount(idEntered: String, type: String) {
        let bannedRef = Database.database().reference().child("bannedPayIds")
        let key = idEntered.trimmingTrailingSpaces.replacingOccurrences(of: ".", with: "")
        if let uid = Auth.auth().currentUser?.uid {
            bannedRef.child(key).observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    print("banned2")
                    return
                } else {
                    self.checkIfReadTax(enteredId: idEntered, type: type)
                }
            })
        }
    }
    func checkIfReadTax(enteredId: String, type: String) {
        let defaults = UserDefaults.standard
        tempPayId = enteredId
        enteredPayoutType = type
        if let readTax = defaults.object(forKey: "taxRead") as? Bool {
            if !readTax {
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "taxVC") as? TaxViewController {
                    vc.delegateNewSolution = self
                    self.viewingTaxInfo = true
                    self.present(vc, animated: true, completion: nil)
                }
            } else {
                self.allCheckedComplete()
            }
        } else {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "taxVC") as? TaxViewController {
                vc.delegateNewSolution = self
                self.viewingTaxInfo = true
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func checkIfBannedUserID() {
        let bannedRef = Database.database().reference().child("banned")
        if let uid = Auth.auth().currentUser?.uid {
            bannedRef.child(uid).observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    return
                } else {
                    self.checkIfSolutionIsComplete()
                }
            })
        }
    }
    
    
    func allCheckedComplete() {
        self.viewingTaxInfo = false
        if let payId = tempPayId, let payoutType = enteredPayoutType {
            if payoutType == "venmoemail" {
                updateVenmoForUserEmail(email: payId)
                self.checkIfSolutionIsComplete()
            } else if payoutType == "venmophone" {
                updateVenmoForUserPhoneNumber(phoneNum: payId)
                self.checkIfSolutionIsComplete()
            } else if payoutType == "paypalemail" {
                updatePayPalForUserEmail(email: payId)
                self.checkIfSolutionIsComplete()
            }
        }
    }
    
    func isValidEmail(testStr:String) -> Bool {
                print("validate emilId: \(testStr)")
                let emailRegEx = "^(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?(?:(?:(?:[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+(?:\\.[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+)*)|(?:\"(?:(?:(?:(?: )*(?:(?:[!#-Z^-~]|\\[|\\])|(?:\\\\(?:\\t|[ -~]))))+(?: )*)|(?: )+)\"))(?:@)(?:(?:(?:[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)(?:\\.[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)*)|(?:\\[(?:(?:(?:(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))\\.){3}(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))))|(?:(?:(?: )*[!-Z^-~])*(?: )*)|(?:[Vv][0-9A-Fa-f]+\\.[-A-Za-z0-9._~!$&'()*+,;=:]+))\\])))(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?$"
                let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: testStr)
                return result
            }
    
    func blurImage(image:UIImage) -> UIImage? {
            let context = CIContext(options: nil)
            let inputImage = CIImage(image: image)
            let originalOrientation = image.imageOrientation
            let originalScale = image.scale

            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(40.0, forKey: kCIInputRadiusKey)
            let outputImage = filter?.outputImage

            var cgImage:CGImage?

            if let asd = outputImage
            {
                cgImage = context.createCGImage(asd, from: (inputImage?.extent)!)
            }

            if let cgImageA = cgImage
            {
                return UIImage(cgImage: cgImageA, scale: originalScale, orientation: originalOrientation)
            }

            return nil
        }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if self.editingPhone {
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = newString.components(separatedBy: NSCharacterSet.decimalDigits.inverted)

            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.hasPrefix("1")

            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int

                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()

            if hasLeadingOne {
                formattedString.append("1 ")
                index += 1
            }
            if (length - index) > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@)", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }

            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            return false
        }
        else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2 {
            return 100
        } else if indexPath.row == 1 {
            return view.frame.width / 1.1
        } else if indexPath.row == 3 {
            return UITableView.automaticDimension
        } else if indexPath.row == 4 {
            return 140
        }
        return 50
    }
    
    
    func updateVenmoForUserPhoneNumber(phoneNum: String) {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users").child(uid)
            ref.updateChildValues(["venmoPhone": phoneNum])
        }
    }
    func updatePayPalForUserEmail(email: String) {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users").child(uid)
            ref.updateChildValues(["paypalEmail": email])
        }
    }
    func updateVenmoForUserEmail(email: String) {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users").child(uid)
            ref.updateChildValues(["venmoEmail": email])
        }
    }
    let activity = UIActivityIndicatorView()
    func checkIfSolutionIsComplete() {
        self.navigationController?.navigationBar.isHidden = true
        if let images = solutionImages, let descript = solutionDes, let titleOfSolution = solutionTitle, let tags = solutionTags, let price = solutionPrice, let uid = Auth.auth().currentUser?.uid, let solId = Database.database().reference().child("solutions").childByAutoId().key {
            let ref = Database.database().reference().child("adminQueue")
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            var count = 0;
            activity.frame = view.frame
            activity.color = .white
            activity.backgroundColor = .opaqueSeparator
            activity.startAnimating()
            view.addSubview(activity)
            var tagsDict = [String: String]()
            for each in tags {
                let key = each.trimmingTrailingSpaces.replacingOccurrences(of: " ", with: "-")
                tagsDict[key.lowercased()] = each
            }
            let time: Int = Int(NSDate().timeIntervalSince1970)
            let valUpdate = ["solId": solId, "price": price, "solDescription" : descript, "solTitle": titleOfSolution, "solTags" : tagsDict, "creatorId": uid, "time": time, "weight": 25, "views": 0] as [String : Any]
            let fullUpdate = [solId: valUpdate]
            ref.updateChildValues(fullUpdate)
            Database.database().reference().child("users").child(uid).child("solutionsPosted").updateChildValues([solId: solId])
            for each in orderImages {
                count+=1
                if let key = Database.database().reference().child("solutions").child(solId).child("images").childByAutoId().key {
                    let storage = Storage.storage().reference().child("images").child(uid).child(key)
                    if let uploadData = each.img.jpegData(compressionQuality: 0.6) {
                        storage.putData(uploadData, metadata: nil, completion:
                                            { (metadata, error) in
                            print("at least here")
                            guard let metadata = metadata else {
                                // Uh-oh, an error occurred!
                                print(error!)
                                self.navigationController?.navigationBar.isHidden = false
                                return
                            }
                            print(metadata)
                            let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                            storage.downloadURL { url, error in
                                guard let downloadURL = url else {
                                    print("erroor downl")
                                    return
                                }
                                var imageOrder = 0
                                if let order = each.order {
                                    imageOrder = order
                                }
                                let urlLoad = downloadURL.absoluteString
                                let result = ["urlPhoto" : urlLoad, "time" : timeStamp, "key" : key, "postedByUid" : uid, "order": imageOrder] as [String : Any]
                                let update = [key : result]
                                ref.child(solId).child("images").updateChildValues(update)
                                if self.unBlurFirstPreview == true || price == 0.0 {
                                    if self.urlForFreeOrPreview == "" {
                                        self.urlForFreeOrPreview = urlLoad
                                    }
                                }
                                if count == images.count {
                                    count = 0
                                    self.createBlurredImages(idSol: solId, price: price) { bool in
                                        if bool == true {
                                            self.activity.stopAnimating()
                                            self.handleCompletion(solId: solId)
                                        } else {
                                            let alertMore = UIAlertController(title: "Error!", message: "Something went wrong! Please try again.", preferredStyle: .alert)
                                            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                                            alertMore.addAction(cancel2)
                                            self.present(alertMore, animated: true, completion: nil)
                                        }
                                    }
                                   
                                }
                                
                            }
                            
                        })
                    }
                }
            }
        } else {
            self.doneClicking = true
        }
    }
    
    
    
    func handleCompletion(solId: String) {
        let overView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        overView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        let helpFulLabel = UILabel(frame: CGRect(x: 20, y: view.frame.height / 2 - 150, width: view.frame.width - 40, height: 100))
        helpFulLabel.text = "Congrats: Your material has been posted to BidNote! Your material is processing and will be live within the next hour."
        helpFulLabel.numberOfLines = 0
        helpFulLabel.textColor = .white
        helpFulLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        helpFulLabel.textAlignment = .center
        let successView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        successView.tintColor = .green
        successView.frame = CGRect(x: view.frame.width / 2 - 60, y: 100, width: 120, height: 120)
        if UIScreen.main.nativeBounds.height <= 1634 {
            successView.frame = CGRect(x: view.frame.width / 2 - 60, y: 20, width: 120, height: 120)
        }
        let doneButton = UIButton(frame: CGRect(x: 50, y: view.frame.height / 2 - 20, width: view.frame.width - 100, height: 50))
        doneButton.setTitle("Done", for: .normal)
        successView.contentMode = .scaleAspectFit
        doneButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        doneButton.titleLabel?.textColor = .white
        doneButton.backgroundColor = .systemBlue
        doneButton.layer.cornerRadius = 10.0
        doneButton.addTarget(self, action: #selector(finalDone), for: .touchUpInside)
        overView.addSubview(helpFulLabel)
        overView.addSubview(doneButton)
        overView.addSubview(successView)
        self.view.addSubview(overView)
        if let link = zoomLink {
            let ref = Database.database().reference().child("adminQueue").child(solId)
            ref.updateChildValues(["zoomLink": link])
        }
        if self.unBlurFirstPreview == true && self.urlForFreeOrPreview != "" {
            let ref = Database.database().reference().child("adminQueue").child(solId)
            ref.updateChildValues(["unblurPreview": self.urlForFreeOrPreview])
        }
        self.notifyAdmins()
        
    }
    
    func createBlurredImages(idSol: String, price: Double, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference().child("adminQueue")
        if let images = solutionImages, let uid = Auth.auth().currentUser?.uid {
            var count = 0
            if price == 0.0 {
                if let key = Database.database().reference().child("solutions").child(idSol).child("blurredImages").childByAutoId().key, self.urlForFreeOrPreview != "" {
                    let result = [key: self.urlForFreeOrPreview]
                    ref.child(idSol).child("blurredImages").updateChildValues(result)
                    completion(true)
                    return
                }
            } else {
                for each in images {
                    count += 1
                    print("loop \(count)")
                    if let result = blurImage(image: each) {
                        if let key = Database.database().reference().child("solutions").child(idSol).child("blurredImages").childByAutoId().key {
                            let storage = Storage.storage().reference().child("blurredImages").child(uid).child(key)
                            if let uploadData = result.jpegData(compressionQuality: 0.1) {
                                storage.putData(uploadData, metadata: nil, completion:
                                                    { (metadata, error) in
                                    print("at least here")
                                    guard let metadata = metadata else {
                                        // Uh-oh, an error occurred!
                                        print(error!)
                                        completion(false)
                                        self.navigationController?.navigationBar.isHidden = false
                                        return
                                    }
                                    storage.downloadURL { url, error in
                                        guard let downloadURL = url else {
                                            print("erroor downl")
                                            completion(false)
                                            return
                                        }
                                        let urlLoad = downloadURL.absoluteString
                                        let result = [key: urlLoad]
                                        ref.child(idSol).child("blurredImages").updateChildValues(result)
                                        if count == images.count {
                                            print("images count : \(images.count) and \(count)")
                                            completion(true)
                                        }
                                    }
                                })
                            }
                        }
                    }
                }
            }
        } else {
            completion(false)
        }
    }
    
    func notifyAdmins() {
        let ref = Database.database().reference()
        ref.child("adminUsers").observeSingleEvent(of: .value, with: { snap in
            if let vals = snap.value as? [String: String] {
                for (_,each) in vals {
                    self.sendNotification(sub_id: each, message: "New Material Posted: Please check admin review ASAP.")
                }
            }
            
        })
    }
    var usersNotified = [String]()
    func sendNotification (sub_id: String, message: String) {
        if !self.usersNotified.contains(sub_id) {
            self.usersNotified.append(sub_id)
            self.functions.httpsCallable("oneSignalCall").call(["userKey": sub_id, "notif_message": message]) { (result, error) in
                if let error = error {
                    debugPrint("⭕️Notification: ", error)
                    print("failed")
                }
            }
        }
    }
    
    @objc func finalDone() {
        self.dismiss(animated: true, completion: {
            self.delegateVC?.dismissVC()
        })
    }
    
    func random(digits:Int) -> String {
        var number = String()
        for _ in 1...digits {
           number += "\(Int.random(in: 1...9))"
        }
        return number
    }
    
    func addZoom() {
        let alertController = UIAlertController(title: "Add a video link", message: "", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Paste LINK here..."
            textField.autocorrectionType = .default
            textField.keyboardType = .twitter
            textField.autocapitalizationType = .sentences
        }
        let attributedString = NSAttributedString(string: "Add a video link", attributes: [
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
            if let linkInputted = alertController.textFields?[0].text, !linkInputted.contains(" ") {
                self.zoomLink = linkInputted
                let alert = UIAlertController(title: "Success", message: "Video link added to this tutoring review/material!", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "okay", style: .cancel)
                alert.addAction(cancel)
                self.present(alert, animated: true)
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(saveAction)
        alertController.addAction(cancel)
        alertController.preferredAction = saveAction
        self.present(alertController, animated: true)
    }
    
    func unblurFirstPreview() {
        let alertController = UIAlertController(title: "Unblur First Preview Image?", message: "This is a way to let potential purchasers see a glimpse of what content you posted. This DOES mean that the first page will be visible to all users regardless of purchase history.", preferredStyle: UIAlertController.Style.alert)
        
        let act1 = UIAlertAction(title: "Make First Preview Image Visible", style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.unBlurFirstPreview = true
            let alert2 = UIAlertController(title: "Success!", message: "You've added an unblurred preview to your material. To cancel, exit this page and reopen.", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Done", style: .cancel)
            alert2.addAction(cancel2)
            self.present(alert2, animated: true)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(act1)
        alertController.addAction(cancel)
        self.present(alertController, animated: true)
    }

}
extension String {
    func withBoldText(text: String, font: UIFont? = nil) -> NSAttributedString {
      let _font = font ?? UIFont.systemFont(ofSize: 14, weight: .regular)
      let fullString = NSMutableAttributedString(string: self, attributes: [NSAttributedString.Key.font: _font])
      let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: _font.pointSize)]
      let range = (self as NSString).range(of: text)
      fullString.addAttributes(boldFontAttribute, range: range)
      return fullString
    }
}
extension Double {
    func decimalCount() -> Int {
        if self == Double(Int(self)) {
            return 0
        }

        let integerString = String(Int(self))
        let doubleString = String(Double(self))
        let decimalCount = doubleString.count - integerString.count - 1

        return decimalCount
    }
}


class tableViewCell1SolutionPreview: UITableViewCell {
    
    @IBOutlet weak var labelTitle: UILabel!
   
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        labelTitle.frame = CGRect(x: 15, y: 5, width: contentView.frame.width - 20, height: 55)
        tagsLabel.frame = CGRect(x: 15, y: 60, width: contentView.frame.width-20, height: 45)
       // allTagsLabel.frame = CGRect(x: 175, y: 52, width: contentView.frame.width - 142, height: 35)
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
    }
    
}

class tableViewCell4SolutionPreview: UITableViewCell {
    
    @IBOutlet weak var descriptLabel: UILabel!
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
    }
}
class tableViewCell5SolutionPreview: UITableViewCell {
    @IBOutlet weak var priceButton: UIButton!
    var delegate: addZoomLink?
    var delegate2: unblurPreview?
    override func layoutSubviews() {
        super.layoutSubviews()
        priceButton.frame = CGRect(x: 20, y: 5, width: contentView.frame.width - 40, height: 45)
        priceButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        priceButton.layer.cornerRadius = 4.0
        addZoomButton.frame = CGRect(x: 20, y: contentView.frame.height - 80, width: contentView.frame.width - 40, height: 30)
        unblurPrev.frame = CGRect(x: 20, y: contentView.frame.height - 40, width: contentView.frame.width - 40, height: 30)
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
    }
    @IBOutlet weak var unblurPrev: UIButton!
    
    @IBAction func unblurPreviewButton(_ sender: Any) {
        delegate2?.unblurFirstPreview()
    }
    
    
    @IBOutlet weak var addZoomButton: UIButton!
    
    @IBAction func actionZoom(_ sender: Any) {
        delegate?.addZoom()
    }
}



class tableViewCell2SolutionPreview: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var images: [UIImage]?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewLayout: UICollectionViewFlowLayout!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = CGRect(x: 10, y: 10, width: contentView.frame.width - 10, height: contentView.frame.height - 20)
        collectionView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "previewCV1", for: indexPath) as? previewCV1
        if let images = self.images {
            cell?.imageView.image = images[indexPath.item]
        }
        return cell ?? UICollectionViewCell()
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: contentView.frame.width / 1.2, height: contentView.frame.width / 1.2)
    }
    
    
}

class segmentTbPreview: UITableViewCell {
    
    @IBOutlet weak var segmentBar: UISegmentedControl!
    override func layoutSubviews() {
        super.layoutSubviews()
        segmentBar.frame = CGRect(x: 20, y: 10, width: contentView.frame.width - 40, height: 35)
        segmentBar.tintColor = .white
    }
}


class previewCV1: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        imageView.layer.cornerRadius = 12.0
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
    }
    
}
extension String {
    var trimmingTrailingSpaces: String {
        if let range = rangeOfCharacter(from: .whitespacesAndNewlines, options: [.anchored, .backwards]) {
            return String(self[..<range.lowerBound]).trimmingTrailingSpaces
        }
        return self
    }
}
