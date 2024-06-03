//
//  AdminViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/27/23.
//

import UIKit
import Firebase
import FirebaseFunctions
protocol refreshAdminPage {
    func refreshContent()
}

class AdminViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, refreshAdminPage {

    @IBOutlet weak var tableView: UITableView!
    
    var items = [adminReviewObject]()
    lazy var functions = Functions.functions()
    let otherActsButton = UIButton()
    var singlePayoutCall = true
    var singlePhonePayoutCall = true
    var maxPayoutHit = false
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        retrieveData()
        otherActsButton.frame = CGRect(x: 30, y: view.frame.height - 120, width: view.frame.width - 60, height: 35)
        otherActsButton.backgroundColor = .lightGray
        otherActsButton.setTitle("Other Actions", for: .normal)
        otherActsButton.titleLabel?.textColor = .white
        otherActsButton.layer.cornerRadius = 6.0
        view.addSubview(otherActsButton)
        otherActsButton.addTarget(self, action: #selector(self.otherActsAction), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let update = items[indexPath.row].update, update == "default" else {
            if let update = items[indexPath.row].update, update == "image" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "adminCell2", for: indexPath) as? adminCell2
                cell?.solutionTitleLabel.text = "Image Update"
                if let images = items[indexPath.row].images {
                    cell?.price.text = "image count: \(images.count)"
                }
                cell?.verdictButton.addTarget(self, action: #selector(verdictImages(sender:)), for: .touchUpInside)
                cell?.verdictButton.tag = indexPath.row
                return cell ?? UITableViewCell()
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "adminCell2", for: indexPath) as? adminCell2
            cell?.solutionTitleLabel.text = "Video Update"
            if let video = items[indexPath.row].solLink {
                cell?.price.text = "Link: \(video)"
            }
            cell?.verdictButton.addTarget(self, action: #selector(verdictUrl(sender:)), for: .touchUpInside)
            cell?.verdictButton.tag = indexPath.row
            return cell ?? UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "adminCell", for: indexPath) as? adminCell
        if let totalApproved = items[indexPath.row].approvedCount {
            if totalApproved == 0 {
                cell?.approvedView.backgroundColor = .red
            } else if totalApproved == 1 {
                cell?.approvedView.backgroundColor = .yellow
            } else {
                cell?.approvedView.backgroundColor = .systemGreen
            }
            cell?.approvedLabel.text = "Total approved sol(s): \(totalApproved)"
        } else {
            cell?.approvedLabel.text = "Total approved sol(s): NA*"
        }
        if let joinDate = items[indexPath.row].userJoinTime, joinDate != 0 {
            if hoursReturn(time: joinDate) == 0 {
                cell?.joinView.backgroundColor = .red
            } else if hoursReturn(time: joinDate) <= 24 {
                cell?.joinView.backgroundColor = .yellow
            } else {
                cell?.joinView.backgroundColor = .systemGreen
            }
            cell?.joinLabel.text = "User joined: \(timeReturn(time: joinDate))"
        } else {
            cell?.joinLabel.text = "User joined NA time ago**"
        }
        if let payoutId = items[indexPath.row].payoutId {
            cell?.payoutLabel.text = "payoutID: \(payoutId)"
        }
        if let purchasedCount = items[indexPath.row].purchased {
           
             if purchasedCount.count == 1 {
                cell?.purchasedView.backgroundColor = .yellow
            } else {
                cell?.purchasedView.backgroundColor = .systemGreen
            }
            cell?.purchasedLabel.text = "Purchased Count: \(purchasedCount.count)"
            
        } else {
            cell?.purchasedView.backgroundColor = .red
            cell?.purchasedLabel.text = "Purchased Count: 0"
        }
        if let time = items[indexPath.row].createdTime {
            cell?.timeLabel.text = "Posted \(timeReturn(time: time))"
        }
        if let price = items[indexPath.row].price {
            cell?.priceLabel.text = "Price: $\(price)"
        }
        if let title = items[indexPath.row].titleString {
            cell?.titleLabel.text = title
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if items[indexPath.row].update == "image" || items[indexPath.row].update == "video"  {
            return 150
        }
        return 310
    }
    
