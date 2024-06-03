//
//  SolutionViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 8/30/23.
//

import UIKit
import Foundation
import FirebaseFunctions
import Firebase
import FirebaseAuth
import OneSignalFramework
import Kingfisher
import PDFKit
import StoreKit

protocol payButtonClicked {
    func clickedPay()
}
protocol zoomClicked {
    func openZoom()
}
protocol switchedSegment {
    func switched(index: Int)
}
protocol expand {
    func expand()
}
protocol imagesToPdf {
    func openPdfImages()
}

class SolutionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, switchedSegment, payButtonClicked, expand, UITextFieldDelegate, changeImages, imagesToPdf, zoomClicked, SKPaymentTransactionObserver, SKProductsRequestDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    enum productService: String, CaseIterable {
        case tier1 = "tier1tutoring"
        case tier2 = "tier2tutoring"
        case tier3 = "tier3tutoring"
        case tier4 = "tier4tutoring"
        case tier5 = "tier5tutoring"
        case tier6 = "tier6tutoring"
        case tier7 = "tier7tutoring"
        case tier8 = "tier8tutoring"
        case tier10 = "tier10tutoring"
        case tier13 = "tier13tutoring"
        case tier15 = "tier15tutoring"
        case tier20 = "tier20tutoring"
    }
    var prices = [0.99, 1.99, 2.99, 3.99, 4.99, 5.99, 6.99, 7.99, 9.99, 12.99, 14.99, 19.99]
    var viewShowPayouts = UIView()
    var solutionTitle: String?
    var solutionDes: String?
    var solutionPrice: Double?
    var solutionTags: [String]?
    var solutionImages: [String]?
    var solutionId: String?
    var creatorId: String?
    var link: String?
    var userOwns = false
    var timePosted: Int?
    var currentIndex = 0
    var likes = [String]()
    var dislikes = [String]()
    var reviews = [review]()
    var showApplePay = false
    var priceString = ""
    var allowApplePay = false
    var blurredImages: [String]?
    var addReviewButton = UIButton()
    var didLikeSolution = false
    var didDislikeSolution = false
    var schoolCode: String?
    var userRating: Double?
    var activityForCardPayment = UIActivityIndicatorView()
    let textviewA = UITextView()
    let exitButtonComment = UIButton()
    let divideViewComment = UIView()
    var commentOpen = false
    let commentingView = UIView()
    var oncep = false
    var sendLikeOnce = true
    var callLikeNotifOnce = false
    var timer : Timer?
    var counter = 0
    var updateSchoolViewsOnce = false
    var isAuthor = false
    var currentString = ""
    var priceTextEditing = false
    var dontShowAuthor: Bool?
    var priceOf: Double?
    var imagesAlreadyInAdminQueue = false
    var showPrompt = false
    var zoomLink: String?
    var previewMode = false
    var userBanned = false
    var videoAlreadyInAdminQueue = false
    var oneAddActivity = false
    var pendingPayOnce = false
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    var loading = UIActivityIndicatorView()
    var applePayButton = UIButton()
    lazy var functions = Functions.functions()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getPrompt()
        loading.frame = view.bounds
        loading.color = .lightGray
        loading.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        loading.startAnimating()
        view.addSubview(loading)
        activityForCardPayment.frame = view.bounds
        activityForCardPayment.color = .systemBlue
        view.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.estimatedRowHeight = 68.0
        tableView.rowHeight = UITableView.automaticDimension
        //0.24, G:0.24, B:0.26, A:0.29
        tableView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        if let solId = self.solutionId {
            self.checkIfPurchases(solId: solId, completion: { (result1) -> Void in
                if result1 {
                    self.userOwns = true
                    self.getSolutionDetails(solId: solId)
                    
                } else {
                    self.userOwns = false
                    self.getSolutionDetails(solId: solId)
                }
            })
            self.checkIfInAdminQueue()
            self.updateSolutionViews()
        }
        let ref = Database.database().reference().child("banned")
        if let uid = Auth.auth().currentUser?.uid {
            ref.child(uid).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    self.userBanned = true
                }
            })
        }
        addReviewButton.frame = CGRect(x: 50, y: view.frame.height - 150, width: view.frame.width - 100, height: 40)
        addReviewButton.backgroundColor = .systemBlue
        addReviewButton.setTitleColor(.white, for: .normal)
        addReviewButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        addReviewButton.setTitle("Add Review", for: .normal)
        addReviewButton.layer.cornerRadius = 8.0
        addReviewButton.addTarget(self, action: #selector(addReview), for: .touchUpInside)
        timer = Timer.scheduledTimer(timeInterval:1, target:self, selector:#selector(prozessTimer), userInfo: nil, repeats: true)
    }
    func checkIfPurchases(solId: String, completion: @escaping (Bool) -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users")
            ref.child(uid).child("purchased").child(solId).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    completion(true)
                } else {
                    completion(false)
                }
            })
        } else {
            completion(false)
        }
    }
    
    
    func getSolutionDetails(solId: String) {
        let ref = Database.database().reference().child("solutions")
        ref.child(solId).observeSingleEvent(of: .value, with: { snap in
            let vals = snap.value as? [String : AnyObject]
            if let finalSolutionTitle = vals?["solTitle"] as? String, let finalSolutionTags = vals?["solTags"] as? [String: String], let finalBlurredImages = vals?["blurredImages"] as? [String: String], let finalCreatorId = vals?["creatorId"] as? String, let finalImages = vals?["images"] as? [String: [String: AnyObject]], let finalPrice = vals?["price"] as? Double, let finalDescript = vals?["solDescription"] as? String, let finalTime = vals?["time"] as? Int, let myUid = Auth.auth().currentUser?.uid {
                self.solutionTitle = finalSolutionTitle
                self.solutionDes = finalDescript
                self.solutionPrice = finalPrice
                self.blurredImages = finalBlurredImages.values.map({$0})
                self.solutionTags = finalSolutionTags.values.map({$0})
                if finalPrice == 0.0 {
                    self.userOwns = true
                }
                var unsortedImgs = [imageObj]()
                for (_,photo) in finalImages {
                    if let urlPhoto = photo["urlPhoto"] as? String {
                        if !unsortedImgs.contains( where: { $0.url == urlPhoto } ) {
                            print("added a url \(urlPhoto)")
                            var objImg = imageObj()
                            objImg.url = urlPhoto
                            //urls.append(urlPhoto)
                            if let order = photo["order"] as? Int {
                                objImg.order = order
                            } else {
                                objImg.order = 0
                            }
                            if !unsortedImgs.contains( where: { $0.url == urlPhoto } ) {
                                unsortedImgs.append(objImg)
                            }
                        }
                    }
                }
                let urlsSorted = unsortedImgs.sorted { $0.order < $1.order }
                var urls = [String]()
                for each in urlsSorted {
                    urls.append(each.url)
                }
                if myUid == finalCreatorId {
                   self.isAuthor = true
                    self.userOwns = true
                }
                if let unblurFirst = vals?["unblurPreview"] as? String {
                    if self.blurredImages?.count != 0 && urls.count != 0 {
                        self.blurredImages?[0] = urls[0]
                        self.previewMode = true
                    }
                }
                if let reviewDict = vals?["reviews"] as? [String: [String: AnyObject]] {
                    for (_,rev) in reviewDict {
                        if let message = rev["message"] as? String, let time = rev["timeStamp"] as? Int, let key = rev["key"] as? String, let creator = rev["sender"] as? String {
                            let review1 = review()
                            review1.id = key
                            review1.time = time
                            review1.userId = creator
                            review1.reviewString = message
                            if !self.reviews.contains(where: { $0.id == key}) {
                                self.reviews.append(review1)
                            }
                        }
                    }
                }
                if let likes = vals?["likes"] as? [String: String] {
                    self.likes = likes.values.map({$0})
                    if likes.values.map({$0}).contains(myUid) {
                        self.didLikeSolution = true
                    }
                }
                if let dislikes = vals?["dislikes"] as? [String: String] {
                    self.dislikes = dislikes.values.map({$0})
                    if dislikes.values.map({$0}).contains(myUid) {
                        self.didDislikeSolution = true
                    }
                }
                if let school =  vals?["school"] as? String {
                    self.schoolCode = school
                }
                if let zoomLink = vals?["zoomLink"] as? String {
                    self.zoomLink = zoomLink
                }
                self.solutionImages = urls
                self.creatorId = finalCreatorId
                self.timePosted = finalTime
                
            }
            if let price = self.solutionPrice {
                if price.decimalCount() == 1 {
                    self.priceString = "\(price)0"
                } else if price.decimalCount() == 0 {
                    self.priceString = "\(price)0"
                } else if price.decimalCount() == 2 {
                    self.priceString = "\(price)"
                }
            }
            self.tableView.reloadData()
            print("priceString \(self.priceString)")
            self.loading.stopAnimating()
            self.loading.removeFromSuperview()
            self.getCreatorIdsRating()
        })
        
    }
    
    func getCreatorIdsRating() {
        let ref = Database.database().reference().child("users")
        if let creatorID = creatorId {
            ref.child(creatorID).child("likesOnSolutions").observeSingleEvent(of: .value, with: {
                snapshot in
                var likes = 0
                var dislikes = 0
                if let vals = snapshot.value as? [String : [String: String]] {
                    for(_,each) in vals {
                        for (_,_) in each {
                            likes+=1
                        }
                    }
                }
                ref.child(creatorID).child("dislikesOnSolutions").observeSingleEvent(of: .value, with: {
                    snap in
                    if let vals2 = snap.value as? [String : [String: String]] {
                        for(_,each2) in vals2 {
                            for (_,_) in each2 {
                                dislikes+=1
                            }
                        }
                    }
                    if dislikes == 0 {
                        self.userRating = 5
                    } else {
                        if dislikes > likes {
                            self.userRating = 0
                        } else if likes / dislikes == 1 {
                            self.userRating = 2.5
                        } else {
                            let total:Float = Float(dislikes + likes)
                            let likesi:Float = Float(likes)
                            //CGRect(x: shawdowView1.frame.width - 150, y: 0, width: 140, height: 8)
                            let ratio:Float = Float(likesi / total)
                            if ratio * 100 <= 20 {
                                self.userRating = 1
                            } else if (ratio * 100) > 20 && (ratio * 100) <= 40 {
                                self.userRating = 2
                            } else if (ratio * 100) > 40 && (ratio * 100) <= 60 {
                                self.userRating = 3
                            } else if (ratio * 100) > 60 && (ratio * 100) <= 80 {
                                self.userRating = 4
                            } else if (ratio * 100) > 80 && (ratio * 100) <= 90 {
                                self.userRating = 4.5
                            } else {
                                self.userRating = 5
                            }
                        }
                    }
                    self.tableView.reloadRows(at: [IndexPath(row: 6, section: 0)], with: .automatic)
                })
                
            })
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentIndex == 1 {
            if reviews.count == 0 {
                return 2
            }
            return reviews.count + 1
        }
        if self.dontShowAuthor != nil {
            return 7
        }
        return 8
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let images = self.solutionImages, let titleS = self.solutionTitle, let solDes = self.solutionDes, let tags = self.solutionTags, let price = self.solutionPrice, let blurredImgs = self.blurredImages, currentIndex == 0 {
            if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell1", for: indexPath) as? tableViewCell1Solution
                cell?.labelTitle.text = titleS
                return cell ?? UITableViewCell()
            } else if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell9", for: indexPath) as? tableViewCell9Solution
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
                return cell ?? UITableViewCell()
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell2", for: indexPath) as? tableViewCell2Solution
                cell?.images = images
                cell?.showPrompt = self.promptCalc()
                cell?.delegate2 = self
                cell?.blurred = blurredImgs
                cell?.delegate = self
                if self.userOwns {
                    cell?.blur = false
                    if let zoomLink = self.zoomLink {
                        cell?.zoomLink = zoomLink
                        cell?.delegate3 = self
                    }
                    cell?.collectionView.reloadData()
                } else {
                    cell?.zoomLink = nil
                    cell?.blur = true
                }
                return cell ?? UITableViewCell()
            } else if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell5", for: indexPath) as? tableViewCell5Solution
                cell?.delegate = self
                return cell ?? UITableViewCell()
            } else if indexPath.row == 4 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell3", for: indexPath) as? tableViewCell3Solution
                cell?.descriptLabel.text = solDes
                return cell ?? UITableViewCell()
            } else if indexPath.row == 5 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell4", for: indexPath) as? tableViewCell4Solution
                cell?.price.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
                cell?.delegate = self
                guard !isAuthor else {
                    cell?.price.setTitle("Edit", for: .normal)
                    return cell ?? UITableViewCell()
                }
                guard userOwns == false else {
                    cell?.price.setTitle("Like/Dislike", for: .normal)
                    cell?.price.backgroundColor = UIColor(red: 0, green: 0.4275, blue: 0.0118, alpha: 1.0)
                    return cell ?? UITableViewCell()
                }
                cell?.price.backgroundColor = .systemBlue
                if price.decimalCount() == 1 {
                    cell?.price.setTitle("Access Material/Tutoring:  $\(price)0", for: .normal)
                } else if price.decimalCount() == 0 {
                    cell?.price.setTitle("Access Material/Tutoring:  $\(price)0", for: .normal)
                } else if price.decimalCount() == 2 {
                    cell?.price.setTitle("Access Material/Tutoring:  $\(price)", for: .normal)
                }
                return cell ?? UITableViewCell()
            } else if indexPath.row == 6 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell8", for: indexPath) as? tableViewCell8Solution
                cell?.likesLabel.text = "\(likes.count)"
                cell?.dislikesLabel.text = "\(dislikes.count)"
                if self.didLikeSolution {
                    cell?.likesIcon.image = UIImage(systemName: "heart.fill")
                    cell?.likesIcon.tintColor = .systemBlue
                    cell?.dislikesIcon.image = UIImage(systemName: "heart.slash")
                    cell?.dislikesIcon.tintColor = .lightGray
                } else if self.didDislikeSolution {
                    cell?.dislikesIcon.image = UIImage(systemName: "heart.slash.fill")
                    cell?.dislikesIcon.tintColor = .systemBlue
                    cell?.likesIcon.image = UIImage(systemName: "heart")
                    cell?.likesIcon.tintColor = .lightGray
                }
                if let posterRating = self.userRating {
                    if posterRating == 4.5 {
                        cell?.averageRatingUserLabel.text = "The author of this material has an average rating of 4.5/5"
                    } else {
                        cell?.averageRatingUserLabel.text = "The author of this material has an average rating of \(Int(posterRating))/5"
                    }
                    
                }
                return cell ?? UITableViewCell()
            } else if indexPath.row == 7 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell10", for: indexPath) as? tableViewCell10Solution
                cell?.moreByAuthorButton.addTarget(self, action: #selector(self.gotToAuthorSolutions), for: .touchUpInside)
                cell?.reportButton.addTarget(self, action: #selector(self.goReport), for: .touchUpInside)
                cell?.payHelpButton.addTarget(self, action: #selector(self.payHelp), for: .touchUpInside)
                return cell ?? UITableViewCell()
            }
        } else if currentIndex == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell5", for: indexPath) as? tableViewCell5Solution
                cell?.delegate = self
                return cell ?? UITableViewCell()
            } else if indexPath.row >= 1 && self.reviews.count != 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell6", for: indexPath) as? tableViewCell6Solution
                cell?.reviewLabel.text = self.reviews[indexPath.row-1].reviewString
                if let time = reviews[indexPath.row-1].time {
                    let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                    let timer = timeStamp - time
                    if timer <= 59 {
                        cell?.timeLabel.text = "\(timer)s ago"
                    }
                    if timer > 59 && timer < 3600 {
                        let minuters = timer / 60
                        cell?.timeLabel.text = "\(minuters) mins ago"
                        if minuters == 1 {
                            cell?.timeLabel.text = "\(minuters) min ago"
                        }
                    }
                    if timer > 59 && timer >= 3600 && timer < 86400 {
                        let hours = timer / 3600
                        if hours == 1 {
                            cell?.timeLabel.text = "\(hours) hr ago"
                        } else {
                            cell?.timeLabel.text = "\(hours) hrs ago"
                        }
                    }
                    if timer > 86400 {
                        let days = timer / 86400
                        cell?.timeLabel.text = "\(days)days ago"
                        if days == 1 {
                            cell?.timeLabel.text = "\(days)day ago"
                        }
                    }
                }
                return cell ?? UITableViewCell()
            } else if indexPath.row == 1 && self.reviews.count == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewSolutionCell7", for: indexPath) as? tableViewCell7Solution
                return cell ?? UITableViewCell()
            }
        }
        return UITableViewCell()
    }
    func switched(index: Int) {
        currentIndex = index
        tableView.reloadData()
        if currentIndex == 1 && userOwns {
            view.addSubview(addReviewButton)
        } else {
            addReviewButton.removeFromSuperview()
        }
    }
    
    func promptCalc() -> Int {
        if !self.userOwns && self.priceOf != 0.0 && !self.previewMode && self.showPrompt {
            return 1
        } else if !self.userOwns && self.priceOf != 0.0 && !self.previewMode {
            return 2
        }
        return 0
    }
    
    @objc func gotToAuthorSolutions() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "selectedCatVC") as? SelectedCatViewController, let userAuthor = self.creatorId {
            vc.userId = userAuthor
            vc.dontShowAuthorsInNextSolutionVC = true
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func payHelp() {
        if let url = URL(string: "https://support.apple.com/en-us/HT201266") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func goReport() {
        guard let uid = Auth.auth().currentUser?.uid, let solid = self.solutionId else { return }
        let alertSecond = UIAlertController(title: "Report This Material", message: "Please tell us what you'd like to report. This can include Copyright, Plagarism, Fraud, Incorrect Lessons, etc..", preferredStyle: .alert)
        alertSecond.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Please type here..."
            textField.autocorrectionType = .default
            textField.autocapitalizationType = .sentences
        }
        let saveAct = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
            if let newPrice = alertSecond.textFields?[0].text, newPrice.count >= 4 {
                let ref = Database.database().reference().child("reports")
                ref.child(uid).updateChildValues([solid: newPrice])
                let alert = UIAlertController(title: "Success", message: "This material has been reported. You may be messaged about future status of this material.", preferredStyle: .alert)
                let canc = UIAlertAction(title: "okay", style: .cancel)
                alert.addAction(canc)
                self.present(alert, animated: true)
                return
            } else {
                let alert = UIAlertController(title: "Error, please give a report description.", message: "Must be at least 4 characters.", preferredStyle: .alert)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if currentIndex == 0 {
            if indexPath.row == 2 {
                return UITableView.automaticDimension
            } else if indexPath.row == 1 {
                return view.frame.width / 1.1
            } else if indexPath.row == 3 || indexPath.row == 4 {
                return UITableView.automaticDimension
            } else if indexPath.row == 6 {
                return 100
            } else if indexPath.row == 7 {
                if UIScreen.main.nativeBounds.height > 2500 {
                    return 240
                }
                return 220
            }
        } else if currentIndex == 1 && self.reviews.count != 0 {
            if indexPath.row == 0 {
                return 60
            }
            return UITableView.automaticDimension
        } else if currentIndex == 1 && self.reviews.count == 0 {
            return 60
        }
        return 50
    }
    
    func clickedPay() {
        if self.userOwns {
            if self.isAuthor {
                editSolution()
            } else {
                if let uid = Auth.auth().currentUser?.uid {
                    let ref = Database.database().reference().child("banned")
                    ref.child(uid).observeSingleEvent(of: .value, with: { snapshot in
                        if snapshot.exists() {
                            //user is banned, end
                        } else {
                            self.showLikeDislike()
                        }
                    })
                    
                }
            }
        } else {
            if SKPaymentQueue.canMakePayments() {
                if self.solutionPrice == 0.99 {
                    let set : Set<String> = [productService.tier1.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 1.99 {
                    let set : Set<String> = [productService.tier2.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 2.99 {
                    let set : Set<String> = [productService.tier3.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 3.99 {
                    let set : Set<String> = [productService.tier4.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 4.99 {
                    let set : Set<String> = [productService.tier5.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 5.99 {
                    let set : Set<String> = [productService.tier6.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 6.99 {
                    let set : Set<String> = [productService.tier7.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 7.99 {
                    let set : Set<String> = [productService.tier8.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 9.99 {
                    let set : Set<String> = [productService.tier10.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 12.99 {
                    let set : Set<String> = [productService.tier13.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 14.99 {
                    let set : Set<String> = [productService.tier15.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else if self.solutionPrice == 19.99 {
                    let set : Set<String> = [productService.tier20.rawValue]
                    let productRequest = SKProductsRequest(productIdentifiers: set)
                    productRequest.delegate = self
                    productRequest.start()
                } else {
                    let alert = UIAlertController(title: "Error", message: "There is something wrong on our end. Please check back in a little while.", preferredStyle: .alert)
                    let okay = UIAlertAction(title: "Okay", style: .cancel)
                    alert.addAction(okay)
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                self.addPaymentActivityView()
                print("purchasing")
            case .purchased:
                print("purchased")
                SKPaymentQueue.default().finishTransaction(transaction)
                self.handleSuccess(id: transaction.transactionIdentifier ?? "778877")
                self.removePaymentActivityView()
            case .failed:
                print("failed")
                SKPaymentQueue.default().finishTransaction(transaction)
                self.removePaymentActivityView()
                self.handleFailure()
            case .restored:
                print("restored")
            case .deferred:
                print("pending")
                self.handlePending()
            default:
                print("default hit")
                break
            }
        }
    }
    
    func handleSuccess(id: String) {
        self.userOwns = true
        self.showApplePay = false
        self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0), ], with: .automatic)
        self.tableView.reloadData()
        self.handleUserPurchased(id: id)
        self.activityForCardPayment.stopAnimating()
        self.activityForCardPayment.removeFromSuperview()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updatePayOutCall()
            self.updateCreatorInbox(type: "purchase")
            let ref = Database.database().reference()
            if let uid = Auth.auth().currentUser?.uid {
                ref.child("users").child(uid).child("loginPin").observeSingleEvent(of: .value, with: { snap in
                    if !snap.exists() {
                        self.askForSecretPin(uid: uid)
                    }
                })
            }
        }
    }
    
    func handlePending() {
        if let solid = self.solutionId, let uid = Auth.auth().currentUser?.uid, self.pendingPayOnce == false {
            self.pendingPayOnce = true
            let ref = Database.database().reference()
            ref.child("pendingPays").updateChildValues([solid: uid])
        }
    }
    
    func handleFailure() {
        print("FAILURE IN DID AUTHORIZE")
        self.userOwns = false
        self.activityForCardPayment.stopAnimating()
        self.activityForCardPayment.removeFromSuperview()
        let alert = UIAlertController(title: "Card Pay Failed", message: "It looks like this transaction could not be completed. Please check payment card/details and try again.", preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .cancel)
        alert.addAction(okay)
        self.present(alert, animated: true)
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if let oProduct = response.products.first {
            print("successfully pulled product")
            self.purchase(aproduct: oProduct)
        } else {
            print("product not available")
        }
    }
    
    func purchase(aproduct: SKProduct) {
        let payement = SKPayment(product: aproduct)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payement)
    }
    
    func addPaymentActivityView() {
        if self.oneAddActivity == false {
            self.oneAddActivity = true
            self.view.addSubview(activityForCardPayment)
            self.activityForCardPayment.stopAnimating()
        }
    }
    func removePaymentActivityView() {
        self.oneAddActivity = false
        self.activityForCardPayment.stopAnimating()
        self.activityForCardPayment.removeFromSuperview()
    }
    
    
    func askForSecretPin(uid: String) {
        let alertSecond = UIAlertController(title: "Make a Pin", message: "What happens if you accidentally delete the app or get a new phone? Use this Pin to get your purchased solutions back.", preferredStyle: .alert)
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
    
    
    let screenWidth = UIScreen.main.bounds.width - 10
    let screenHeight = UIScreen.main.bounds.height / 2
    var selectedRow = 0
    func editSolution() {
        guard let userId = Auth.auth().currentUser?.uid, userId == creatorId, let solTitle = self.solutionTitle, let solid = self.solutionId, let solDes = self.solutionDes, let solPrice = self.solutionPrice, self.userBanned == false else {
            return
        }
        var alert = UIAlertController(title: "Edit your material", message: "Please select what you would like to edit: ", preferredStyle: .actionSheet)
        if UIDevice().userInterfaceIdiom == .pad {
            alert = UIAlertController(title: "Edit your material", message: "Please select what you would like to edit: ", preferredStyle: .alert)
        }
        let titleEdit = UIAlertAction(title: "Title", style: .default, handler: { alert -> Void in
            let alertSecond = UIAlertController(title: "Edit Title", message: "Please edit your title and click save. Please note, this title will be quality checked by administrators upon saving.", preferredStyle: .alert)
            alertSecond.addTextField { (textField : UITextField!) -> Void in
                textField.text = solTitle
                textField.autocorrectionType = .default
                textField.keyboardType = .default
                textField.autocapitalizationType = .words
            }
            let saveAct = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
                if let newTitle = alertSecond.textFields?[0].text, newTitle.count > 5 {
                    guard !newTitle.contains("  ") && !newTitle.contains("shit") && !newTitle.contains("fuck") && !newTitle.contains("fuq") && !newTitle.contains("f u c") && !newTitle.contains("f u q") &&  !newTitle.contains("ass") && !newTitle.contains("bitch") && !newTitle.contains("dick") && !newTitle.contains("s u c k") && !newTitle.contains("s u k") && !newTitle.contains("sex") && !newTitle.contains("fag") && !newTitle.contains("jew") && !newTitle.contains(" hates ") && !newTitle.contains("nigg") && newTitle.count < 120 else {
                        print("failed here")
                        return
                    }
                    let ref = Database.database().reference()
                    ref.child("mutedUsers").child(userId).observeSingleEvent(of: .value, with: { snap in
                        if !snap.exists() {
                            ref.child("solutions").child(solid).updateChildValues(["solTitle": newTitle])
                            ref.child("solutionUpdates").child(solid).updateChildValues(["solTitle": newTitle])
                            self.solutionTitle = newTitle
                            ref.child("solutions").child(solid).updateChildValues(["searchTitle": newTitle.lowercased()])
                            self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                        }
                    })
                }
            })
            let cancelTitleEdit = UIAlertAction(title: "Cancel", style: .cancel)
            alertSecond.addAction(saveAct)
            alertSecond.addAction(cancelTitleEdit)
            self.present(alertSecond, animated: true)
        })
        let descriptEdit = UIAlertAction(title: "Description", style: .default, handler: { alert -> Void in
            let alertSecond = UIAlertController(title: "Edit Description", message: "Please edit your description and click save. Please note, this description will be quality checked by administrators upon saving.", preferredStyle: .alert)
            alertSecond.addTextField { (textField : UITextField!) -> Void in
                textField.text = solDes
                textField.autocorrectionType = .default
                textField.keyboardType = .default
                textField.autocapitalizationType = .sentences
            }
            let saveAct = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
                if let newDescript = alertSecond.textFields?[0].text, newDescript.count > 5 {
                    guard !newDescript.contains("   ") && !newDescript.contains("shit") && !newDescript.contains("fuck") && !newDescript.contains("fuq") && !newDescript.contains("f u c") && !newDescript.contains("f u q") &&  !newDescript.contains("ass") && !newDescript.contains("bitch") && !newDescript.contains("dick") && !newDescript.contains("s u c k") && !newDescript.contains("s u k") && !newDescript.contains("sex") && !newDescript.contains("fag") && !newDescript.contains("jew") && !newDescript.contains(" hates ") && !newDescript.contains("nigg") && newDescript.count < 1000 else {
                        print("failed here")
                        let alert = UIAlertController(title: "Error no double spaces or profanity in description. Max characters: 400", message: "Please retry.", preferredStyle: .alert)
                        let canc = UIAlertAction(title: "okay", style: .cancel)
                        alert.addAction(canc)
                        self.present(alert, animated: true)
                        return
                    }
                    let ref = Database.database().reference()
                    ref.child("solutions").child(solid).updateChildValues(["solDescription": newDescript])
                    ref.child("solutionUpdates").child(solid).updateChildValues(["solDescription": newDescript])
                    self.solutionDes = newDescript
                    self.tableView.reloadRows(at: [IndexPath(row: 4, section: 0)], with: .automatic)
                }
            })
            let cancelTitleEdit = UIAlertAction(title: "Cancel", style: .cancel)
            alertSecond.addAction(saveAct)
            alertSecond.addAction(cancelTitleEdit)
            self.present(alertSecond, animated: true)
        })
        let videoEdit = UIAlertAction(title: "Video URL", style: .default, handler: { alert -> Void in
            guard self.videoAlreadyInAdminQueue == false else {
                let alert = UIAlertController(title: "Error, you already edited the material video or images recently.", message: "Please let the images or url finish processing before editing again (15-30mins).", preferredStyle: .alert)
                let canc = UIAlertAction(title: "okay", style: .cancel)
                alert.addAction(canc)
                self.present(alert, animated: true)
                return
            }
            let alertSecond = UIAlertController(title: "Edit Video Url", message: "We are in the process of adding multiple video link options. Please paste the url of the video.", preferredStyle: .alert)
            alertSecond.addTextField { (textField : UITextField!) -> Void in
                if let currentUrl = self.zoomLink {
                    textField.text = currentUrl
                } else {
                    textField.placeholder = "Paste Video Url Here..."
                }
                textField.autocorrectionType = .no
                textField.keyboardType = .URL
                textField.autocapitalizationType = .none
            }
            let saveAct = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
                if let newTitle = alertSecond.textFields?[0].text, newTitle.count > 5, newTitle.contains("."), let myUid = Auth.auth().currentUser?.uid {
                    let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                    let ref = Database.database().reference().child("adminQueue")
                    let update = ["creatorId": myUid, "solId": solid, "adminUpdateVideo": "videoUpdate", "time": timeStamp, "videoUrl": newTitle.lowercased()] as [String : Any]
                    ref.child(solid).updateChildValues(update)
                    self.imagesAlreadyInAdminQueue = true
                    self.videoAlreadyInAdminQueue = true
                    self.zoomLink = newTitle
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
                    let alert = UIAlertController(title: "Success!", message: "Video URL successfully updated! Please wait 30 mins before other users can see this.", preferredStyle: .alert)
                    let canc = UIAlertAction(title: "okay", style: .cancel)
                    alert.addAction(canc)
                    self.present(alert, animated: true)
                }
            })
            let cancelTitleEdit = UIAlertAction(title: "Cancel", style: .cancel)
            alertSecond.addAction(saveAct)
            alertSecond.addAction(cancelTitleEdit)
            self.present(alertSecond, animated: true)
        })
        let priceEdit = UIAlertAction(title: "Price", style: .default, handler: { alert -> Void in
            guard UIDevice().userInterfaceIdiom != .pad else {
                self.ipadPrice()
                return
            }
            let vc = UIViewController()
            vc.preferredContentSize = CGSize(width: self.screenWidth, height: self.screenHeight)
            let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.screenWidth, height:self.screenHeight))
            pickerView.dataSource = self
            pickerView.delegate = self
            
            pickerView.selectRow(self.selectedRow, inComponent: 0, animated: false)
            //pickerView.selectRow(selectedRowTextColor, inComponent: 1, animated: false)
            
            vc.view.addSubview(pickerView)
            pickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
            pickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
            
            var alert = UIAlertController(title: "Select Price", message: "", preferredStyle: .actionSheet)
            if UIDevice().userInterfaceIdiom == .pad {
                alert = UIAlertController(title: "Select Price", message: "", preferredStyle: .alert)
            }
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
                let ref = Database.database().reference()
                ref.child("solutions").child(solid).updateChildValues(["price": selected])
                ref.child("solutionUpdates").child(solid).updateChildValues(["price": selected])
                self.solutionPrice = selected
                self.priceString = "$\(selected)"
                self.notifyPriceUpdate()
                return
            }))
            self.present(alert, animated: true, completion: nil)
        })
        let imageEdit = UIAlertAction(title: "Images", style: .default, handler: { alert -> Void in
            guard self.imagesAlreadyInAdminQueue == false else {
                let alert = UIAlertController(title: "Error, you already edited the material images.", message: "Please let the images finish processing before editing again (15-30mins).", preferredStyle: .alert)
                let canc = UIAlertAction(title: "okay", style: .cancel)
                alert.addAction(canc)
                self.present(alert, animated: true)
                return
            }
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "expandVC") as? ExpandViewController {
                vc.editMode = true
                vc.solid = solid
                vc.delegate = self
                vc.images = self.solutionImages
                self.present(vc, animated: true, completion: nil)
            }
        })
        let cancelEditAlert = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(titleEdit)
        alert.addAction(cancelEditAlert)
        alert.addAction(descriptEdit)
        if self.solutionPrice != 0.0 {
            alert.addAction(priceEdit)
        }
        alert.addAction(videoEdit)
        alert.addAction(imageEdit)
        alert.preferredAction = cancelEditAlert
        self.present(alert, animated: true)
    
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
        if let solid = self.solutionId {
            self.selectedRow = pickerView.selectedRow(inComponent: 0)
            //self.selectedRowTextColor = pickerView.selectedRow(inComponent: 1)
            let selected = self.prices[self.selectedRow]
            print(selected)
            let ref = Database.database().reference()
            ref.child("solutions").child(solid).updateChildValues(["price": selected])
            ref.child("solutionUpdates").child(solid).updateChildValues(["price": selected])
            self.solutionPrice = selected
            self.priceString = "$\(selected)"
            self.notifyPriceUpdate()
            self.priceView.removeFromSuperview()
        }
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
    
    func notifyPriceUpdate() {
        let alert = UIAlertController(title: "Price Updated!", message: "New Material Price: \(self.priceString) Note: it may take some time before you see this across the app.", preferredStyle: .alert)
        let canc = UIAlertAction(title: "okay", style: .cancel)
        alert.addAction(canc)
        self.present(alert, animated: true)
    }

    func getPrompt() {
        let ref = Database.database().reference()
        ref.child("prompt").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                self.showPrompt = true
            } else {
                
            }
        })
    }
    
    func showLikeDislike() {
        var alert = UIAlertController(title: "How was this material?", message: "Did you like this material? If not, please tell us why.", preferredStyle: .actionSheet)
        if UIDevice().userInterfaceIdiom == .pad {
            alert = UIAlertController(title: "How was this material?", message: "Did you like this material? If not, please tell us why.", preferredStyle: .alert)
        }
        let action1 = UIAlertAction(title: "Like", style: .default, handler: { alert -> Void in
            if let uid = Auth.auth().currentUser?.uid, let solutionId = self.solutionId {
                self.likes.removeAll(where: { $0 == uid })
                self.likes.append(uid)
                self.dislikes.removeAll(where: { $0 == uid })
                Database.database().reference().child("solutions").child(solutionId).child("likes").child(uid).removeValue()
                Database.database().reference().child("solutions").child(solutionId).child("dislikes").child(uid).removeValue()
                Database.database().reference().child("solutions").child(solutionId).child("likes").updateChildValues([uid: uid])
                if let creatorId = self.creatorId {
                    Database.database().reference().child("users").child(creatorId).child("dislikesOnSolutions").child(solutionId).child(uid).removeValue()
                    Database.database().reference().child("users").child(creatorId).child("likesOnSolutions").child(solutionId).updateChildValues([uid: uid])
                }
                self.didLikeSolution = true
                self.didDislikeSolution = false
                self.tableView.reloadRows(at: [IndexPath(row: 6, section: 0)], with: .automatic)
                if self.callLikeNotifOnce == false {
                    self.updateCreatorInbox(type: "like")
                    self.callLikeNotifOnce = true
                }
                if self.sendLikeOnce, let creatorId = self.creatorId {
                    self.sendLikeOnce = false
                    let ref = Database.database().reference().child("users")
                    ref.child(creatorId).child("userKey").observeSingleEvent(of: .value, with: { snap in
                        if let value = snap.value as? String {
                            self.sendNotification(sub_id: value, message: "Someone liked your solution!")
                        }
                        
                    })
                }
            }
        })
        let action2 =  UIAlertAction(title: "Dislike", style: .default, handler: { alert -> Void in
            let alert2 = UIAlertController(title: "What was wrong?", message: "Tell us shortly (1-2 sentences) why you disliked this material.", preferredStyle: .alert)
            alert2.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Please write here..."
                textField.autocorrectionType = .default
                textField.keyboardType = .twitter
                textField.keyboardAppearance = .dark
                textField.autocapitalizationType = .sentences
                textField.tintColor = .blue
            }
            let attributedString = NSAttributedString(string: "What was wrong?", attributes: [
                NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Bold", size: 18)!, //your font here
                NSAttributedString.Key.foregroundColor : UIColor.systemBlue
                ])
            alert2.setValue(attributedString, forKey: "attributedTitle")
          
            let saveAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { alert -> Void in
                if let uid = Auth.auth().currentUser?.uid, let solutionId = self.solutionId {
                    self.likes.removeAll(where: { $0 == uid })
                    self.dislikes.removeAll(where: { $0 == uid })
                    self.dislikes.append(uid)
                    Database.database().reference().child("solutions").child(solutionId).child("likes").child(uid).removeValue()
                    Database.database().reference().child("solutions").child(solutionId).child("dislikes").child(uid).removeValue()
                    Database.database().reference().child("solutions").child(solutionId).child("dislikes").updateChildValues([uid: uid])
                    if let creatorId = self.creatorId {
                        Database.database().reference().child("users").child(creatorId).child("likesOnSolutions").child(solutionId).child(uid).removeValue()
                        Database.database().reference().child("users").child(creatorId).child("dislikesOnSolutions").child(solutionId).updateChildValues([uid: uid])
                    }
                }
                self.didLikeSolution = false
                self.didDislikeSolution = true
                self.tableView.reloadRows(at: [IndexPath(row: 6, section: 0)], with: .automatic)
            })
            let cancel2 = UIAlertAction(title: "Cancel", style: .cancel)
            alert2.addAction(saveAction)
            alert2.addAction(cancel2)
            self.present(alert2, animated: true)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    func expand() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "expandVC") as? ExpandViewController {
            vc.editMode = false
            vc.images = self.solutionImages
            self.present(vc, animated: true, completion: nil)
        }
    }
    
   
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       // cell.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
    }
    
    func showDropIn(clientTokenOrTokenizationKey: String) {
//        let request =  BTDropInRequest()
//        request.venmoDisabled = true
//        request.paypalDisabled = true
//        request.applePayDisabled = false
//        let dropIn = BTDropInController(authorization: clientTokenOrTokenizationKey, request: request)
//        { (controller, result, error) in
//            if (error != nil) {
//                print("ERROR")
//            } else if (result?.isCanceled == true) {
//                print("CANCELED")
//            } else if let result = result {
//                switch result.paymentMethodType {
//                case .applePay ,.payPal,.masterCard,.discover,.visa:
//                    // Here Result success  check paymentMethod not nil if nil then user select applePay
//                    if let paymentMethod = result.paymentMethod {
//                        self.activityForCardPayment.startAnimating()
//                        self.activityForCardPayment.backgroundColor = .opaqueSeparator
//                        self.view.addSubview(self.activityForCardPayment)
//                        self.handleSuccessFullNonApplePayNonce(nonce: paymentMethod.nonce, paymentDescript: paymentMethod.description, completion: { (outcome) -> Void in
//                            if outcome != "" {
//                                print("SUCCESS IN DID AUTHORIZE")
//                                self.userOwns = true
//                                self.showApplePay = false
//                                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0), ], with: .automatic)
//
//                                self.tableView.reloadData()
//                                self.handleUserPurchased(id: outcome)
//                                self.activityForCardPayment.stopAnimating()
//                                self.activityForCardPayment.removeFromSuperview()
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                                    controller.dismiss(animated: true)
//                                    self.updatePayOutCall()
//                                    self.updateCreatorInbox(type: "purchase")
//                                }
//                            } else {
//                                print("FAILURE IN DID AUTHORIZE")
//                                self.userOwns = false
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                                    controller.dismiss(animated: true)
//                                }
//                                self.activityForCardPayment.stopAnimating()
//                                self.activityForCardPayment.removeFromSuperview()
//                                controller.dismiss(animated: true, completion: {
//                                    let alert = UIAlertController(title: "Card Pay Failed", message: "It looks like this transaction could not be completed. Please check payment card/details and try again.", preferredStyle: .alert)
//                                    let okay = UIAlertAction(title: "Okay", style: .cancel)
//                                    alert.addAction(okay)
//                                    self.present(alert, animated: true)
//                                })
//
//                            }
//                        })
//                    } else {
//                        controller.dismiss(animated: true, completion: {
//                            guard self.allowApplePay else {
//                                print("apple pay not allowed in country")
//                                controller.dismiss(animated: true, completion: nil)
//                                return
//                            }
//                            self.showApplePay = true
//                            self.tableView.reloadRows(at: [IndexPath(row: 5, section: 0), IndexPath(row: 4, section: 0)], with: .automatic)
//                            self.apiClient = BTAPIClient(authorization: clientTokenOrTokenizationKey)
//                        })
//                    }
//                default:
//                    print("error")
//                    controller.dismiss(animated: true, completion: nil)
//                }
//            }
//            controller.dismiss(animated: true, completion: nil)
//        }
//        self.present(dropIn!, animated: true, completion: nil)
    }
    
    func handleApplePkButtonPress() {
//        guard !pkApplePayInCall else {
//            return
//        }
//        pkApplePayInCall = true
//        // call apple pay
//        let paymentRequest = self.paymentRequest()
//        // Example: Promote PKPaymentAuthorizationViewController to optional so that we can verify
//        // that our paymentRequest is valid. Otherwise, an invalid paymentRequest would crash our app.
//
//        if let vc = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) as PKPaymentAuthorizationViewController? {
//            vc.delegate = self
//            self.present(vc, animated: true, completion: nil)
//        } else {
//            print("Error: Payment request is invalid.")
//        }
    }
    //card payment cloud call and result
    func handleSuccessFullNonApplePayNonce(nonce: String, paymentDescript: String, completion: @escaping (String) -> Void) {
        
//        self.functions.httpsCallable("createPay").call(["nonce": nonce, "amountTotal": priceString]) { (result, error) in
//            if let error = error {
//                debugPrint("⭕️PayPal: ", error)
//                self.showApplePay = false
//                print("CARD ENTRY FAILURE PAYMENT FROM CLOUD FUNCTION")
//                completion("")
//            }
//            if let resultVal = result?.data as? [String: Any] {
//                print("CLOUD CARD PAY RESULT COMPLETED: \(resultVal)")
//                if let status = resultVal["status"] {
//                    if status as! String == "SUCCESS" {
//                        if let tid = resultVal["newPayment"] {
//                            completion(tid as! String)
//                        } else {
//                            print("CANNOT RETRIEVE PAYMENT ID FROM CLOUD RESULT")
//                            completion("")
//                        }
//                    } else {
//                        print("STATUS HAS FAILED")
//                        completion("")
//                    }
//                } else {
//                    print("CANNOT RETRIEVE STATUS")
//                    completion("")
//                }
//            }
//
//        }
    }
    //apple pay cloud call and result
    func handleApplePaySuccess(nonce: String, paymentDescript: String, completion: @escaping (String) -> Void) {
        
//        self.functions.httpsCallable("createPay").call(["nonce": nonce, "amountTotal": priceString]) { (result, error) in
//            if let error = error {
//                debugPrint("⭕️PayPal: ", error)
//                self.showApplePay = false
//                print("APPLE PAY CLOUD CALL FAIL IN CLOUD RESULT")
//                completion("")
//            }
//            if let resultVal = result?.data as? [String: Any] {
//                print("CLOUD APPLE PAY RESULT COMPLETED: \(resultVal)")
//                if let status = resultVal["status"] {
//                    if status as! String == "SUCCESS" {
//                        if let tid = resultVal["newPayment"] {
//                            completion(tid as! String)
//                        } else {
//                            print("CANNOT RETRIEVE PAYMENT ID FROM CLOUD RESULT")
//                            completion("")
//                        }
//                    } else {
//                        print("STATUS HAS FAILED")
//                        completion("")
//                    }
//                } else {
//                    print("CANNOT RETRIEVE STATUS")
//                    completion("")
//                }
//            }
//
//        }
                
    }
    
//    func paymentRequest() -> PKPaymentRequest {
//            let paymentRequest = PKPaymentRequest()
//            paymentRequest.merchantIdentifier = "merchant.bidnote";
//            paymentRequest.supportedNetworks = [PKPaymentNetwork.amex, PKPaymentNetwork.visa, PKPaymentNetwork.masterCard];
//            paymentRequest.merchantCapabilities = PKMerchantCapability.capability3DS;
//            paymentRequest.countryCode = "US"; // e.g. US
//            paymentRequest.currencyCode = "USD"; // e.g. USD
//            paymentRequest.paymentSummaryItems = [
//                PKPaymentSummaryItem(label: "BidNote, For: \(self.solutionTitle!)", amount: NSDecimalNumber(string: "\(self.solutionPrice!)")),
//            ]
//            return paymentRequest
//        }
    
//    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
//        let applePayClient = BTApplePayClient(apiClient: self.apiClient!)
//                applePayClient.tokenizeApplePay(payment) {
//                    (tokenizedApplePayPayment, error) in
//                    guard let tokenizedApplePayPayment = tokenizedApplePayPayment else {
//                        // Tokenization failed. Check `error` for the cause of the failure.
//                        // Indicate failure via completion callback.
//                        completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
//                        return
//                    }
//                    // Received a tokenized Apple Pay payment from Braintree.
//                    // If applicable, address information is accessible in `payment`.
//
//                    // Send the nonce to your server for processing.
//                    print("nonce = \(tokenizedApplePayPayment.nonce)")
//
//                    self.handleApplePaySuccess(nonce: tokenizedApplePayPayment.nonce, paymentDescript: tokenizedApplePayPayment.description, completion: { (outcome) -> Void in
//                        if outcome != "" {
//                            print("SUCCESS IN DID AUTHORIZE")
//                            self.userOwns = true
//                            self.showApplePay = false
//                            self.tableView.reloadData()
//                            self.pkApplePayInCall = false
//                            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0), ], with: .automatic)
//                            self.handleUserPurchased(id: outcome)
//                            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                                controller.dismiss(animated: true)
//                                self.updatePayOutCall()
//                                self.updateCreatorInbox(type: "purchase")
//                            }
//                        } else {
//                            print("FAILURE IN DID AUTHORIZE")
//                            self.userOwns = false
//                            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                                controller.dismiss(animated: true)
//                            }
//                            controller.dismiss(animated: true, completion: {
//                                let alert = UIAlertController(title: "Apple Pay Failed", message: "It looks like this transaction could not be completed. Please check payment card/details and try again.", preferredStyle: .alert)
//                                let okay = UIAlertAction(title: "Okay", style: .cancel)
//                                alert.addAction(okay)
//                                self.present(alert, animated: true)
//                                self.pkApplePayInCall = false
//                            })
//
//                        }
//                    })
//
//                    //  self.postNonceToServer(paymentMethodNonce: tokenizedApplePayPayment.nonce)
//                    // Then indicate success or failure via the completion callback, e.g.
//
//                }
   // }
    
    
    func handleUserPurchased(id: String) {
        if let uid = Auth.auth().currentUser?.uid, let solid = self.solutionId {
            let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
            let ref = Database.database().reference().child("users").child(uid).child("purchased")
            let update = [solid : ["time" : timeStamp, "tid": id, "key": solid] as [String : Any]]
            ref.updateChildValues(update)
        }
    }
    
    @objc func addReview() {
        
        self.addReviewButton.isHidden = true
        if Auth.auth().currentUser?.uid != nil, !isAuthor  {
            commentingView.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 0)
            self.view.addSubview(commentingView)
            setUpComment()
            commentOpen = true
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                self.commentingView.frame = CGRect(x: 0, y: self.view.frame.height / 3.4, width: self.view.frame.width, height: self.view.frame.height - self.view.frame.height / 3.4)
                self.textviewA.becomeFirstResponder()
            }, completion: nil)
        } else {
            let alertMore = UIAlertController(title: "Error!", message: "Sorry you cannot review if you are the owner/or do not have a valid userid.", preferredStyle: .alert)
            let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            
            alertMore.addAction(cancel2)
            self.present(alertMore, animated: true, completion: nil)
        }
    }
    func setUpComment () {
        
        textviewA.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        
        textviewA.frame = CGRect(x: 0, y: 51, width: self.view.frame.width, height: 100)
        divideViewComment.frame = CGRect(x: 0, y: 0, width: commentingView.frame.width , height: 50)
        divideViewComment.backgroundColor = UIColor(red: 0.8863, green: 0.8706, blue: 0.898, alpha: 1.0)
        commentingView.layer.shadowColor = UIColor.gray.cgColor
        commentingView.layer.shadowOpacity = 1
        commentingView.layer.shadowOffset = CGSize.zero
        commentingView.layer.shadowRadius = 2
        commentingView.layer.cornerRadius = 8.0
        divideViewComment.roundCorners([.topLeft, .topRight], radius: 8.0)
        commentingView.addSubview(divideViewComment)
        commentingView.backgroundColor = textviewA.backgroundColor
        exitButtonComment.frame = CGRect(x: 10, y: 5, width: 40, height: 40)
        exitButtonComment.setTitle("Exit", for: .normal)
        exitButtonComment.addTarget(self, action: #selector(self.closeComment), for: .touchUpInside)
        exitButtonComment.setTitleColor(.gray, for: .normal)
        let postButton = UIButton()
        postButton.frame = CGRect(x: self.commentingView.frame.width - 95, y: 8, width: 80, height: 34)
        postButton.backgroundColor = UIColor(red: 0, green: 0.5608, blue: 0.9373, alpha: 1.0)
        postButton.setTitleColor(.white, for: .normal)
        postButton.setTitle("Post", for: .normal)
        postButton.layer.cornerRadius = 10.0
        postButton.clipsToBounds = true
        postButton.addTarget(self, action: #selector(self.submitReview), for: .touchUpInside)
        self.commentingView.addSubview(postButton)
        self.commentingView.addSubview(exitButtonComment)
        self.commentingView.addSubview(textviewA)
    }
    
    @objc func submitReview() {
        //check if user is banned
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("banned")
            ref.child(uid).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    //user is banned, end
                } else {
                    self.checkIfCleanAndContinueReviewPost()
                }
            })
            
        }
        
    }
    
    func checkIfCleanAndContinueReviewPost() {
        if let message = self.textviewA.text, message.count > 2 {
            let string1 = message.lowercased()
            if  string1.contains("penis") || string1.contains("vagina")  || string1.contains(" fag") || string1.contains("anal")  || string1.contains("cunt") ||  string1.contains("porn") || string1.contains("nigger") || string1.contains("beaner") || string1.contains(" coon ") || string1.contains("spic") || string1.contains("wetback") || string1.contains("chink") || string1.contains("gook") ||  string1.contains("twat") || string1.contains(" darkie ") || string1.contains("god hates") || string1.contains("    ") ||  string1.contains("nigga") || string1.contains("kike") || string1.contains("fuck") || string1.contains("shit")
            
            {
                let alertMore = UIAlertController(title: "Error!", message: "This has a word or character that violates our reviews policy. Please remove any vulgar words or characters, then post the comment (:", preferredStyle: .alert)
                let cancel2 = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                
                alertMore.addAction(cancel2)
                self.present(alertMore, animated: true, completion: nil)
                return
            } else {
                let time = Int(NSDate().timeIntervalSince1970)
                if self.oncep == false {
                    self.oncep = true
                    if let sid = self.solutionId {
                        if let uid = Auth.auth().currentUser?.uid {
                            let ref = Database.database().reference()
                            let key = uid
                            let feedLi = ["message" : message, "sender" : uid, "timeStamp" : time, "key" : key] as [String : Any]
                            let mySetup = [key : feedLi]
                            
                            ref.child("solutions").child(sid).child("reviews").updateChildValues(mySetup)
                            self.oncep = false
                            let review1 = review()
                            review1.userId = uid
                            review1.id = key
                            review1.reviewString = message
                            review1.time = time
                            if let firstInd = self.reviews.firstIndex(where: { $0.id == key }){
                                self.reviews[firstInd] = review1
                            } else {
                                self.reviews.append(review1)
                            }
                            self.textviewA.text = ""
                            self.closeComment()
                            self.tableView.reloadData()
                            // sendNotification()
                        }
                    }
                }
            }
        }
    }
    
    @objc func closeComment() {
        textviewA.resignFirstResponder()
        commentOpen = false
        self.addReviewButton.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.commentingView.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 0)
        }, completion: { finished in
            self.commentingView.removeFromSuperview()
            self.exitButtonComment.removeFromSuperview()
            self.divideViewComment.removeFromSuperview()
            self.textviewA.removeFromSuperview()
        })
    }
    
    func updateTagViews() {
        let ref = Database.database().reference().child("tagViews")
        if let uid = Auth.auth().currentUser?.uid {
            if let tags = self.solutionTags {
                for each in tags {
                    let result = [uid: uid]
                    let newString = each.trimmingTrailingSpaces.replacingOccurrences(of: " ", with: "-").lowercased()
                    ref.child(newString).updateChildValues(result)
                }
            }
        }
    }
    
    func updateCreatorInbox(type: String) {
        if let creator = self.creatorId {
            let ref = Database.database().reference().child("users")
            if let key = ref.child(creator).child("inbox").childByAutoId().key {
                let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                var contentString = "Someone purchased your material! You will recieve a commission payout within the next 24 hours :D"
                if type != "purchase" {
                    contentString = "Someone liked your material! Looks like someone got smarter and wanted to thank you, or at least thats what we think happened (;"
                }
                let inboxUpdate = ["key": key, "type": type, "content": contentString, "time": timeStamp, "read": 0] as [String : Any]
                let finalUpdate = [key: inboxUpdate]
                ref.child(creator).child("inbox").updateChildValues(finalUpdate)
                ref.child(creator).updateChildValues(["inboxUnseen": 1])
                if type == "purchase" {
                    ref.child(creator).child("userKey").observeSingleEvent(of: .value, with: { snap in
                        if let value = snap.value as? String {
                            self.sendNotification(sub_id: value, message: "Someone just purchased your material! Check your Venmo/PayPal over the next day for a commission payout, happy studying!")
                        }
                    })
                }
            }
        }
    }
    
    func updateSolutionViews() {
        let ref = Database.database().reference().child("solutions")
        if let solId = self.solutionId, let myUid = Auth.auth().currentUser?.uid {
            ref.child(solId).child("views").updateChildValues([myUid: myUid])
        }
    }
    
    func updateSchoolViews() {
        let defaults = UserDefaults.standard
        if let _ = Auth.auth().currentUser?.uid, let schoolCode = self.schoolCode, !updateSchoolViewsOnce {
            updateSchoolViewsOnce = true
            if var school = defaults.dictionary(forKey: "schools") as? [String: Int] {
                if let currentNum = school[schoolCode] {
                    school[schoolCode] = currentNum + 1
                } else {
                    school[schoolCode] = 1
                }
                defaults.set(school, forKey: "schools")
                print("updated schools dict for key: \(schoolCode)")
            } else {
                defaults.set([schoolCode: 1], forKey: "schools")
                print("created school dict with first school: \(schoolCode)")
            }
        }
    }
    
    func updateMyTagViews() {
        let defaults = UserDefaults.standard
        if let _ = Auth.auth().currentUser?.uid, let tags = self.solutionTags {
            for each in tags {
                let updateValue = each.lowercased().trimmingTrailingSpaces.replacingOccurrences(of: " ", with: "-")
                if var tagViews = defaults.dictionary(forKey: "tagViews") as? [String: Int] {
                    if let currentNum = tagViews[updateValue] {
                        tagViews[updateValue] = currentNum + 1
                    } else {
                        tagViews[updateValue] = 1
                    }
                    defaults.set(tagViews, forKey: "tagViews")
                    print("updated tagViews dict for key: \(updateValue)")
                } else {
                    defaults.set([updateValue: 1], forKey: "tagViews")
                    print("created tagViews dict with first tag: \(updateValue)")
                }
            }
        }
    }
    //ADMIN PAYOUT INFO: three collections: adminPayouts, payoutData, and adminArchive
    //Payouts api calls from adminPayouts, and deletes entries once finished
    //payout data is just the stored, and permanant data for each key, which is an individual sale, not payout: ie who bought, what time, and the price
    //adminArchive is past payout data, form of time key: {uid: {key, payTotal, payId, keysDict}}
    // note that admin archive is only added to in the payout call in AdminPayoutsVC
    var oneCallPayout = false
    func updatePayOutCall() {
        guard oneCallPayout == false else {
            return
        }
        oneCallPayout = true
        if let uid = Auth.auth().currentUser?.uid, let solid = self.solutionId, let price = self.solutionPrice, let creator = self.creatorId {
            let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
            let ref = Database.database().reference().child("payoutData")
            if let key = ref.childByAutoId().key {
                //payoutdata add= key: {payerUid, time, authorUid, price, solId}
                ref.child(key).child(creator).updateChildValues(["time": timeStamp, "price": price, "key": key, "authorUid": creator, "payerUid": uid, "solId": solid])
                //checked/approved below: adding new adminpayout: creatorid: {key: price}
                let ref2 = Database.database().reference().child("payoutAdmin")
                ref2.child(creator).updateChildValues([key: price])
            }
        }
    }
    
    @objc func prozessTimer() {
        counter += 1
        if counter == 4 {
            self.updateTagViews()
            self.updateSchoolViews()
            self.updateMyTagViews()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
           timer = nil
    }
    
    func checkIfInAdminQueue() {
        let ref = Database.database().reference().child("adminQueue")
        if let solid = self.solutionId {
            ref.child(solid).observeSingleEvent(of: .value, with: {
                snap in
                if snap.exists() {
                    self.imagesAlreadyInAdminQueue = true
                    self.videoAlreadyInAdminQueue = true
                }
            })
        }
    }
    
    
    func updateInQueue() {
        self.imagesAlreadyInAdminQueue = true
        self.videoAlreadyInAdminQueue = true
    }
    
    func sendNotification (sub_id: String, message: String) {
        self.functions.httpsCallable("oneSignalCall").call(["userKey": sub_id, "notif_message": message]) { (result, error) in
            if let error = error {
                debugPrint("⭕️Notification: ", error)
                print("failed")
            }
        }
    }
    func openPdfImages() {
        var loadedImages = [UIImage]()
        if let solImages = self.solutionImages {
            let dispatch = DispatchGroup()
            for each in solImages {
                dispatch.enter()
                downloadImage(with: each) { image in
                    guard let image  = image else {
                        dispatch.leave()
                        return
                    }
                    loadedImages.append(image)
                    dispatch.leave()
                }
            }
            dispatch.notify(queue: DispatchQueue.main) {
                if loadedImages.count != 0 {
                    if let pdf = loadedImages.makePDF() {
                        guard let documentData = pdf.dataRepresentation() else { return }
                        let activityController = UIActivityViewController(activityItems: [documentData], applicationActivities: nil)
                        activityController.excludedActivityTypes = [.message, .postToFacebook, .postToTwitter, .postToFlickr, .postToVimeo]
                        activityController.popoverPresentationController?.sourceView = self.view
                        self.present(activityController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    func downloadImage(with urlString : String , imageCompletionHandler: @escaping (UIImage?) -> Void){
            guard let url = URL.init(string: urlString) else {
                return  imageCompletionHandler(nil)
            }
        let resource = KF.ImageResource(downloadURL: url)
            
            KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
                switch result {
                case .success(let value):
                    imageCompletionHandler(value.image)
                case .failure:
                    imageCompletionHandler(nil)
                }
            }
        }
    
    func openZoom() {
        if let zoomLink = self.zoomLink {
            if let url = URL(string: zoomLink) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
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
extension SolutionViewController {
  
}
extension Array where Element: UIImage {
    
      func makePDF()-> PDFDocument? {
        let pdfDocument = PDFDocument()
        for (index,image) in self.enumerated() {
            let pdfPage = PDFPage(image: image)
            pdfDocument.insert(pdfPage!, at: index)
        }
        return pdfDocument
    }
}
extension SolutionViewController {
    
    func saveCustomerIdToFirebase(customerId: String) {
        let ref = Database.database().reference().child("users")
        if let uid = Auth.auth().currentUser?.uid {
            ref.child(uid).updateChildValues(["squareId" : customerId])
        }
    }
}
class tableViewCell1Solution: UITableViewCell {
    @IBOutlet weak var labelTitle: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2778, 2688:
                labelTitle.font = UIFont(name: "HelveticaNeue-Bold", size: 22)
            default:
                print("Unknown")
            }
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                print("iPad")
            }
        }
    }
}
class tableViewCell9Solution: UITableViewCell {
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2778, 2688:
                tagsLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
            default:
                print("Unknown")
            }
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                print("iPad")
            }
        }
    }
}
class tableViewCell2Solution: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var images: [String]?
    var blurred: [String]?
    var blur: Bool?
    var zoomLink: String?
    var showPrompt: Int?
    
    var delegate: expand?
    var delegate2: imagesToPdf?
    var delegate3: zoomClicked?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewLayout: UICollectionViewFlowLayout!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = CGRect(x: 10, y: 10, width: contentView.frame.width - 10, height: contentView.frame.height - 20)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let blur = self.blur, blur == true, let blurred = self.blurred {
            return blurred.count
        }
        return images?.count ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "previewCV", for: indexPath) as? previewCV
        if let showPrompt = self.showPrompt, showPrompt != 0, correctIndexPath(index: indexPath.row) {
            cell?.showPrompt = showPrompt
        } else {
            cell?.showPrompt = 0
        }
        if let images = self.images, let blurred = self.blurred {
            if let blur = self.blur, blur == true {
                if let url = URL(string: blurred[indexPath.item]) {
                    cell?.imageView.kf.setImage(with: url)
                }
                cell?.expandButton.isHidden = true
                cell?.fullPDF.isHidden = true
                cell?.zoomButton.isHidden = true
            } else {
                if let url = URL(string: images[indexPath.item]) {
                    cell?.imageView.kf.setImage(with: url)
                }
                if indexPath.item == 0 {
                    cell?.fullPDF.isHidden = false
                    if let _ = self.zoomLink {
                        cell?.zoomButton.isHidden = false
                    } else {
                        cell?.zoomButton.isHidden = true
                    }
                } else {
                    cell?.fullPDF.isHidden = true
                    cell?.zoomButton.isHidden = true
                }
            }
        }
        cell?.expandButton.addTarget(self, action: #selector(openExpand), for: .touchUpInside)
        cell?.fullPDF.addTarget(self, action: #selector(openPdf), for: .touchUpInside)
        cell?.zoomButton.addTarget(self, action: #selector(openZoomLink), for: .touchUpInside)
        return cell ?? UICollectionViewCell()
        
    }
    
    func correctIndexPath (index: Int) -> Bool {
        if index == 0 || index == 1 {
            return true
        }
        return false
    }
    
    @objc func openPdf() {
        delegate2?.openPdfImages()
    }
    @objc func openExpand() {
        delegate?.expand()
    }
    @objc func openZoomLink() {
        delegate3?.openZoom()
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let blur = self.blur, blur == false {
            delegate?.expand()
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: contentView.frame.width / 1.2, height: contentView.frame.width / 1.2)
    }
}
class tableViewCell3Solution: UITableViewCell {
    @IBOutlet weak var descriptLabel: UILabel!
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2778, 2688:
                descriptLabel.font = UIFont(name: "HelveticaNeue", size: 18)
            default:
                print("Unknown")
            }
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                print("iPad")
            }
        }
    }
}

