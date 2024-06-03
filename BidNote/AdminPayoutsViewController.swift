//
//  AdminPayoutsViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 11/17/23.
//

import UIKit
import FirebaseFunctions
import Firebase


class AdminPayoutsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var items = [adminPayoutObject]()
    lazy var functions = Functions.functions()
    let buttonMakeNewPayout = UIButton()
    var singlePayoutCallPhone = true
    var singlePayoutCallVenmoEmail = true
    var singlePayoutCallPayPalEmail = true
    var maxPayoutHit = false
    var emailPayoutPastOnce = true
    var archiveUpdateOnce = true
    let hidGest = UITapGestureRecognizer()
    let currentPayoutsView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        getOldPayouts()
        buttonMakeNewPayout.frame = CGRect(x: 50, y: view.frame.height - 150, width: view.frame.width - 100, height: 40)
        buttonMakeNewPayout.backgroundColor = .systemBlue
        buttonMakeNewPayout.setTitleColor(.white, for: .normal)
        buttonMakeNewPayout.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        buttonMakeNewPayout.setTitle("Add Review", for: .normal)
        buttonMakeNewPayout.layer.cornerRadius = 8.0
        buttonMakeNewPayout.addTarget(self, action: #selector(addPayout), for: .touchUpInside)
        currentPayoutsView.frame = CGRect(x: 0, y: view.frame.height - 200, width: view.frame.width, height: 180)
        view.addSubview(buttonMakeNewPayout)
        // Do any additional setup after loading the view.
    }
    
    @objc func addPayout() {
        let alert = UIAlertController(title: "Other Admin Actions", message: "Please note this is the LIMITED CALLS section of admin review. Please contact Gavin/confirm with him before clicking anything here.", preferredStyle: .actionSheet)
        let action2 = UIAlertAction(title: "Payout Update", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let alertReject = UIAlertController(title: "Please enter code", message: "Please enter manual admin utility code (us-115): ", preferredStyle: .alert)
            alertReject.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "enter https-response code..."
                textField.autocorrectionType = .default
                textField.keyboardType = .twitter
                textField.keyboardAppearance = .dark
                textField.autocapitalizationType = .none
            }
            let act1 = UIAlertAction(title: "complete", style: .default, handler: { alert -> Void in
                if alertReject.textFields?[0].text == "berlark9927" {
                    self.callPayouts()
                }
            })
            let canc = UIAlertAction(title: "cancel", style: .cancel)
            alertReject.addAction(act1)
            alertReject.addAction(canc)
            self.present(alertReject, animated: true)
        })
        let action3 = UIAlertAction(title: "// coming soon //", style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.showCurrentPayouts()
        })
        let cancel = UIAlertAction(title: "GOT IT / Cancel", style: .cancel)
        alert.addAction(action2)
        alert.addAction(action3)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    func callPayouts() {
        let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
        //payout admin structure: userid: {
        let ref = Database.database().reference().child("payoutAdmin")
        let defaultRef = Database.database().reference()
        //content dictionary: {sellerUid: totalSalesUSD}
        var content = [String: Double]()
        //payout data keys for each sellerId
        var sellerKeys = [String: [String: String]]()
        //payID and finalSalesTotal/what we pay the user dictionary:
        //phone number dict:
        var payIdAndFinalPricePhone = [String: Double]()
        //venmo email dict:
        var payIdAndFinalPriceVenmoEmail = [String: Double]()
        //paypal email dict
        var payIdAndFinalPricePayPalEmail = [String: Double]()
        //archiveDictValues
        var tempArchiveDict = [String: [String: Any]]()
        //loop through payoutAdmin
        var emailPayoutsForArchive = [String: Double]()
        var phonePayoutsForArchive = [String: Double]()
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if let vals = snapshot.value as? [String: [String: Double]] {
                for (sellerId, keyAndPriceDict) in vals {
                    for (payoutDataKey,salePrice) in keyAndPriceDict {
                        if let currentSaleTotalForSellerId = content[sellerId] {
                            content[sellerId] = (currentSaleTotalForSellerId + self.calculatePayoutPerItem(price: salePrice)).rounded(digits: 2)
                        } else {
                            content[sellerId] = self.calculatePayoutPerItem(price: salePrice)
                        }
                        //store the key for this sale in the sellerKeys dict
                        sellerKeys[sellerId] = [payoutDataKey: payoutDataKey]
                    }
                }
            }
            //check if we have any payouts, then proceed: remember content= {sellerId: totalSalesUSD}
            if content.count != 0 {
                //now for each seller id in content, lets grab their payout ID
                let userRef = Database.database().reference().child("users")
                let dispatch1 = DispatchGroup()
                for (sellerUID,payoutTotal) in content {
                    dispatch1.enter()
                    userRef.child(sellerUID).child("venmoPhone").observeSingleEvent(of: .value, with: { snap in
                        if let venmo = snap.value as? String {
                            payIdAndFinalPricePhone[venmo] = payoutTotal
                            tempArchiveDict[sellerUID] = ["sellerUid" : sellerUID, "time": timeStamp, "payTotal": payoutTotal, "payId": venmo, "keysOut": sellerKeys[sellerUID] ?? ["": ""]]
                            phonePayoutsForArchive[sellerUID] = payoutTotal
                            dispatch1.leave()
                        } else {
                            userRef.child(sellerUID).child("venmoEmail").observeSingleEvent(of: .value, with: { snap2 in
                                if let venmoEmail = snap2.value as? String {
                                    payIdAndFinalPriceVenmoEmail[venmoEmail] = payoutTotal
                                    tempArchiveDict[sellerUID] = ["sellerUid" : sellerUID, "time": timeStamp, "payTotal": payoutTotal, "payId": venmoEmail, "keysOut": sellerKeys[sellerUID] ?? ["": ""]]
                                    emailPayoutsForArchive[sellerUID] = payoutTotal
                                    dispatch1.leave()
                                } else {
                                    userRef.child(sellerUID).child("paypalEmail").observeSingleEvent(of: .value, with: { snap3 in
                                        if let paypalEmail = snap3.value as? String {
                                            payIdAndFinalPricePayPalEmail[paypalEmail] = payoutTotal
                                            tempArchiveDict[sellerUID] = ["sellerUid" : sellerUID, "time": timeStamp, "payTotal": payoutTotal, "payId": paypalEmail, "keysOut": sellerKeys[sellerUID] ?? ["": ""]]
                                            emailPayoutsForArchive[sellerUID] = payoutTotal
                                            dispatch1.leave()
                                        } else {
                                            print("no payout id")
                                            dispatch1.leave()
                                        }
                                    })
                                }
                            })
                        }
                    })
                }
                dispatch1.notify(queue: DispatchQueue.main) {
                    //start with VENMO email calls, then after 5 seconds, do PayPal, then wait 5 more seconds and do Phone.
                    if payIdAndFinalPriceVenmoEmail.count != 0 && self.singlePayoutCallVenmoEmail {
                        self.singlePayoutCallVenmoEmail = false
                        //first call is email only
                        //in order to pass data through the firebase function, we encode each object in a price string and a idstring. So for example what is passed into cloud function is gavinwolfe@me.com/jacob11@gmail.com/ and pricestring: 0.15/0.98/
                        //please note that each string ends with a /
                        var priceStr = ""
                        var idStr = ""
                        //loop through payIdAndFinalPriceEmail dictionary
                        for (sellerEmail,sellerTotalPayout) in payIdAndFinalPriceVenmoEmail {
                            //add the payoutTotal USD value to the price string
                            priceStr += "\(sellerTotalPayout)/"
                            //add the payout-paymentID (ie: gavinw@gmail.com) to the idString. please make sure to look through the textview that info and payout ids look correct!
                            idStr += "\(sellerEmail)/"
                            //if there is a single payoutID over 55$, we prompt this alert, we only call this once. THIS SHOULD BE CHANGED UPON USER GROWTH
                            if sellerTotalPayout >= 55.0 && !self.maxPayoutHit {
                                let alert = UIAlertController(title: "WARNING", message: "There are 1 or more users with total payments over 55$ USD Please look at database/payoutadmin", preferredStyle: .actionSheet)
                                let cancel = UIAlertAction(title: "okay", style: .cancel)
                                alert.addAction(cancel)
                                self.present(alert, animated: true)
                                self.maxPayoutHit = true
                                self.singlePayoutCallVenmoEmail = true
                                return
                            }
                        }
                        //NOW CALL CLOUD FUNCTION WITH STRING DATA
                        if priceStr.count > 0 && idStr.count > 0 && !idStr.contains(" ") {
                            self.functions.httpsCallable("payoutCall").call(["priceData": priceStr, "idData": idStr, "idType": "venmoEmail"]) { (result, error) in
                                if let error = error {
                                    print("ERROR in CALL!")
                                } else {
                                    print("function completed: success")
                                    //remove data from adminPayout
                                    // add to adminPayoutArchive
                                    //because venmo phone payments have delay, also the api is about 30 second delay, we dont want to update all users past payouts collections on firebase right away. that is why they are split up into email and phone. BUT we only want to call each once. Becase there are 2 email payout calls, we only want one update to the user payouts collection. So we do it first here, if this gets called. If this wasnt called, aka there are 0 payouts to venmo emails, then if there are any calls to paypal emails, it will be updated. emailPayoutsPastOnce gets turned to false here so payoutsPast update doesnt get recalled below for paypal email payouts
                                    for (sellerId, payOutAmt) in emailPayoutsForArchive {
                                        //remove the payout item! important that adminPayout items are deleted so we dont double pay
                                        ref.child(sellerId).removeValue()
                                        defaultRef.child("users").child(sellerId).child("payoutsPast").updateChildValues(["\(timeStamp)": payOutAmt])
                                    }
                                    self.emailPayoutPastOnce = false
                                    Database.database().reference().child("adminArchive").child("\(timeStamp)").updateChildValues(tempArchiveDict)
                                    self.archiveUpdateOnce = false
                                    let cont = Array(content.keys.map({$0}))
                                    self.sendNotification(content: cont)
                                    //we only want to call this once. BOTH NOTIFICATIONS AND ADMIN ARCHIVE
                                }
                                
                            }
                        }
                    } //venmo email call end
                    if payIdAndFinalPricePayPalEmail.count != 0 && self.singlePayoutCallPayPalEmail {
                        self.singlePayoutCallPayPalEmail = false
                        //first call is email only
                        //in order to pass data through the firebase function, we encode each object in a price string and a idstring. So for example what is passed into cloud function is gavinwolfe@me.com/jacob11@gmail.com/ and pricestring: 0.15/0.98/
                        //please note that each string ends with a /
                        var priceStrPayPal = ""
                        var idStrPayPal = ""
                        //loop through payIdAndFinalPriceEmail dictionary
                        for (sellerEmail,sellerTotalPayout) in payIdAndFinalPricePayPalEmail {
                            //add the payoutTotal USD value to the price string
                            priceStrPayPal += "\(sellerTotalPayout)/"
                            //add the payout-paymentID (ie: gavinw@gmail.com) to the idString. please make sure to look through the textview that info and payout ids look correct!
                            idStrPayPal += "\(sellerEmail)/"
                            //if there is a single payoutID over 55$, we prompt this alert, we only call this once. THIS SHOULD BE CHANGED UPON USER GROWTH
                            if sellerTotalPayout >= 55.0 && !self.maxPayoutHit {
                                let alert = UIAlertController(title: "WARNING", message: "There are 1 or more users with total payments over 55$ USD Please look at database/payoutadmin", preferredStyle: .actionSheet)
                                let cancel = UIAlertAction(title: "okay", style: .cancel)
                                alert.addAction(cancel)
                                self.present(alert, animated: true)
                                self.maxPayoutHit = true
                                self.singlePayoutCallPayPalEmail = true
                                return
                            }
                        }
                        //NOW CALL CLOUD FUNCTION WITH STRING DATA
                        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                            if priceStrPayPal.count > 0 && idStrPayPal.count > 0 && !idStrPayPal.contains(" ") {
                                self.functions.httpsCallable("payoutCall").call(["priceData": priceStrPayPal, "idData": idStrPayPal, "idType": "email"]) { (result, error) in
                                    if let error = error {
                                        print("ERROR in CALL!")
                                    } else {
                                        print("function completed: success")
                                        //remove data from adminPayout
                                        // add to adminPayoutArchive
                                        if self.emailPayoutPastOnce {
                                            for (sellerId, payOutAmt) in emailPayoutsForArchive {
                                                ref.child(sellerId).removeValue()
                                                defaultRef.child("users").child(sellerId).child("payoutsPast").updateChildValues(["\(timeStamp)": payOutAmt])
                                            }
                                            self.emailPayoutPastOnce = false
                                            //if no venmo email payouts, this will get called
                                        }
                                        if self.archiveUpdateOnce {
                                            Database.database().reference().child("adminArchive").child("\(timeStamp)").updateChildValues(tempArchiveDict)
                                            self.archiveUpdateOnce = false
                                            let cont = Array(content.keys.map({$0}))
                                            self.sendNotification(content: cont)
                                            //if no venmo email payouts, this will get called
                                        }
                                    }
                                    
                                }
                            }
                        }
                    }
                    if payIdAndFinalPricePhone.count != 0, self.singlePayoutCallPhone {
                        self.singlePayoutCallPhone = false
                        var priceString = ""
                        var idString = ""
                        for (sellerPhone,totalSellerPay) in payIdAndFinalPricePhone {
                            priceString += "\(totalSellerPay)/"
                            idString += "\(sellerPhone)/"
                            if totalSellerPay >= 55.0 && !self.maxPayoutHit {
                                let alert = UIAlertController(title: "WARNING", message: "There are 1 or more users with total payments over 55$ USD Please look at database/payoutadmin", preferredStyle: .actionSheet)
                                let cancel = UIAlertAction(title: "okay", style: .cancel)
                                alert.addAction(cancel)
                                self.present(alert, animated: true)
                                self.maxPayoutHit = true
                                self.singlePayoutCallPhone = true
                                return
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 14.0) {
                            if priceString.count > 0 && idString.count > 0 && !idString.contains(" ") {
                                self.functions.httpsCallable("payoutCall").call(["priceData": priceString, "idData": idString, "idType": "phone"]) { (result, error) in
                                    if let error = error {
                                        print("ERROR in CALL!")
                                    } else {
                                        print("function completed: success")
                                        for (sellerId, payoutAmt) in phonePayoutsForArchive {
                                            ref.child(sellerId).removeValue()
                                            defaultRef.child("users").child(sellerId).child("payoutsPast").updateChildValues(["\(timeStamp)": payoutAmt])
                                        }
                                        if self.archiveUpdateOnce {
                                            Database.database().reference().child("adminArchive").child("\(timeStamp)").updateChildValues(tempArchiveDict)
                                            let cont = Array(content.keys.map({$0}))
                                            self.sendNotification(content: cont)
                                        }
                                    }
                                }
                            }
                        }
                    } //phone function-call end
                } //notify call end
            }
        })
    }
    var sendOnceFailSafe = false
    func sendNotification (content: [String]) {
        let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
        print("sending notifications called")
        guard sendOnceFailSafe == false else {
            return
        }
        sendOnceFailSafe = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 45.0) {
            let dispatch = DispatchGroup()
            for userID in content {
                dispatch.enter()
                let ref = Database.database().reference()
                ref.child("users").child(userID).child("userKey").observeSingleEvent(of: .value, with: { snap in
                    if let sub_id = snap.value as? String {
                        let message = "We just sent you a commission payout! Please check your Venmo or PayPal account."
                        self.functions.httpsCallable("oneSignalCall").call(["userKey": sub_id, "notif_message": message]) { (result, error) in
                            if let error = error {
                                debugPrint("⭕️Notification: ", error)
                                print("failed")
                            }
                        }
                    }
                    if let key = ref.child("users").child(userID).child("inbox").childByAutoId().key {
                        let messageContained = "We sent a payout for your total daily commissions earned. This has been sent to the Venmo or PayPal account you listed on the app. Please visit the Help/Tax Info tab on your 'More' screen in the BidNote app for more info or questions."
                        let inboxUpdate = ["key": key, "type": "payout", "content": messageContained, "time": timeStamp, "read": 0] as [String : Any]
                        let finalUpdate = [key: inboxUpdate]
                        ref.child("users").child(userID).child("inbox").updateChildValues(finalUpdate)
                    }
                    dispatch.leave()
                })
            }
            dispatch.notify(queue: DispatchQueue.main) {
                print("completed notification calls")
            }
        }
    }
    
    func calculatePayoutPerItem(price: Double) -> Double {
        return (0.74*price).rounded(digits: 2)
//        if price <= 2.00 {
//            return (0.975*price - 0.49).rounded(digits: 2)
//        } else if price > 2.00 && price < 5.0 {
//            return (0.975*price - 0.51).rounded(digits: 2)
//        } else if price >= 5.00 && price < 10.0 {
//            return (0.975*price - 0.50 - 0.05*price).rounded(digits: 2)
//        } else {
//            return (0.975*price - 0.50 - 0.06*price).rounded(digits: 2)
//        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "adminPayoutsCell", for: indexPath) as? adminPayoutsCell
        if let timeVal = items[indexPath.row].timeVal, let userVal = items[indexPath.row].idsAndPayTotals, let key = items[indexPath.row].key {
            cell?.topLabel.text = "Payout: \(key)"
            cell?.midLabel.text = timeReturn(time: timeVal)
            cell?.bottomLabel.text = "Total count: \(userVal.count)"
            var stringOfData = ""
            for each in userVal {
                stringOfData = stringOfData + " " + each
            }
            cell?.textView.text = stringOfData
        }
        return cell ?? UITableViewCell()
    }
    
    func getOldPayouts() {
        let ref = Database.database().reference()
        ref.child("adminArchive").observeSingleEvent(of: .value, with: { snap in
            if let data = snap.value as? [String: [String: AnyObject]] {
                for (timeKey, each) in data {
                    let obj = adminPayoutObject()
                    obj.timeVal = Int(timeKey)
                    obj.key = timeKey
                    var itemsPayTotals = [String]()
                    for (_, valuesIn) in each {
                        if let payid = valuesIn["payId"] as? String, let totalPay = valuesIn["payTotal"] as? Double {
                           itemsPayTotals.append("\(payid):\(totalPay)")
                        }
                    }
                    obj.idsAndPayTotals = itemsPayTotals
                    if !self.items.contains( where: { $0.key == obj.key } ) {
                        self.items.append(obj)
                    }
                }
            }
            self.items = self.items.sorted(by: {$0.timeVal > $1.timeVal})
            self.tableView.reloadData()
        })
    }
    func timeReturn(time: Int) -> String {
        let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
        let timer = timeStamp - time
        if timer <= 59 {
            return "\(timer)s ago"
        }
        if timer > 59 && timer < 3600 {
            let minuters = timer / 60
            return "\(minuters) mins ago"
        }
        if timer > 59 && timer >= 3600 && timer < 86400 {
            let hours = timer / 3600
            if hours == 1 {
                return "\(hours) hr ago"
            } else {
                return "\(hours) hrs ago"
            }
        }
        if timer > 86400 {
            let days = timer / 86400
            return "\(days)days ago"
        }
        if timer > 2592000 {
            let months = timer/2592000
            return "\(months)months ago"
        }
        return ""
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220
    }
    
    func showCurrentPayouts() {
        let textView = UITextView()
        textView.frame = CGRect(x: 0, y: 0, width: currentPayoutsView.frame.width, height: 180)
        var textDict = [String: Double]()
        var textViewText = ""
        let ref = Database.database().reference()
        ref.child("payoutAdmin").observeSingleEvent(of: .value, with: { snapshot in
            if let data = snapshot.value as? [String: [String: Double]] {
                for (userUID, uniqKey) in data {
                    for (_,priceInt) in uniqKey {
                        if let currentTotal = textDict[userUID] {
                            textDict[userUID] = (currentTotal + priceInt).rounded(digits: 2)
                        } else {
                            textDict[userUID] = priceInt.rounded(digits: 2)
                        }
                    }
                }
            }
            for each in textDict {
                textViewText.append("\(each.key) : \(each.value) ")
            }
            textView.text = textViewText
            self.currentPayoutsView.addSubview(textView)
            self.view.addSubview(self.currentPayoutsView)
            self.hidGest.addTarget(self, action: #selector(self.hidePayoutView))
            self.hidGest.numberOfTapsRequired = 1
            self.currentPayoutsView.backgroundColor = .opaqueSeparator
            textView.textColor = .white
            textView.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
            textView.backgroundColor = .opaqueSeparator
            self.view.addGestureRecognizer(self.hidGest)
        })
    }
    
    @objc func hidePayoutView() {
        self.currentPayoutsView.removeFromSuperview()
        self.view.removeGestureRecognizer(hidGest)
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
class adminPayoutsCell: UITableViewCell {
    
    @IBOutlet weak var topLabel: UILabel!
    
    @IBOutlet weak var midLabel: UILabel!
    
    @IBOutlet weak var bottomLabel: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        topLabel.frame = CGRect(x: 15, y: 10, width: contentView.frame.width - 20, height: 30)
        midLabel.frame = CGRect(x: 15, y: 45, width: contentView.frame.width - 20, height: 30)
        bottomLabel.frame = CGRect(x: 15, y: 80, width: contentView.frame.width - 20, height: 30)
        textView.frame = CGRect(x: 10, y: 110, width: contentView.frame.width - 20, height: 110)
    }
}