    @objc func verdictUrl(sender: UIButton) {
        if let solid = items[sender.tag].sid {
            let ref = Database.database().reference()
            let alert = UIAlertController(title: "Verdict", message: "As an Admin of BidNote, you must give a verdict within the guidelines of BidNote's policies. Please do not, for any reason what so ever, approve material that fail our guidelines. THIS INCLUDES IF THE Material IS NOTICEABLY FALSE. This team appreciates your help being an admin. Thank you.", preferredStyle: .actionSheet)
            let action1 = UIAlertAction(title: "Approve", style: UIAlertAction.Style.default, handler: { alert -> Void in
                if let link = self.items[sender.tag].solLink {
                    ref.child("solutions").child(solid).updateChildValues(["zoomLink": link])
                    ref.child("adminQueue").child(solid).removeValue()
                    self.items.removeAll()
                    self.tableView.reloadData()
                    self.retrieveData()
                }
            })
            let action2 = UIAlertAction(title: "Reject", style: UIAlertAction.Style.default, handler: { alert -> Void in
                self.handleReject(index: sender.tag, type: 2)
            })
            let action3 = UIAlertAction(title: "BAN and Reject", style: UIAlertAction.Style.default, handler: { alert -> Void in
                if let userId = self.items[sender.tag].userId {
                    let ref = Database.database().reference()
                    ref.child("banned").updateChildValues([userId: userId])
                    ref.child("adminQueue").child(solid).removeValue()
                    self.items.removeAll()
                    self.tableView.reloadData()
                    self.retrieveData()
                }
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(action1)
            alert.addAction(action2)
            alert.addAction(action3)
            alert.addAction(cancel)
            self.present(alert, animated: true)
        }
    }
    
    @objc func verdictImages(sender: UIButton) {
        if let solid = items[sender.tag].sid {
            let ref = Database.database().reference()
            let alert = UIAlertController(title: "Verdict", message: "As an Admin of BidNote, you must give a verdict within the guidelines of BidNote's policies. Please do not, for any reason what so ever, approve solutions that fail our guidelines. THIS INCLUDES IF THE SOLUTION IS NOTICEABLY FALSE. This team appreciates your help being an admin. Thank you.", preferredStyle: .actionSheet)
            let action1 = UIAlertAction(title: "Approve", style: UIAlertAction.Style.default, handler: { alert -> Void in
                ref.child("adminQueue").child(solid).child("images").observeSingleEvent(of: .value, with: { snap in
                    if let data = snap.value as? [String: AnyObject] {
                        ref.child("solutions").child(solid).child("images").updateChildValues(data)
                        ref.child("adminQueue").child(solid).removeValue()
                        self.items.removeAll()
                        self.tableView.reloadData()
                        self.retrieveData()
                    }
                })
            })
            let action2 = UIAlertAction(title: "Reject", style: UIAlertAction.Style.default, handler: { alert -> Void in
                self.handleReject(index: sender.tag, type: 1)
            })
            let action3 = UIAlertAction(title: "BAN and Reject", style: UIAlertAction.Style.default, handler: { alert -> Void in
                if let userId = self.items[sender.tag].userId {
                    let ref = Database.database().reference()
                    ref.child("banned").updateChildValues([userId: userId])
                    ref.child("adminQueue").child(solid).removeValue()
                    self.items.removeAll()
                    self.tableView.reloadData()
                    self.retrieveData()
                }
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(action1)
            alert.addAction(action2)
            alert.addAction(action3)
            alert.addAction(cancel)
            self.present(alert, animated: true)
        }
    }
    
    func handleReject(index: Int, type: Int) {
        let alertReject = UIAlertController(title: "Add Rejection Message", message: "Enter the reason why we rejected, and how to fix. 1 sentence max.", preferredStyle: .alert)
        alertReject.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Please write here..."
            textField.autocorrectionType = .default
            textField.keyboardType = .twitter
            textField.keyboardAppearance = .dark
            textField.autocapitalizationType = .sentences
            textField.tintColor = .blue
        }
        let attributedString = NSAttributedString(string: "Add Rejection Message", attributes: [
            NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
        ])
        alertReject.setValue(attributedString, forKey: "attributedTitle")
        let action1 = UIAlertAction(title: "Finish", style: UIAlertAction.Style.default, handler: { alert -> Void in
            if let solId = self.items[index].sid, let text = alertReject.textFields?[0].text, let userId = self.items[index].userId {
                let ref = Database.database().reference()
                ref.child("adminQueue").child(solId).removeValue()
                let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                if let key = ref.child("users").child(userId).child("inbox").childByAutoId().key {
                    var contentString = "Your image update has been Rejected: \(text);"
                    if type == 2 {
                        contentString = "Your video url update has been Rejected: \(text);"
                    }
                    let update = ["key": key, "type": "reject", "content": contentString, "time": timeStamp] as [String : Any]
                    let finalUpdate = [key: update]
                    ref.child("users").child(userId).child("inbox").updateChildValues(finalUpdate)
                    ref.child("users").child(userId).updateChildValues(["inboxUnseen": 1])
                    ref.child("users").child(userId).child("userKey").observeSingleEvent(of: .value, with: { snap in
                        if let value = snap.value as? String {
                            if type == 1 {
                                self.sendNotification(sub_id: value, message: "We've sent you a message about the material images that you recently uploaded. Check your inbox in the app!")
                            } else {
                                self.sendNotification(sub_id: value, message: "We've sent you a message about the video url that you recently uploaded. Check your inbox in the app!")
                            }
                        }
                    })
                } else {
                    print("key failed")
                }
                self.refreshContent()
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertReject.addAction(action1)
        alertReject.addAction(cancel)
        self.present(alertReject, animated: true)
    }
    
    func refreshContent() {
        self.items.removeAll()
        self.tableView.reloadData()
        self.retrieveData()
    }
    func sendNotification (sub_id: String, message: String) {
        self.functions.httpsCallable("oneSignalCall").call(["userKey": sub_id, "notif_message": message]) { (result, error) in
            if let error = error {
                debugPrint("⭕️Notification: ", error)
                print("failed")
            }
        }
    }
    func retrieveData() {
        let ref = Database.database().reference().child("adminQueue")
        let userRef = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value, with: { snap in
            if let values = snap.value as? [String: AnyObject] {
                let dispatch = DispatchGroup()
                for (_,ad2) in values {
                    if let isJustUpdate = ad2["adminUpdate"] as? String {
                        let object = adminReviewObject()
                        object.update = "image"
                        if let sid = ad2["solId"] as? String {
                            object.sid = sid
                        }
                        if let suid = ad2["creatorId"] as? String {
                            object.userId = suid
                        }
                        if let time = ad2["time"] as? Int {
                            object.createdTime = time
                        }
                        if let images = ad2["images"] as? [String: AnyObject] {
                            var urls = [String]()
                            for (_,img) in images {
                                if let url = img["urlPhoto"] as? String {
                                    if !urls.contains(url) {
                                        urls.append(url)
                                    }
                                }
                            }
                            object.images = urls
                        }
                        if !self.items.contains( where: { $0.sid == object.sid } ) {
                            print("added")
                            self.items.append(object)
                        }
                    } else if let urlUpdate = ad2["adminUpdateVideo"] as? String {
                        let object = adminReviewObject()
                        object.update = "video"
                        if let sid = ad2["solId"] as? String {
                            object.sid = sid
                        }
                        if let suid = ad2["creatorId"] as? String {
                            object.userId = suid
                        }
                        if let time = ad2["time"] as? Int {
                            object.createdTime = time
                        }
                        if let url = ad2["videoUrl"] as? String {
                            object.solLink = url
                        }
                        if !self.items.contains( where: { $0.sid == object.sid } ) {
                            print("added")
                            self.items.append(object)
                        }
                    } else {
                        dispatch.enter()
                        let object = adminReviewObject()
                        if let key = ad2["solId"] as? String {
                            object.sid = key
                        }
                        if let time = ad2["time"] as? Int {
                            object.createdTime = time
                        }
                        if let titleS = ad2["solTitle"] as? String {
                            object.titleString = titleS
                        }
                        if let price = ad2["price"] as? Double {
                            object.price = price
                        }
                        if let link = ad2["solLink"] as? String {
                            object.solLink = link
                        }
                        object.update = "default"
                        if let createdTime = ad2["time"] as? Int {
                            object.createdTime = createdTime
                        } else {
                            object.createdTime = 0
                        }
                        if let images = ad2["images"] as? [String: AnyObject] {
                            var urls = [String]()
                            for (_,img) in images {
                                if let url = img["urlPhoto"] as? String {
                                    if !urls.contains(url) {
                                        urls.append(url)
                                    }
                                }
                            }
                            object.images = urls
                        }
                        if let descr = ad2["solDescription"] as? String {
                            object.descript = descr
                        }
                        if let tags = ad2["solTags"] as? [String: String] {
                           object.tags = tags.values.map({$0})
                        }
                        if let userID = ad2["creatorId"] as? String {
                            object.userId = userID
                            userRef.child(userID).observeSingleEvent(of: .value, with: { snapshot in
                                if let userValues = snapshot.value as? [String: AnyObject] {
                                    let vals = snapshot.value as? [String : AnyObject]
                                    if let purchased = vals?["purchased"] as? [String: [String: AnyObject]] {
                                        object.purchased = Array(purchased.keys)
                                    }
                                    if let approved = vals?["approvedSolutions"] as? [String: String] {
                                        object.approvedCount = approved.count
                                    } else {
                                        object.approvedCount = 0
                                    }
                                    if let joinedDate = vals?["joinedTime"] as? Int {
                                        object.userJoinTime = joinedDate
                                    } else {
                                        object.userJoinTime = 0
                                    }
                                    if let payoutId = vals?["venmoPhone"] as? String {
                                        object.payoutId = payoutId
                                    } else if let payOutIdVenmoEmail = vals?["venmoEmail"] as? String {
                                        object.payoutId = payOutIdVenmoEmail
                                    } else if let payoutPaypal = vals?["paypalEmail"] as? String {
                                        object.payoutId = payoutPaypal
                                    } else if object.price == 0.0 {
                                        object.payoutId = "free"
                                    }
                                }
                                if !self.items.contains( where: { $0.sid == object.sid } ) {
                                    print("added")
                                    self.items.append(object)
                                    self.items.sort(by: { $0.createdTime > $1.createdTime })
                                }
                                dispatch.leave()
                            })
                        }
                    }
                }
                dispatch.notify(queue: DispatchQueue.main) {
                    print("reloaded")
                    self.tableView.reloadData()
                }
            }
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
    
    func hoursReturn(time: Int) -> Int {
        let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
        let timer = timeStamp - time
        if timer > 3600 {
            let hours = timer / 3600
           return hours
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let type = items[indexPath.row].update, type == "image" {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "expandVC") as? ExpandViewController {
                vc.editMode = false
                vc.images = self.items[indexPath.row].images
                self.present(vc, animated: true, completion: nil)
            }
        }
        else if items[indexPath.row].update == "video", let link = items[indexPath.row].solLink {
            if let url = URL(string: link) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "verdictVC") as? VerdictViewController {
                if let descript = items[indexPath.row].descript, let solId = items[indexPath.row].sid, let tags = items[indexPath.row].tags, let titleS = items[indexPath.row].titleString, let images = items[indexPath.row].images, let suid = items[indexPath.row].userId {
                    vc.descript = descript
                    vc.images = images
                    vc.titleString = titleS
                    vc.tags = tags
                    vc.solId = solId
                    vc.suid = suid
                    vc.delegate = self
                    if let userPayId = items[indexPath.row].payoutId {
                        vc.payId = userPayId
                    }
                }
                if let solLink = items[indexPath.row].solLink {
                    vc.solLink = solLink
                }
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @objc func otherActsAction() {
        var alert = UIAlertController(title: "Other Admin Actions", message: "Please note this is the LIMITED CALLS section of admin review. Please contact Gavin/confirm with him before clicking anything here.", preferredStyle: .actionSheet)
        if UIDevice().userInterfaceIdiom == .pad {
            alert = UIAlertController(title: "Other Admin Actions", message: "Please note this is the LIMITED CALLS section of admin review. Please contact Gavin/confirm with him before clicking anything here.", preferredStyle: .alert)
        }
        let action1 = UIAlertAction(title: "Tag Views Update", style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.updateViewTags()
        })
        let action2 = UIAlertAction(title: "Payouts", style: UIAlertAction.Style.default, handler: { alert -> Void in
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
                    if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "adminPayoursVC") as? AdminPayoutsViewController {
                        self.present(vc, animated: true, completion: nil)
                    }
                }
            })
            let canc = UIAlertAction(title: "cancel", style: .cancel)
            alertReject.addAction(act1)
            alertReject.addAction(canc)
            self.present(alertReject, animated: true)
        })
        let action3 = UIAlertAction(title: "Weight Update", style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.updateSolutionWeight()
        })
        let cancel = UIAlertAction(title: "GOT IT / Cancel", style: .cancel)
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    func updateViewTags() {
        let ref = Database.database().reference().child("tagViews")
        let popRef = Database.database().reference().child("popularTags")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if let dataReturned = snapshot.value as? [String: [String: String]] {
                for (one, each) in dataReturned {
                    popRef.updateChildValues([one: each.count])
                }
            }
        })
    }
    
    func updateSolutionWeight() {
        let ref = Database.database().reference()
        ref.child("solutions").observeSingleEvent(of: .value, with: { snapshotWeight in
            if let dataReturned = snapshotWeight.value as? [String: AnyObject] {
                for (each,valu) in dataReturned {
                    if let views = valu["views"] as? [String: String] {
                        if views.count > 5 {
                            let newWeight = Int.random(in: 20..<45)
                            ref.child("solutions").child(each).updateChildValues(["weight": newWeight])
                        } else {
                            let newWeight = Int.random(in: 1..<31)
                            ref.child("solutions").child(each).updateChildValues(["weight": newWeight])
                        }
                    } else {
                        let newWeight = Int.random(in: 1..<31)
                        ref.child("solutions").child(each).updateChildValues(["weight": newWeight])
                        
                    }
                }
            }
        })
    }
    
    
//    func callPayouts() {
//        let ref = Database.database().reference().child("payoutAdmin")
//        var content = [String: Double]()
//        var tempArchiveDict = [String: String]()
//        var payIdAndFinalPriceEmail = [String: Double]()
//        var payIdAndFinalPricePhone = [String: Double]()
//        ref.observeSingleEvent(of: .value, with: { snapshot in
//            if let vals = snapshot.value as? [String: [String: Double]] {
//                for (each, each1) in vals {
//                    let key = each
//                    for (_,pric) in each1 {
//                        if let currentVal = content[key] {
//                            content[each] = currentVal + self.calculatePayoutPerItem(price: pric)
//                        } else {
//                            content[each] = self.calculatePayoutPerItem(price: pric)
//                        }
//                    }
//                }
//            }
//            if content.count != 0 {
//                let userRef = Database.database().reference().child("users")
//                print(content)
//                let dispatch1 = DispatchGroup()
//                for (key_id,endPrice) in content {
//                    dispatch1.enter()
//                    userRef.child(key_id).child("venmoPhone").observeSingleEvent(of: .value, with: { snap in
//                        if let venmo = snap.value as? String {
//                            payIdAndFinalPricePhone[venmo] = endPrice
//                            tempArchiveDict[key_id] = "\(venmo)/\(endPrice)"
//                            dispatch1.leave()
//                        } else {
//                            userRef.child(key_id).child("venmoEmail").observeSingleEvent(of: .value, with: { snap2 in
//                                if let venmoEmail = snap2.value as? String {
//                                    payIdAndFinalPriceEmail[venmoEmail] = endPrice
//                                    tempArchiveDict[key_id] = "\(venmoEmail)/\(endPrice)"
//                                    dispatch1.leave()
//                                } else {
//                                    userRef.child(key_id).child("paypalEmail").observeSingleEvent(of: .value, with: { snap3 in
//                                        if let paypalEmail = snap3.value as? String {
//                                            payIdAndFinalPriceEmail[paypalEmail] = endPrice
//                                            tempArchiveDict[key_id] = "\(paypalEmail)/\(endPrice)"
//                                            dispatch1.leave()
//                                        } else {
//                                            print("no payout id")
//                                            dispatch1.leave()
//                                        }
//                                    })
//                                }
//                            })
//                        }
//                    })
//                }
//                dispatch1.notify(queue: DispatchQueue.main) {
//                    if payIdAndFinalPriceEmail.count != 0 && self.singlePayoutCall {
//                        self.singlePayoutCall = false
//                        //first call is email only
//                        var priceStr = ""
//                        var idStr = ""
//                        for (strid,dprice) in payIdAndFinalPriceEmail {
//                            priceStr += "\(dprice)/"
//                            idStr += "\(strid)/"
//                            if dprice >= 40.0 && !self.maxPayoutHit {
//                                let alert = UIAlertController(title: "WARNING", message: "There are 1 or more users with total payments over 40$ USD Please look at database/payoutadmin", preferredStyle: .alert)
//                                let cancel = UIAlertAction(title: "okay", style: .cancel)
//                                alert.addAction(cancel)
//                                self.present(alert, animated: true)
//                                self.maxPayoutHit = true
//                                self.singlePayoutCall = true
//                                return
//                            }
//                        }
//                        self.functions.httpsCallable("payoutCall").call(["priceData": priceStr, "idData": idStr, "idType": "email"]) { (result, error) in
//                            if let error = error {
//                                print("ERROR in CALL!")
//                            } else {
//                                print("function completed: success")
//                                //remove data from adminPayout
//                                // add to adminPayoutArchive
//
//                                let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
//                                for (each,pric) in content {
//                                    print("would remove ref \(each)")
//                                    Database.database().reference().child("users").child(each).updateChildValues(["payoutsPast": ["\(timeStamp)": pric]])
//                                    //ref.child(each).removeValue()
//                                }
//                                Database.database().reference().child("adminArchive").child("\(timeStamp)").updateChildValues(tempArchiveDict)
//                            }
//
//                        }
//                    }
//                    if payIdAndFinalPricePhone.count != 0, self.singlePhonePayoutCall {
//                        self.singlePhonePayoutCall = false
//                        var priceString = ""
//                        var idString = ""
//                        for (dictId,dictPrice) in payIdAndFinalPricePhone {
//                            priceString += "\(dictPrice)/"
//                            idString += "\(dictId)/"
//                            if dictPrice >= 40.0 && !self.maxPayoutHit {
//                                let alert = UIAlertController(title: "WARNING", message: "There are 1 or more users with total payments over 40$ USD Please look at database/payoutadmin", preferredStyle: .actionSheet)
//                                let cancel = UIAlertAction(title: "okay", style: .cancel)
//                                alert.addAction(cancel)
//                                self.present(alert, animated: true)
//                                self.maxPayoutHit = true
//                                self.singlePayoutCall = true
//                                return
//                            }
//                        }
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
//                            self.functions.httpsCallable("payoutCall").call(["priceData": priceString, "idData": idString, "idType": "phone"]) { (result, error) in
//                                if let error = error {
//                                    print("ERROR in CALL!")
//                                } else {
//                                    print("function completed: success")
//                                    let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
//                                    for (each,pric) in content {
//                                        print("would remove ref \(each)")
//                                        Database.database().reference().child("users").child(each).updateChildValues(["payoutsPast": ["\(timeStamp)": pric]])
//                                        //ref.child(each).removeValue()
//                                    }
//                                    Database.database().reference().child("adminArchive").child("\(timeStamp)").updateChildValues(tempArchiveDict)
//
//                                }
//
//                            }
//                        }
//                    }
//                }
//            }
//        })
//    }
    
    func calculatePayoutPerItem(price: Double) -> Double {
        if price <= 2.00 {
            return (0.975*price - 0.49).rounded(digits: 2)
        } else if price > 2.00 && price < 5.0 {
            return (0.975*price - 0.51).rounded(digits: 2)
        } else if price >= 5.00 && price < 10.0 {
            return (0.975*price - 0.50 - 0.05*price).rounded(digits: 2)
        } else {
            return (0.975*price - 0.50 - 0.06*price).rounded(digits: 2)
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
extension Double {
    func rounded(digits: Int) -> Double {
        let multiplier = pow(10.0, Double(digits))
        return (self * multiplier).rounded() / multiplier
    }
}

class adminCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var approvedView: UIView!
    
    @IBOutlet weak var approvedLabel: UILabel!
    
    @IBOutlet weak var joinView: UIView!
    
    @IBOutlet weak var joinLabel: UILabel!
    
    @IBOutlet weak var payoutView: UIView!
    
    @IBOutlet weak var payoutLabel: UILabel!
    
    @IBOutlet weak var purchasedView: UIView!
    @IBOutlet weak var purchasedLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 10, y: 10, width: contentView.frame.width - 20, height: 80)
        approvedView.frame = CGRect(x: 10, y: 100, width: 20, height: 20)
        approvedLabel.frame = CGRect(x: 35, y: 100, width: contentView.frame.width - 35, height: 28)
        joinView.frame = CGRect(x: 10, y: 135, width: 20, height: 20)
        joinLabel.frame = CGRect(x: 35, y: 135, width: contentView.frame.width - 35, height: 28)
        payoutView.frame = CGRect(x: 10, y: 170, width: 20, height: 20)
        payoutLabel.frame = CGRect(x: 35, y: 170, width: contentView.frame.width - 35, height: 28)
        purchasedView.frame = CGRect(x: 10, y: 205, width: 20, height: 20)
        purchasedLabel.frame = CGRect(x: 35, y: 205, width: contentView.frame.width - 35, height: 28)
        priceLabel.frame = CGRect(x: 10, y: 240, width: contentView.frame.width - 35, height: 28)
        timeLabel.frame = CGRect(x: 15, y: 275, width: contentView.frame.width - 30, height: 28)
        
    }
    
}
class adminCell2: UITableViewCell {
    
    @IBOutlet weak var verdictButton: UIButton!
    
    @IBOutlet weak var solutionTitleLabel: UILabel!
    
    @IBOutlet weak var price: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        solutionTitleLabel.frame = CGRect(x: 10, y: 10, width: contentView.frame.width - 20, height: 25)
        price.frame = CGRect(x: 10, y: 38, width: contentView.frame.width - 20, height: 50)
        verdictButton.frame = CGRect(x: 15, y: 100, width: contentView.frame.width - 30, height: 35)
    }
    
}