class tableViewCell4Solution: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        price.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
    }
    var delegate: payButtonClicked?
    
    @IBOutlet weak var price: UIButton!
    
    @IBAction func priceClicked(_ sender: Any) {
        delegate?.clickedPay()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
            price.frame = CGRect(x: 20, y: 5, width: contentView.frame.width - 40, height: 45)
            price.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
            price.layer.cornerRadius = 4.0
        //imageViewApplePay.frame = CGRect(x: (contentView.frame.width / 2) - 40, y: 0, width: 40, height: 40)
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
    }
    @objc func applePayPressed() {
        delegate?.clickedPay()
    }
}

class tableViewCell5Solution: UITableViewCell {
    @IBOutlet weak var segmentBar: UISegmentedControl!
    var delegate: switchedSegment?
    override func layoutSubviews() {
        super.layoutSubviews()
        segmentBar.addTarget(self, action: #selector(changeSeg(_:)), for: .valueChanged)
        segmentBar.frame = CGRect(x: 20, y: 10, width: contentView.frame.width - 40, height: 35)
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            segmentBar.setTitleTextAttributes(titleTextAttributes, for: .normal)
            segmentBar.setTitleTextAttributes(titleTextAttributes, for: .selected)
       
    }
    
    @objc func changeSeg(_ sender: UISegmentedControl) {
        delegate?.switched(index: sender.selectedSegmentIndex)
    }
}
class tableViewCell6Solution: UITableViewCell {
    
