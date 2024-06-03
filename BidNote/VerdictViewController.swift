//
//  VerdictViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/27/23.
//

import UIKit
import Kingfisher
import Firebase
import FirebaseFunctions

class VerdictViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var textViewTitle: UITextView!
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var tagsTextView: UITextView!
    
    @IBOutlet weak var viewPurchasedButton: UIButton!
    
    @IBOutlet weak var addTagsButton: UIButton!
    
    @IBOutlet weak var userIsBannedLabel: UILabel!
    
    @IBOutlet weak var doneButton: UIButton!
    
    
    var delegate: refreshAdminPage?
    var approve = false
    var reject = false
    var images: [String]?
    var solId: String?
    var titleString: String?
    var descript: String?
    var payId: String?
    var tags: [String]?
    var suid: String?
    var solLink: String?
    var showSolutionLinkOnce = true
    var banReject = false
    var userIsBanned = false
    var addedTags = [String]()
    var clickViewPurchaseOnce = false
    var schoolCodes = [String]()
    var setSchoolCode = false
    lazy var functions = Functions.functions()
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.frame = CGRect(x: 10, y: 10, width: view.frame.width - 10, height: (view.frame.width/2) * 1.6)
        let belowCVY = (view.frame.width/2) * 1.6 + 10
        layoutSubUI(cvy: belowCVY)
        if let _ = self.images {
            collectionView.reloadData()
        }
        if let titleS = self.titleString {
            textViewTitle.text = titleS
        }
        if let desc = self.descript {
            descriptionTextView.text = desc
        }
        if let tags = self.tags {
            setTagsText(tags: tags)
        }
        if let suid = suid {
            self.checkIfBanned(userid: suid)
        }
        self.getSchoolTags()
        
        // Do any additional setup after loading the view.
    }
        
    func setTagsText(tags: [String]) {
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
        self.tagsTextView.text = tagsString
    }
    
    func layoutSubUI(cvy: CGFloat) {
        textViewTitle.frame = CGRect(x: 15, y: cvy + 10, width: view.frame.width - 30, height: 55)
        descriptionTextView.frame = CGRect(x: 15, y: cvy + 70, width: view.frame.width - 30, height: 55)
        tagsTextView.frame = CGRect(x: 15, y: cvy + 110, width: view.frame.width - 30, height: 55)
        viewPurchasedButton.frame = CGRect(x: 15, y: cvy + 160, width: view.frame.width - 30, height: 35)
        addTagsButton.frame =  CGRect(x: 15, y: cvy + 200, width: view.frame.width - 30, height: 35)
        userIsBannedLabel.frame = CGRect(x: 15, y: cvy + 250, width: view.frame.width - 30, height: 30)
        doneButton.frame = CGRect(x: 50, y: view.frame.height - 150, width: view.frame.width - 100, height: 36)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellVerdictCV", for: indexPath) as? verdictCV
        if let url = URL(string: images?[indexPath.row] ?? "") {
            cell?.imageView.kf.setImage(with: url)
        }
        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width / 2, height: 1.5*(view.frame.width/2))
    }
    
    @IBAction func doneAction(_ sender: Any) {
        if let link = self.solLink, showSolutionLinkOnce {
            showSolutionLinkOnce = false
            if let url = URL(string: link) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else if !approve && !reject && !banReject {
            let alert = UIAlertController(title: "Verdict", message: "As an Admin of BidNote, you must give a verdict within the guidelines of BidNote's policies. Please do not, for any reason what so ever, approve solutions that fail our guidelines. THIS INCLUDES IF THE SOLUTION IS NOTICEABLY FALSE. This team appreciates your help being an admin. Thank you.", preferredStyle: .actionSheet)
            let action1 = UIAlertAction(title: "Approve", style: UIAlertAction.Style.default, handler: { alert -> Void in
                self.approve = true
                self.doneButton.setTitle("Approve", for: .normal)
            })
            let action2 = UIAlertAction(title: "Reject", style: UIAlertAction.Style.default, handler: { alert -> Void in
                self.reject = true
                self.doneButton.setTitle("Reject", for: .normal)
            })
            let action3 = UIAlertAction(title: "BAN and Reject", style: UIAlertAction.Style.default, handler: { alert -> Void in
                self.banReject = true
                self.doneButton.setTitle("Ban+Reject", for: .normal)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(action1)
            alert.addAction(action2)
            alert.addAction(action3)
            alert.addAction(cancel)
            self.present(alert, animated: true)
        } else if approve && !reject && !userIsBanned {
            self.disableApproveButtonIfAlreadyApproved()
            self.handleApproval()
        } else if reject && !approve {
            self.handleReject()
        } else if !reject && !approve && banReject {
            self.handleBanAndReject()
        }
    }
    
    

    func checkIfBanned(userid: String) {
        let ref = Database.database().reference().child("banned")
        ref.child(userid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.userIsBannedLabel.text = "BANNED USERID"
                self.userIsBanned = true
            } else {
                self.userIsBannedLabel.text = "User is not banned"
            }
        })
    }
    
    func handleApproval() {
        self.checkIfALreadyVerdicted(completion: { result -> Void in
            if result == "proceed" {
                if let solId = self.solId {
                    let ref = Database.database().reference().child("adminQueue")
                    let finalRef = Database.database().reference().child("solutions")
                    let userRef = Database.database().reference().child("users")
                    ref.child(solId).observeSingleEvent(of: .value, with: {snap in
                        let vals = snap.value as? [String : AnyObject]
                        if let finalSolutionTitle = vals?["solTitle"] as? String, let finalSolutionTags = vals?["solTags"] as? [String: String], let finalBlurredImages = vals?["blurredImages"] as? [String: String], let finalCreatorId = vals?["creatorId"] as? String, let finalImages = vals?["images"] as? [String: AnyObject], let finalPrice = vals?["price"] as? Double, let finalDescript = vals?["solDescription"] as? String, let finalTime = vals?["time"] as? Int {
                            let update = ["solTitle": finalSolutionTitle, "solDescription": finalDescript, "images": finalImages, "blurredImages": finalBlurredImages, "creatorId": finalCreatorId, "price": finalPrice, "time": finalTime, "solTags": finalSolutionTags, "solId": solId, "weight": 25, "searchTitle": finalSolutionTitle.lowercased().replacingOccurrences(of: ",", with: "")] as [String : Any]
                            finalRef.child(solId).updateChildValues(update)
                            self.addSearchResultsKeys(solId: solId, solTitle: finalSolutionTitle, tags: finalSolutionTags.values.map({$0}))
                            if let link = vals?["zoomLink"] as? String {
                                self.updateLinkIfThereIs(solid: solId, linkString: link)
                            }
                            if let unBlurFirst = vals?["unblurPreview"] as? String {
                                finalRef.child(solId).updateChildValues(["unblurPreview": unBlurFirst])
                            }
                            userRef.child(finalCreatorId).child("approvedSolutions").updateChildValues([solId: solId])
                            
                            ref.child(solId).removeValue()
                            let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                            if let key = userRef.child(finalCreatorId).child("inbox").childByAutoId().key {
                                var contentString = "Your material is now live! Thank you for helping other students learn."
                                if finalPrice != 0.0 {
                                    contentString = "Your material is now live! You will now start recieving commissions on sales. BidNote is a small startup out of UCSB, every person you tell about the app helps immensely. Thank You (:"
                                }
                                let inboxUpdate = ["key": key, "type": "approval", "content": contentString, "time": timeStamp, "read": 0] as [String : Any]
                                let finalUpdate = [key: inboxUpdate]
                                userRef.child(finalCreatorId).updateChildValues(["inboxUnseen": 1])
                                userRef.child(finalCreatorId).child("inbox").updateChildValues(finalUpdate)
                                userRef.child(finalCreatorId).child("userKey").observeSingleEvent(of: .value, with: { snapshot in
                                    if let value = snapshot.value as? String {
                                        if finalPrice > 0.0 {
                                            self.sendNotification(sub_id: value, message: "Your material has been approved! You can now earn a commission on each sale. Please shoutout BidNote to your friends!")
                                        } else {
                                            self.sendNotification(sub_id: value, message: "Your material has been approved! People can now find it in the app!")
                                        }
                                    }
                                })
                            }
                            self.dismiss(animated: true)
                            self.delegate?.refreshContent()
                        }
                    })
                }
            } else {
                let alert = UIAlertController(title: "WARNING", message: "IT SEEMS THIS SOLUTION WAS ALREADY verdicted. Please exit this solution and refresh your admin feed(exit and reopen the feed)", preferredStyle: .actionSheet)
                let cancel = UIAlertAction(title: "okay", style: .cancel)
                alert.addAction(cancel)
                self.present(alert, animated: true)
            }
        })
    }
    
    func handleReject() {
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
            if let solId = self.solId, let text = alertReject.textFields?[0].text, let userId = self.suid, let solTitle = self.titleString {
                let ref = Database.database().reference()
                ref.child("adminQueue").child(solId).removeValue()
                let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                if let key = ref.child("users").child(userId).child("inbox").childByAutoId().key {
                    let contentString = "Your material has been Rejected: \(text); Material Title starts with: \(solTitle.prefix(5))"
                    let update = ["key": key, "type": "reject", "content": contentString, "time": timeStamp] as [String : Any]
                    let finalUpdate = [key: update]
                    ref.child("users").child(userId).child("inbox").updateChildValues(finalUpdate)
                    ref.child("users").child(userId).updateChildValues(["inboxUnseen": 1])
                    ref.child("users").child(userId).child("userKey").observeSingleEvent(of: .value, with: { snap in
                        if let value = snap.value as? String {
                            self.sendNotification(sub_id: value, message: "We've sent you a message about material you posted. Check your inbox in the app!")
                        }
                    })
                    self.dismiss(animated: true)
                    self.delegate?.refreshContent()
                } else {
                    print("key failed")
                    self.dismiss(animated: true)
                    self.delegate?.refreshContent()
                }
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertReject.addAction(action1)
        alertReject.addAction(cancel)
        self.present(alertReject, animated: true)
    }
    
    func handleBanAndReject() {
        if let suid_data = self.suid, let solId = self.solId {
            let ref = Database.database().reference()
            if let payId = self.payId {
                ref.child("bannedPayIds").updateChildValues([payId: payId])
            }
            ref.child("banned").updateChildValues([suid_data: suid_data])
            ref.child("adminQueue").child(solId).removeValue()
            self.delegate?.refreshContent()
            self.dismiss(animated: true)
        }
    }
    
    
    
    func addSearchResultsKeys(solId: String, solTitle: String, tags: [String]) {
        let ref = Database.database().reference().child("searchKeys")
        let solRef = Database.database().reference().child("solutions")
        let recentSchoolsRef = Database.database().reference()
        let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
        guard !solTitle.contains(".") && !solTitle.contains("#") && !solTitle.contains("$") && !solTitle.contains("[") && !solTitle.contains("]") else {
            print("contained illegal title character")
            return
        }
        let noSpaces = solTitle.replacingOccurrences(of: ",", with: "").components(separatedBy: CharacterSet.whitespacesAndNewlines)
        for each in noSpaces {
            if !each.contains(" ") && each != "" {
                print("here we are \(each)")
                let result = [solId: solId]
                let updateKey = each.lowercased().trimmingTrailingSpaces.replacingOccurrences(of: " ", with: "-")
                ref.child(updateKey).updateChildValues(result)
            }
        }
        for each in tags {
            guard !each.contains(".") && !each.contains("#") && !each.contains("$") && !each.contains("[") && !each.contains("]") else {
                print("contained illegal tag character")
                return
            }
            let result = [solId: solId]
            let newString = each.trimmingTrailingSpaces.replacingOccurrences(of: " ", with: "-")
            ref.child(newString.lowercased()).updateChildValues(result)
            if !setSchoolCode && self.schoolCodes.contains(newString.lowercased()) {
                solRef.child(solId).updateChildValues(["school": newString.lowercased()])
                let recentSchoolChild = "\(each.lowercased())-recent"
                recentSchoolsRef.child(recentSchoolChild).updateChildValues([solId: timeStamp])
                setSchoolCode = true
            }
        }
        if self.addedTags.count != 0 {
            for each in addedTags {
                if !each.contains(".") && !each.contains("#") && !each.contains("$") && !each.contains("[") && !each.contains("]") && each != "   " && each != "    " && each != "     " && each != " " {
                    let result = [solId: solId]
                    ref.child(each.lowercased()).updateChildValues(result)
                    if !setSchoolCode && self.schoolCodes.contains(each.lowercased()) {
                        solRef.child(solId).updateChildValues(["school": each.lowercased()])
                        let recentSchoolChild = "\(each.lowercased())-recent"
                        recentSchoolsRef.child(recentSchoolChild).updateChildValues([solId: timeStamp])
                        setSchoolCode = true
                    }
                }
            }
        }
    }
    
    func updateLinkIfThereIs(solid: String, linkString: String) {
        let ref = Database.database().reference().child("solutions").child(solid)
        ref.updateChildValues(["zoomLink": linkString])
    }
    
    func getSchoolTags() {
        let ref = Database.database().reference()
        ref.child("schools").observeSingleEvent(of: .value, with: { snapsh in
            if let data = snapsh.value as? [String: String] {
                let schoolCodes = data.keys.map({$0})
                self.schoolCodes = schoolCodes
            }
        })
    }
    
    func checkIfALreadyVerdicted (completion: @escaping (String) -> Void) {
        let ref = Database.database().reference()
        if let solid = self.solId {
            ref.child("adminQueue").child(solid).observeSingleEvent(of: .value, with: {
                snapshot in
                if snapshot.exists() {
                    completion("proceed")
                } else {
                    completion("fail")
                }
            })
        }
    }
    
    func sendNotification (sub_id: String, message: String) {
        self.functions.httpsCallable("oneSignalCall").call(["userKey": sub_id, "notif_message": message]) { (result, error) in
            if let error = error {
                debugPrint("⭕️Notification: ", error)
                print("failed")
            }
        }
    }
    
    @IBAction func addTagsAction(_ sender: Any) {
        let alertChooseTagOrTitle = UIAlertController(title: "Add Tags or Title Keyword", message: "select tags or title key word then add it to this non verdicted material.", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Tags", style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.tagAdd()
        })
        let action2 = UIAlertAction(title: "Title Keyword", style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.titleKeyword()
        })
        let action3 = UIAlertAction(title: "Title Change", style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.titleChange()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertChooseTagOrTitle.addAction(action1)
        alertChooseTagOrTitle.addAction(action2)
        alertChooseTagOrTitle.addAction(action3)
        alertChooseTagOrTitle.addAction(cancel)
        self.present(alertChooseTagOrTitle, animated: true)
    }
    
    func tagAdd() {
        let alertTag = UIAlertController(title: "Add Tags", message: "Type the tag, then click done. It will add it to the tags. PLEASE DO NOT RETYPE A TAG ALREADY ADDED", preferredStyle: .alert)
        alertTag.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Please write here..."
            textField.autocorrectionType = .default
            textField.keyboardType = .twitter
            textField.keyboardAppearance = .dark
            textField.autocapitalizationType = .sentences
            textField.tintColor = .blue
        }
        let attributedString = NSAttributedString(string: "Add Tags", attributes: [
            NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
        ])
        alertTag.setValue(attributedString, forKey: "attributedTitle")
        let action1 = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { alert -> Void in
            if let text = alertTag.textFields?[0].text, text.count > 2, text != "   " {
                let key = text.trimmingTrailingSpaces.replacingOccurrences(of: " ", with: "-")
                self.addedTags.append(key)
                self.tags?.append(text)
                self.setTagsText(tags: self.tags!)
            }
            
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertTag.addAction(action1)
        alertTag.addAction(cancel)
        self.present(alertTag, animated: true)
    }
    func titleChange() {
        let alertTag = UIAlertController(title: "Change Title", message: "Please change the title to something appropriate.", preferredStyle: .alert)
        alertTag.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Please write here..."
            textField.text = self.titleString
            textField.autocorrectionType = .default
            textField.keyboardType = .twitter
            textField.keyboardAppearance = .dark
            textField.autocapitalizationType = .sentences
        }
        let attributedString = NSAttributedString(string: "Change Title", attributes: [
            NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
        ])
        alertTag.setValue(attributedString, forKey: "attributedTitle")
        let action1 = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { alert -> Void in
            if let text = alertTag.textFields?[0].text, text.count > 5, text != "   ", let solid = self.solId {
                let ref = Database.database().reference().child("adminQueue").child(solid)
                ref.updateChildValues(["solTitle": text])
                self.textViewTitle.text = text
                self.titleString = text
            }
            
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertTag.addAction(action1)
        alertTag.addAction(cancel)
        self.present(alertTag, animated: true)
    }
    func titleKeyword() {
        guard let solid = self.solId, let solTitle = self.titleString else { return }
        let alertChooseTitle = UIAlertController(title: "Add title keyword", message: "For homework, quiz, test, midterm, final, etc material posted.", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Homework", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let ref = Database.database().reference().child("adminQueue").child(solid)
            ref.updateChildValues(["solTitle": "Homework Help: " + solTitle])
            self.textViewTitle.text = "Homework Help: " + solTitle
        })
        let action2 = UIAlertAction(title: "Quiz", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let ref = Database.database().reference().child("adminQueue").child(solid)
            ref.updateChildValues(["solTitle": "Quiz Prep: " + solTitle])
            self.textViewTitle.text = "Quiz Prep: " + solTitle
        })
        let action3 = UIAlertAction(title: "Test", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let ref = Database.database().reference().child("adminQueue").child(solid)
            ref.updateChildValues(["solTitle": "Test Prep: " + solTitle])
            self.textViewTitle.text = "Test Prep: " + solTitle
        })
        let action4 = UIAlertAction(title: "Project", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let ref = Database.database().reference().child("adminQueue").child(solid)
            ref.updateChildValues(["solTitle": "Project Help: " + solTitle])
            self.textViewTitle.text = "Project Help: " + solTitle
        })
        let cancel = UIAlertAction(title: "cancel", style: .cancel)
        alertChooseTitle.addAction(action1)
        alertChooseTitle.addAction(action2)
        alertChooseTitle.addAction(action3)
        alertChooseTitle.addAction(action4)
        alertChooseTitle.addAction(cancel)
        self.present(alertChooseTitle, animated: true)
    }
    
    func disableApproveButtonIfAlreadyApproved() {
        if let solId = self.solId {
            let ref = Database.database().reference().child("adminQueue")
            ref.child(solId).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    print("still in queue, can approve/give verdict")
                } else {
                    self.doneButton.isEnabled = false
                    let alert = UIAlertController(title: "WARNING", message: "IT SEEMS THIS MATERIAL WAS ALREADY verdicted. Please exit this material and refresh your admin feed(exit and reopen the feed)", preferredStyle: .actionSheet)
                    let cancel = UIAlertAction(title: "okay", style: .cancel)
                    alert.addAction(cancel)
                    self.present(alert, animated: true)
                    
                }
            })
        }
    }
    
    @IBAction func viewPurchasedAction(_ sender: Any) {
        var urlsAll = [String]()
        if self.clickViewPurchaseOnce == false {
            self.clickViewPurchaseOnce = true
            if let userId = self.suid {
                let ref = Database.database().reference()
                ref.child("users").child(userId).child("purchased").observeSingleEvent(of: .value, with: { snap in
                    if let vals = snap.value as? [String: AnyObject] {
                        let dispatchGroup = DispatchGroup()
                        for (_,each) in vals {
                            dispatchGroup.enter()
                            if let key = each["key"] as? String {
                                ref.child("solutions").child(key).child("images").observeSingleEvent(of: .value, with: { snapshot in
                                    if let imgVals = snapshot.value as? [String: AnyObject] {
                                        for (_,one) in imgVals {
                                            if let url = one["urlPhoto"] as? String {
                                                urlsAll.append(url)
                                            }
                                        }
                                    }
                                    dispatchGroup.leave()
                                })
                            }
                        }
                        dispatchGroup.notify(queue: DispatchQueue.main) {
                            self.expand(images: urlsAll)
                        }
                    } else {
                        self.clickViewPurchaseOnce = false
                        let alert = UIAlertController(title: "No Purchases", message: "User has 0 purchases", preferredStyle: .actionSheet)
                        let cancel = UIAlertAction(title: "okay", style: .cancel)
                        alert.addAction(cancel)
                        self.present(alert, animated: true)
                    }
                })
                
            }
        }
    }
    
    func expand(images: [String]) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "expandVC") as? ExpandViewController {
            vc.images = images
            vc.editMode = false
            self.present(vc, animated: true, completion: nil)
        }
        self.clickViewPurchaseOnce = false
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

class verdictCV: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 5, y: 5, width: contentView.frame.width - 10, height: contentView.frame.height - 10)
    }
    
}
