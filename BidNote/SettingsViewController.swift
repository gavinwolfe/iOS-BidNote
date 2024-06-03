//
//  SettingsViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 11/21/23.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController, completedTax, UITextFieldDelegate {
    
    
    
    @IBOutlet weak var venmoStudioLabel: UILabel!
    
    @IBOutlet weak var venmoContentLabel: UILabel!
    
    @IBOutlet weak var accountPinStudioLabel: UILabel!
    
    @IBOutlet weak var changePayoutButton: UIButton!
    
    @IBOutlet weak var pinContentLabel: UILabel!
    
    @IBOutlet weak var changePinButton: UIButton!
    
    @IBOutlet weak var memorizeLabel: UILabel!
    
    @IBOutlet weak var appleAppButton: UIButton!
    
    @IBOutlet weak var appleNotificationsButton: UIButton!
    var viewShowPayouts = UIView()
    var tempPayId: String?
    var enteredPayoutType: String?
    var editingPhone = false
    @IBAction func appSettingsAction(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    @IBAction func notificationSettingsAction(_ sender: Any) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
            UIApplication.shared.open(appSettings)
        }
    }
    
    var viewingTaxInfo = false
    override func viewDidLoad() {
        super.viewDidLoad()

        changePayoutButton.layer.cornerRadius = 8
        changePinButton.layer.cornerRadius = 8
        
        getPayoutAccount()
        // Do any additional setup after loading the view.
    }
    
    func getPayoutAccount () {
        let ref = Database.database().reference()
        if let uid = Auth.auth().currentUser?.uid {
            ref.child("users").child(uid).observeSingleEvent(of: .value, with: { snapshot in
                let values = snapshot.value as? [String: AnyObject]
                if let venmoAccount = values?["venmoPhone"] as? String {
                    self.venmoContentLabel.text = venmoAccount
                    self.venmoStudioLabel.text = "Venmo Phone Number"
                } else if let venmoEmail = values?["venmoEmail"] as? String {
                    self.venmoContentLabel.text = venmoEmail
                    self.venmoStudioLabel.text = "Venmo Email"
                } else if let paypalEmail = values?["paypalEmail"] as? String {
                    self.venmoContentLabel.text = paypalEmail
                    self.venmoStudioLabel.text = "PayPal Email"
                } else {
                    self.venmoContentLabel.text = "No Account Added"
                }
                if let pin = values?["loginPin"] as? String {
                    self.pinContentLabel.text = "Starts with \(pin[0])..."
                } else {
                    self.pinContentLabel.text = "No Pin Added"
                }
            })
        }
    }
    
    func showUserPayout() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        viewShowPayouts = UIView()
        viewShowPayouts.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        viewShowPayouts.backgroundColor = UIColor(white: 0.3, alpha: 0.8)
        let offersView = UIView(frame: CGRect(x: 10, y: view.frame.height - 355, width: view.frame.width - 20, height: 270))
        offersView.backgroundColor = .white
        offersView.layer.cornerRadius = 10
        let gestureView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 355))
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
        subLabel.text = "Please add your Venmo or PayPal in order to recieve payouts from BidNote for comissions on your material. Your account information is NEVER shared publicly. Commissions are paid by BidNote to you directly."
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
            let alert2 = UIAlertController(title: "Phone Number", message: "Enter the phone number connected to your Venmo account. We will send commissions to this Venmo account. *PLEASE* make sure you entered the correct phone number before continuing!", preferredStyle: .alert)
            alert2.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Ie: 805..."
                textField.font = UIFont(name: "HelveticaNeue-Medium", size: 17)
                textField.autocorrectionType = .default
                self.editingPhone = true
                textField.delegate = self
                textField.keyboardType = .phonePad
                textField.keyboardAppearance = .dark
            }
            let attributedString = NSAttributedString(string: "Phone Number", attributes: [
                NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
                NSAttributedString.Key.foregroundColor : UIColor.systemBlue
                ])
            alert2.setValue(attributedString, forKey: "attributedTitle")
          
            let saveAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { alert -> Void in
                guard var text = alert2.textFields?[0].text?.westernArabicNumeralsOnly, text.count >= 10, text.count <= 11, !text.contains(" ") else {
                    let alertMore = UIAlertController(title: "Invalid Phone Entry", message: "Please make sure your phone input is 10-11 digits long.", preferredStyle: .alert)
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
                textField.keyboardAppearance = .dark
                textField.autocapitalizationType = .none
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
                textField.keyboardAppearance = .dark
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
        let key = idEntered.trimmingTrailingSpaces.replacingOccurrences(of: ".", with: ",")
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
        }
    }
    
    func allCheckedComplete() {
        if let uid = Auth.auth().currentUser?.uid {
            self.viewingTaxInfo = false
            if let payId = tempPayId, let payoutType = enteredPayoutType {
                let ref = Database.database().reference().child("users").child(uid)
                ref.child("venmoPhone").removeValue()
                ref.child("venmoEmail").removeValue()
                ref.child("paypalEmail").removeValue()
                if payoutType == "venmoemail" {
                    updateVenmoForUserEmail(email: payId)
                    self.venmoContentLabel.text = payId
                    self.tempPayId = nil
                    self.enteredPayoutType = nil
                    self.venmoStudioLabel.text = "Venmo Email"
                } else if payoutType == "venmophone" {
                    updateVenmoForUserPhoneNumber(phoneNum: payId)
                    self.venmoContentLabel.text = payId
                    self.venmoStudioLabel.text = "Venmo Phone Number"
                    self.tempPayId = nil
                    self.enteredPayoutType = nil
                } else if payoutType == "paypalemail" {
                    updatePayPalForUserEmail(email: payId)
                    self.venmoContentLabel.text = payId
                    self.venmoStudioLabel.text = "PayPal Email"
                    self.tempPayId = nil
                    self.enteredPayoutType = nil
                }
                self.removePayoutsView()
            }
        }
    }
    
    func askForSecretPin(uid: String) {
        let alertSecond = UIAlertController(title: "Make a Pin", message: "What happens if you accidentally delete the app or get a new phone? Use this Pin to get your purchased material back.", preferredStyle: .alert)
        alertSecond.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Create your 4-6 digit pin..."
            textField.autocorrectionType = .default
            textField.keyboardType = .numberPad
            textField.autocapitalizationType = .sentences
        }
        let saveAct = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
            if let newPrice = alertSecond.textFields?[0].text, newPrice.count >= 4, !newPrice.contains(" ") {
                let ref = Database.database().reference().child("users")
                ref.child(uid).updateChildValues(["loginPin": newPrice])
                self.pinContentLabel.text = "Starts with \(newPrice[0])..."
                return
            } else {
                let alert = UIAlertController(title: "Error, please make this Pin at least 4 digits. No Spaces.", message: "This pin is never shared with anyone. It is just for account recovery purposes.", preferredStyle: .alert)
                let canc = UIAlertAction(title: "okay", style: .cancel)
                alert.addAction(canc)
                self.present(alert, animated: true)
            }
        })
        let cancelTitleEdit = UIAlertAction(title: "Cancel", style: .cancel, handler: { alert -> Void in
        })
        alertSecond.addAction(saveAct)
        alertSecond.addAction(cancelTitleEdit)
        alertSecond.preferredAction = saveAct
        self.present(alertSecond, animated: true)
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
    
    @IBAction func changePayoutAction(_ sender: Any) {
        showUserPayout()
    }
    
    
    @IBAction func changePinAction(_ sender: Any) {
        if let uid = Auth.auth().currentUser?.uid {
            self.askForSecretPin(uid: uid)
        }
    }
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension String {
    var westernArabicNumeralsOnly: String {
        let pattern = UnicodeScalar("0")..."9"
        return String(unicodeScalars
            .flatMap { pattern ~= $0 ? Character($0) : nil })
    }
}