    @IBOutlet weak var reviewLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var backView: UIView!
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        backView.layer.cornerRadius = 12.0
    }
    
}
class tableViewCell7Solution: UITableViewCell {
    @IBOutlet weak var noReviewsYetLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        self.noReviewsYetLabel.frame = CGRect(x: 15, y: 10, width: contentView.frame.width - 30, height: 40)
    }
}
class tableViewCell8Solution: UITableViewCell {
    
    
    @IBOutlet weak var likesIcon: UIImageView!
    
    @IBOutlet weak var likesLabel: UILabel!
    
    @IBOutlet weak var dislikesIcon: UIImageView!
    
    @IBOutlet weak var dislikesLabel: UILabel!
    
    @IBOutlet weak var averageRatingUserLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        likesIcon.frame = CGRect(x: 45, y: 15, width: 35, height: 35)
        likesLabel.frame = CGRect(x: 28, y: 50, width: 70, height: 25)
        dislikesIcon.frame = CGRect(x: contentView.frame.width - 80, y: 15, width: 35, height: 35)
        dislikesLabel.frame = CGRect(x: contentView.frame.width - 97, y: 50, width: 70, height: 25)
        averageRatingUserLabel.frame = CGRect(x: 100, y: 5, width: contentView.frame.width - 200, height: 80)
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2778, 2688:
                likesIcon.frame = CGRect(x: 40, y: 15, width: 40, height: 40)
                likesLabel.frame = CGRect(x: 23, y: 55, width: 75, height: 25)
                dislikesIcon.frame = CGRect(x: contentView.frame.width - 85, y: 15, width: 40, height: 40)
                dislikesLabel.frame = CGRect(x: contentView.frame.width - 103, y: 55, width: 75, height: 25)
                
            default:
                print("Unknown")
            }
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                print("iPad")
            }
        }
    }
}
class tableViewCell10Solution: UITableViewCell {
    
    @IBOutlet weak var moreByAuthorButton: UIButton!
    
    @IBOutlet weak var reportButton: UIButton!
    
    @IBOutlet weak var payHelpButton: UIButton!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        moreByAuthorButton.frame = CGRect(x: 30, y: contentView.frame.height - 120, width: contentView.frame.width - 60, height: 35)
        payHelpButton.frame = CGRect(x: 30, y: contentView.frame.height - 80, width: contentView.frame.width - 60, height: 35)
        reportButton.frame = CGRect(x: 30, y: contentView.frame.height - 40, width: contentView.frame.width - 60, height: 35)
    }
    
}

class previewCV: UICollectionViewCell {
    
    var promptLabel = UILabel()
    var showPrompt: Int?
    
    @IBOutlet weak var fullPDF: UIButton!
  
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var expandButton: UIButton!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        imageView.layer.cornerRadius = 12.0
        fullPDF.frame = CGRect(x: 15, y: 5, width: 120, height: 35)
        fullPDF.layer.cornerRadius = 6.0
        zoomButton.frame = CGRect(x: 15, y: 45, width: 120, height: 35)
        zoomButton.layer.cornerRadius = 6.0
        contentView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        if let showPrompt = self.showPrompt, showPrompt != 0 {
            promptLabel.frame = CGRect(x: 15, y: contentView.frame.height - 60, width: contentView.frame.width - 20, height: 60)
            if showPrompt == 1 {
                promptLabel.text = "Purchase this tutoring service+material below. Only partial service preview available until valid purchase."
            } else {
                promptLabel.text = "Purchase full material/tutoring below. Your personal+payment information is never shared with anyone."
            }
            promptLabel.font = UIFont(name: "HelveticaNeue", size: 16)
            promptLabel.textColor = .lightGray
            promptLabel.shadowOffset = CGSize(width: 1, height: 1)
            promptLabel.shadowColor = .black
            promptLabel.textAlignment = .left
            promptLabel.numberOfLines = 3
            contentView.addSubview(promptLabel)
        } else {
            promptLabel.removeFromSuperview()
        }
    }
    
    
    @IBOutlet weak var zoomButton: UIButton!
    
    
    
}
extension UIView {
    func roundCorners(_ corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}


