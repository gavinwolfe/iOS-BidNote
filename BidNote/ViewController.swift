//
//  ViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 2/5/23.
//

import UIKit
import Firebase
import FirebaseAuth


class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, openSearch {

    var refreshControl = UIRefreshControl()
    @IBOutlet weak var collectionView: UICollectionView!
    let buttonCam = UIButton()
    var homeNotes = [solutionObject]()
    let collectionViewHeaderFooterReuseIdentifier = "HomeCollectionReusableView"
    let loading = UIActivityIndicatorView()
    var timesRan = 2
    var working = false
    var currentItemCount = 0
    //tutorial view:
    let button1 = UIButton()
    let button2 = UIButton()
    var showLicPrompt = false
    var searchTitle = "Organic Chemistry..."
    func checkPrompt() {
        let ref = Database.database().reference()
        ref.child("prompt").observeSingleEvent(of: .value, with: { snap in
            if snap.exists() {
                self.showLicPrompt = true
                self.searchTitle = "Organic Chemistry Tutor..."
            } else {
                self.showLicPrompt = false
            }
        })
    }
    
    func checkAnnon () {
        if Auth.auth().currentUser?.isAnonymous == true {
            loading.frame = view.bounds
            loading.color = .lightGray
            loading.style = .large
            loading.startAnimating()
            view.addSubview(loading)
            self.getNotes()
            let defaults = UserDefaults.standard
            if let _ = defaults.string(forKey: "showTutorial") {
            } else {
                self.tutorialMode()
            }
            //all good
        } else {
            Auth.auth().signInAnonymously() { (authResult, error) in
                let ref = Database.database().reference().child("users")
                let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                let update = ["joinedTime": timeStamp]
                if let uid = authResult?.user.uid {
                    ref.child(uid).updateChildValues(update)
                    self.getNotes()
                }
                let defaults = UserDefaults.standard
                defaults.set(false, forKey: "taxRead")
                if let uid = authResult?.user.uid, let key = ref.child(uid).child("inbox").childByAutoId().key {
                    let inboxUpdate = ["key": key, "type": "purchase", "content": "Welcome to BidNote! This is where you receive important messages in the app (:", "time": timeStamp, "read": 0] as [String : Any]
                    let finalUpdate = [key: inboxUpdate]
                    ref.child(uid).updateChildValues(["inboxUnseen": 1])
                    ref.child(uid).child("inbox").updateChildValues(finalUpdate)
                }
                self.tutorialMode()
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
          return .lightContent
    }
    
    func searchGrab2(content: String) {
        let ref = Database.database().reference().child("searchKeys").child(content)
        ref.queryLimited(toLast: 50).observeSingleEvent(of: .value, with: { snap in
            if let values = snap.value as? [String: AnyObject] {
                let dispatch = DispatchGroup()
                for (one,_) in values {
                    dispatch.enter()
                    Database.database().reference().child("solutions").child(one).observeSingleEvent(of: .value, with: { snap2 in
                        if let data = snap2.value as? [String: AnyObject] {
                            //add solution to filtered array
                            // if its already added, increase its weight. the more keywords, the better
                            print("content loaded\(data)")
                        }
                        dispatch.leave()
                    })
                }
                dispatch.notify(queue: DispatchQueue.main) {
                    print("completed")
                }
            }
        })
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        collectionView.register(UINib(nibName: collectionViewHeaderFooterReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier:collectionViewHeaderFooterReuseIdentifier)
        
        self.checkForInbox()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkAnnon()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        //collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        buttonCam.frame = CGRect(x: 0, y: self.view.bounds.height - 135, width: view.bounds.width, height: 52)
        buttonCam.backgroundColor = .systemBlue
        buttonCam.addTarget(self, action: #selector(self.buttonCameraAction), for: .touchUpInside)
        buttonCam.setTitle("Post New Material", for: .normal)
        buttonCam.titleLabel?.textColor = .white
        buttonCam.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        view.addSubview(self.buttonCam)
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControl.Event.valueChanged)
        collectionView.addSubview(refreshControl)
        if UIDevice().userInterfaceIdiom == .pad {
            buttonCam.frame = CGRect(x: 0, y: self.view.bounds.height - 120, width: view.bounds.width, height: 60)
        }
        if UIScreen.main.nativeBounds.height <= 1634 || UIScreen.main.nativeBounds.height == 2208 || UIScreen.main.nativeBounds.height == 1920 {
            buttonCam.frame = CGRect(x: 0, y: self.view.bounds.height - 105, width: self.view.bounds.width, height: 60)
        }
        print(UIScreen.main.nativeBounds.height)
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
               // Do any additional setup after loading the view.
    }
    
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.buttonCam.frame = CGRect(x: 0, y: self.view.bounds.height - 120, width: self.view.bounds.width, height: 60)
                self.button1.frame = CGRect(x: 15, y: self.view.bounds.height - 262, width: self.view.bounds.width-30, height: 50)
                self.button2.frame = CGRect(x: 15, y: self.view.bounds.height - 205, width: self.view.frame.width-30, height: 50)
                self.collectionView.reloadData()
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.buttonCam.frame = CGRect(x: 0, y: self.view.bounds.height - 120, width: self.view.bounds.width, height: 60)
                    self.button1.frame = CGRect(x: 15, y: self.view.bounds.height - 262, width: self.view.bounds.width-30, height: 50)
                    self.button2.frame = CGRect(x: 15, y: self.view.bounds.height - 205, width: self.view.frame.width-30, height: 50)
                    self.collectionView.reloadData()
                })
            }
        }
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
  
    
    var waitCallRefresh = false
    @objc func refresh(sender:AnyObject) {
        print("would refresh")
        //check for new articles
        if self.waitCallRefresh == false {
            self.waitCallRefresh = true
            self.homeNotes.removeAll()
            self.collectionView.reloadData()
            self.getNotes()
        }
      
        // Code to refresh table view
    }
    
    @objc func buttonCameraAction() {
        guard self.showLicPrompt == false else {
            let alert = UIAlertController(title: "Academic Honesty, Plagiarism, and Copyright Clause", message: "BidNote is a platform strictly for tutoring and academic lessons. Goods or Services that are even remotely considered academically dishonest, plagiarized, or copyrighted will result in an immediate user ban and the goods/services will be outright rejected. WARNING: All goods/services are manually reviewed by administrators prior to acceptance. Please only provide services that are created by you and you alone.", preferredStyle: .alert)
            let agree = UIAlertAction(title: "Agree and Continue", style: UIAlertAction.Style.default, handler: { alert -> Void in
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NewSolutionVC") as! UINavigationController
                if let viewCon = vc.viewControllers[0] as? NewSolutionViewController {
                    
                }
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            })
            let cancel = UIAlertAction(title: "Go Back", style: .cancel)
            alert.addAction(cancel)
            alert.addAction(agree)
            self.present(alert, animated: true)
            return
        }
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NewSolutionVC") as! UINavigationController
        if let viewCon = vc.viewControllers[0] as? NewSolutionViewController {
            
        }
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        currentItemCount = homeNotes.count
        return homeNotes.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellHome", for: indexPath) as? mainCollectionCell
        if let title = homeNotes[indexPath.item].titleString, let price = homeNotes[indexPath.item].price, let percentLike = homeNotes[indexPath.item].percentLike, let image = homeNotes[indexPath.item].coverImage, let timestring = homeNotes[indexPath.item].timeString, let tags = homeNotes[indexPath.item].tags {
            cell?.titleCellLabel.text = title
            if let url = URL(string: image) {
                cell?.imageView1.kf.setImage(with: url)
                cell?.imageView2.kf.setImage(with: url)
            }
            if price.decimalCount() == 1 {
                if self.showLicPrompt {
                    cell?.priceLabel.text = "Access: $\(price)0"
                } else {
                    cell?.priceLabel.text = "Access: $\(price)0"
                }
            } else if price.decimalCount() == 0 {
                if self.showLicPrompt {
                    cell?.priceLabel.text = "Access: $\(price)0"
                } else {
                    cell?.priceLabel.text = "Access: $\(price)0"
                }
            } else if price.decimalCount() == 2 {
                if self.showLicPrompt {
                    cell?.priceLabel.text = "Access: $\(price)"
                } else {
                    cell?.priceLabel.text = "Access: $\(price)"
                }
            }
            if price == 0.0 {
                if self.showLicPrompt {
                    cell?.priceLabel.text = "Access: Free"
                } else {
                    cell?.priceLabel.text = "Access: Free"
                }
            }
            var tagsString = "Tags: "
            var start = 1
            for each in tags {
                if start == tags.count {
                    tagsString = tagsString + "\(each) "
                } else {
                    tagsString = tagsString + "\(each), "
                }
                start = start + 1
            }
           // cell?.colorView.backgroundColor = UIColor(red: 0.9373, green: 0.9373, blue: 0.9373, alpha: 1.0)
            //randomColor(number: indexPath.item + 1)
            cell?.tagsLabel.text = tagsString
            cell?.timeLabel.text = timestring
            cell?.percentLikedLabel.text = "\(percentLike)% liked"
            if percentLike < 40 {
                cell?.percentLikedLabel.textColor = .systemRed
            } else if percentLike >= 40 && percentLike < 65 {
                cell?.percentLikedLabel.textColor = .systemYellow
            } else {
                cell?.percentLikedLabel.textColor = .systemGreen
            }
        }
        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: collectionViewHeaderFooterReuseIdentifier, for: indexPath) as! HomeCollectionReusableView
        view.searchL.text = self.searchTitle
        view.delegate = self
        view.overView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if UIDevice().userInterfaceIdiom == .pad {
            return CGSize(width: view.frame.width, height: view.frame.width / 3)
        }
        return CGSize(width: view.frame.width, height: view.frame.width / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2532, 2556:
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.75)
            case 1334:
                print("iPhone 6/6S/7/8")
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
            case 1920, 2208:
                print("iPhone 6+/6S+/7+/8+")
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
            case 2778:
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.78)
            case 2796:
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.78)
            case 2688:
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.78)
            case 2436:
                print("iPhone X, XS")
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
            default:
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.92)
               
            }
        } else if UIDevice().userInterfaceIdiom == .pad {
            if UIScreen.main.nativeBounds.height == 2732 {
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 5.2)
            }
            if UIScreen.main.nativeBounds.width >= 1500 {
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 5.8)
            }
            if  UIScreen.main.nativeBounds.height <= 2266 {
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 5)
            }
            return CGSize(width: collectionView.frame.width, height: view.frame.width / 5)
        }
        return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
    }
    
    
    
    
    func getNotes() {
        checkPrompt()
        let result = getSchools()
        if (result != "") {
            retrieveNotesRecentSchool(school: result, completion: { (outcome) -> Void in
                if outcome == "fetch completed" {
                    let result2 = self.getMyTags()
                    if result2.count != 0 {
                        //WEVE got their top 3 or 2 or 1 viewed tags
                        var counter = 0
                        for each in result2 {
                            self.getSolutionsFromTag(tag: each, completion: { (outcome) -> Void in
                                if outcome != "" {
                                    counter+=1
                                    if counter == result2.count {
                                        self.collectionView.reloadData()
                                        self.loading.stopAnimating()
                                        self.loading.removeFromSuperview()
                                        self.waitCallRefresh = false
                                        self.refreshControl.endRefreshing()
                                        return
                                    }
                                }
                            })
                        }
                    } else {
                        //somehow they dont have any tag views but a top school
                        
                    }
                } else {
                    print("made recent call from no schools")
                    //no recents from their school idk how but ok
                    self.grabSolutionsByRecent(fixedWeight: false, limit: 1, completion: { (outcome) -> Void in
                        print("finished new user-load")
                        self.collectionView.reloadData()
                        self.loading.stopAnimating()
                        self.loading.removeFromSuperview()
                        self.waitCallRefresh = false
                        self.refreshControl.endRefreshing()
                        return
                    })
                }
                
            })
            
        } else {
          
            grabSolutionsByRecent(fixedWeight: false,limit: 2, completion: { (outcome) -> Void in
                print("finished new user-load")
                self.collectionView.reloadData()
                self.loading.stopAnimating()
                self.loading.removeFromSuperview()
                self.waitCallRefresh = false
                self.refreshControl.endRefreshing()
                return
            })
        }
        // second grab is based on interacted with tags
        //third grab is popular tags
        
    }
    
    
    
    
    func getSchools() -> String {
        let defaults = UserDefaults.standard
        if let schools = defaults.dictionary(forKey: "schools") as? [String: Int] {
            if let max = schools.max(by: { $0.value < $1.value }) {
                return max.key
            }
        }
        return ""
    }
    
    func getMyTags() -> [String] {
        let defaults = UserDefaults.standard
        if let tagViews = defaults.dictionary(forKey: "tagViews") as? [String: Int] {
            if tagViews.count <= 2 {
                var stringRetrun = [String]()
                let oneTags = tagViews.sorted { $0.value > $1.value }
                for each in oneTags {
                    stringRetrun.append(each.key)
                }
                return stringRetrun

            } else if tagViews.count >= 3 {
               let threeTags = tagViews.sorted { $0.value > $1.value }
                print(threeTags)
                var stringRetrun = [String]()
                var count = 0
                for each in threeTags {
                    if count != 3 {
                        stringRetrun.append(each.key)
                        count+=1
                    } else {
                        break
                    }
                }
                return stringRetrun
            }
        }
        return [String]()
    }
    
    func retrieveNotesRecentSchool(school: String, completion: @escaping (String) -> Void) {
        let ref = Database.database().reference()
        let solRef = Database.database().reference().child("solutions")
        var maxDrop = 2
        let defaults = UserDefaults.standard
        let purchasedSave = defaults.stringArray(forKey: "purchased") ?? [String]()
        let schoolRecent = "\(school)-recent"
        ref.child(schoolRecent).queryLimited(toFirst: 20).queryOrderedByValue().observeSingleEvent(of: .value, with: { snapshot in
            if let data = snapshot.value as? [String: Int] {
                let dispatch = DispatchGroup()
                for (solid,_) in data {
                    if !self.homeNotes.contains( where: { $0.id == solid } ) {
                        dispatch.enter()
                        solRef.child(solid).observeSingleEvent(of: .value, with: { snap in
                            let vals = snap.value as? [String: AnyObject]
                            if let title = vals?["solTitle"] as? String, let tags = vals?["solTags"] as? [String: String], let coverImages = vals?["blurredImages"] as? [String: String], let finalCreatorId = vals?["creatorId"] as? String, let price = vals?["price"] as? Double, let time = vals?["time"] as? Int, let solId = vals?["solId"] as? String {
                                if maxDrop > 0 && purchasedSave.contains(solId) {
                                    maxDrop -= 1
                                } else {
                                    let solution = solutionObject()
                                    solution.id = solId
                                    solution.titleString = title
                                    solution.time = time
                                    solution.price = price
                                    solution.weight = Int.random(in: 10..<30)
                                    solution.tags = tags.values.map({$0})
                                    solution.creatorId = finalCreatorId
                                    solution.coverImage = coverImages.values.map({$0})[0]
                                    solution.dislikes = [String]()
                                    solution.likes = [String]()
                                    if let likes = vals?["likes"] as? [String: String]{
                                        solution.likes = likes.values.map({$0})
                                    }
                                    if let dislikes = vals?["dislikes"] as? [String: String] {
                                        solution.dislikes = dislikes.values.map({$0})
                                    }
                                    if solution.dislikes.count == 1 && solution.likes.count == 0 {
                                        solution.percentLike = 0
                                    } else if solution.dislikes.count >= 1 && solution.likes.count >= 1 {
                                        let total:Float = Float(solution.dislikes.count + solution.likes.count)
                                        let likesi:Float = Float(solution.likes.count)
                                        //CGRect(x: shawdowView1.frame.width - 150, y: 0, width: 140, height: 8)
                                        let ratio:Float = Float(likesi / total)
                                        solution.percentLike = Int(ratio * 100)
                                    } else {
                                        solution.percentLike = 100
                                    }
                                    let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                                    let timer = timeStamp - time
                                    if timer <= 59 {
                                        solution.timeString = "\(timer) sec ago"
                                    }
                                    if timer > 59 && timer < 3600 {
                                        let minuters = timer / 60
                                        solution.timeString = "\(minuters) mins ago"
                                        if minuters == 1 {
                                            solution.timeString = "\(minuters) min ago"
                                        }
                                    }
                                    if timer > 59 && timer >= 3600 && timer < 86400 {
                                        let hours = timer / 3600
                                        if hours == 1 {
                                            solution.timeString = "\(hours) hr ago"
                                        } else {
                                            solution.timeString = "\(hours) hrs ago"
                                        }
                                    }
                                    if timer > 86400 {
                                        let days = timer / 86400
                                        solution.timeString = "\(days) days ago"
                                        if days == 1 {
                                            solution.timeString = "\(days) day ago"
                                        }
                                    }
                                    if timer > 2592000 {
                                        let months = timer/2592000
                                        solution.timeString = "\(months) months ago"
                                        if months == 1 {
                                            solution.timeString = "\(months) month ago"
                                        }
                                    }
                                    if let unblurP = vals?["unblurPreview"] as? String {
                                        solution.coverImage = unblurP
                                    }
                                    if !self.homeNotes.contains( where: { $0.id == solution.id } ) {
                                        self.homeNotes.append(solution)
                                        self.homeNotes.sort(by: { $0.weight > $1.weight })
                                    }
                                }
                            }
                            dispatch.leave()
                        })
                    }
                }
                dispatch.notify(queue: DispatchQueue.main) {
                    completion("fetch completed")
                }
            } else {
                completion("zero")
            }
        })
    }
    
    func grabSolutionsByRecent(fixedWeight: Bool, limit: Int, completion: @escaping (String) -> Void) {
        let ref = Database.database().reference().child("solutions")
        let totalQuery = 25*limit
        ref.queryLimited(toLast: UInt(totalQuery)).queryOrdered(byChild: "time").observeSingleEvent(of: .value, with: {(snapshot) in
            if let dataReturned = snapshot.value as? [String: AnyObject] {
                for (_,each) in dataReturned {
                    if let title = each["solTitle"] as? String, let time = each["time"] as? Int, let tags = each["solTags"] as? [String: String], let price = each["price"] as? Double, let id = each["solId"] as? String {
                        
                        let solution = solutionObject()
                        solution.id = id
                        solution.titleString = title
                        solution.time = time
                        solution.price = price
                        if fixedWeight == true {
                            solution.weight = -self.timesRan
                        } else if !self.showLicPrompt {
                            solution.weight = Int.random(in: 10..<20)
                        } else {
                            if let weight = each["weight"] as? Int {
                                solution.weight = weight
                            }
                        }
                        solution.tags = tags.values.map({$0})
                        solution.dislikes = [String]()
                        solution.likes = [String]()
                        if let coverImage = each["blurredImages"] as? [String: String] {
                            solution.coverImage = coverImage.values.map({$0})[0]
                        } else {
                            if let coverTag = each["coverTag"] as? String {
                                let randomInt = Int.random(in: 0..<10)
                                let string = "scan\(coverTag)\(randomInt)"
                                solution.coverImage = string
                            } else {
                                let randomInt = Int.random(in: 0..<10)
                                solution.coverImage = "scan\(randomInt)"
                            }
                        }
                        if let likes = each["likes"] as? [String: String]{
                            solution.likes = likes.values.map({$0})
                        }
                        if let dislikes = each["dislikes"] as? [String: String] {
                            solution.dislikes = dislikes.values.map({$0})
                        }
                        if solution.dislikes.count == 1 && solution.likes.count == 0 {
                            solution.percentLike = 0
                        } else if solution.dislikes.count >= 1 && solution.likes.count >= 1 {
                            let total:Float = Float(solution.dislikes.count + solution.likes.count)
                            let likesi:Float = Float(solution.likes.count)
                            //CGRect(x: shawdowView1.frame.width - 150, y: 0, width: 140, height: 8)
                            let ratio:Float = Float(likesi / total)
                            solution.percentLike = Int(ratio * 100)
                        } else {
                            solution.percentLike = 100
                        }
                        let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                        let timer = timeStamp - time
                        if timer <= 59 {
                            solution.timeString = "\(timer) sec ago"
                        }
                        if timer > 59 && timer < 3600 {
                            let minuters = timer / 60
                            solution.timeString = "\(minuters) mins ago"
                            if minuters == 1 {
                                solution.timeString = "\(minuters) min ago"
                            }
                        }
                        if timer > 59 && timer >= 3600 && timer < 86400 {
                            let hours = timer / 3600
                            if hours == 1 {
                                solution.timeString = "\(hours) hr ago"
                            } else {
                                solution.timeString = "\(hours) hrs ago"
                            }
                        }
                        if timer > 86400 {
                            let days = timer / 86400
                            solution.timeString = "\(days) days ago"
                            if days == 1 {
                                solution.timeString = "\(days) day ago"
                            }
                        }
                        if timer > 2592000 {
                            let months = timer/2592000
                            solution.timeString = "\(months) months ago"
                            if months == 1 {
                                solution.timeString = "\(months) month ago"
                            }
                        }
                        if let unblurP = each["unblurPreview"] as? String {
                            solution.coverImage = unblurP
                        }
                        if !self.homeNotes.contains( where: { $0.id == solution.id } ) {
                            self.homeNotes.append(solution)
                            self.homeNotes.sort(by: { $0.weight > $1.weight })
                        }
                    }
                }
            }
            completion("done")
        })
            
        
    }
    
    func getSolutionsFromTag(tag: String, completion: @escaping (String) -> Void) {
        var maxDrop = 2
        let defaults = UserDefaults.standard
        let purchasedSave = defaults.stringArray(forKey: "purchased") ?? [String]()
        let ref = Database.database().reference().child("searchKeys")
        let ref2 = Database.database().reference().child("solutions")
        ref.child(tag).queryLimited(toLast: 35).observeSingleEvent(of: .value, with: { snapshot in
            if let data = snapshot.value as? [String: String] {
                let dispatch = DispatchGroup()
                for (solid,_) in data {
                    if self.homeNotes.contains( where: { $0.id == solid } ) {
                        if let firstIndex = self.homeNotes.firstIndex(where: { $0.id == solid }) {
                            self.homeNotes[firstIndex].weight+=3
                        }
                    } else {
                        dispatch.enter()
                        ref2.child(solid).observeSingleEvent(of: .value, with: { snap in
                            let vals = snap.value as? [String: AnyObject]
                            if let title = vals?["solTitle"] as? String, let tags = vals?["solTags"] as? [String: String], let coverImages = vals?["blurredImages"] as? [String: String], let finalCreatorId = vals?["creatorId"] as? String, let price = vals?["price"] as? Double, let time = vals?["time"] as? Int, let solId = vals?["solId"] as? String {
                                if maxDrop > 0 && purchasedSave.contains(solId) {
                                    maxDrop -= 1
                                } else {
                                    
                                    let solution = solutionObject()
                                    solution.id = solId
                                    solution.titleString = title
                                    solution.time = time
                                    solution.price = price
                                    if let solWeight = vals?["weight"] as? Int {
                                        solution.weight = solWeight
                                    } else {
                                        solution.weight = Int.random(in: 10..<20)
                                    }
                                    solution.tags = tags.values.map({$0})
                                    solution.creatorId = finalCreatorId
                                    solution.coverImage = coverImages.values.map({$0})[0]
                                    
                                    if let likes = vals?["likes"] as? [String: String], let dislikes = vals?["dislikes"] as? [String: String] {
                                        solution.likes = likes.values.map({$0})
                                        solution.dislikes = dislikes.values.map({$0})
                                        if dislikes.count == 1 {
                                            solution.percentLike = 100
                                        } else if dislikes.count > 1 {
                                            let total:Float = Float(dislikes.count-1 + likes.count-1)
                                            let likesi:Float = Float(likes.count-1)
                                            //CGRect(x: shawdowView1.frame.width - 150, y: 0, width: 140, height: 8)
                                            let ratio:Float = Float(likesi / total)
                                            solution.percentLike = Int(ratio * 100)
                                        }
                                    } else {
                                        solution.likes = [""]
                                        solution.dislikes = [""]
                                        solution.percentLike = 100
                                    }
                                    let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                                    let timer = timeStamp - time
                                    if timer <= 59 {
                                        solution.timeString = "\(timer) sec ago"
                                    }
                                    if timer > 59 && timer < 3600 {
                                        let minuters = timer / 60
                                        solution.timeString = "\(minuters) mins ago"
                                        if minuters == 1 {
                                            solution.timeString = "\(minuters) min ago"
                                        }
                                    }
                                    if timer > 59 && timer >= 3600 && timer < 86400 {
                                        let hours = timer / 3600
                                        if hours == 1 {
                                            solution.timeString = "\(hours) hr ago"
                                        } else {
                                            solution.timeString = "\(hours) hrs ago"
                                        }
                                    }
                                    if timer > 86400 {
                                        let days = timer / 86400
                                        solution.timeString = "\(days) days ago"
                                        if days == 1 {
                                            solution.timeString = "\(days) day ago"
                                        }
                                    }
                                    if timer > 2592000 {
                                        let months = timer/2592000
                                        solution.timeString = "\(months) months ago"
                                        if months == 1 {
                                            solution.timeString = "\(months) month ago"
                                        }
                                    }
                                    if let unblurP = vals?["unblurPreview"] as? String {
                                        solution.coverImage = unblurP
                                    }
                                    if !self.homeNotes.contains( where: { $0.id == solution.id } ) {
                                        self.homeNotes.append(solution)
                                        self.homeNotes.sort(by: { $0.weight > $1.weight })
                                    }
                                }
                            }
                            dispatch.leave()
                        })
                    }
                }
                dispatch.notify(queue: DispatchQueue.main) {
                    completion("fetch2 completed")
                }
                    
            } else {
                completion("failed")
            }
        })
    }
    
    
    
    func randomColor (number: Int) -> UIColor {
        // there are 7
        if number % 2 == 1 {
            return UIColor(red: 0, green: 0.4667, blue: 0.7373, alpha: 1.0)
        } else {
            return UIColor(red: 0, green: 0.5569, blue: 0.3333, alpha: 1.0)
        }
        
    }
  
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        // UITableView only moves in one direction, y axis
        
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 10.0 {
            print("dragged refresh")
            if scrollView == collectionView {
                if self.timesRan < 6 {
                    if self.working == false {
                        self.working = true
                        let grabCount = 10*timesRan
                        self.grabSolutionsByRecent(fixedWeight: true, limit: timesRan, completion: { (outcome) -> Void in
                            print("called data sequence")
                            if outcome != "" && self.homeNotes.count > self.currentItemCount {
                                self.collectionView.reloadData()
                                self.timesRan+=1
                                self.working = false
                                print("all we could get")
                            }
                        })
                    }
                }
            }
        }
    }
    
    func checkForInbox() {
        let ref = Database.database().reference()
        if let uid = Auth.auth().currentUser?.uid {
            ref.child("users").child(uid).child("inboxUnseen").observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    self.tabBarController?.tabBar.items?[1].badgeValue = "1"
                } else {
                    self.tabBarController?.tabBar.items?[1].badgeValue = nil
                }
            })
        }
    }

    func goToSearch() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "searchVC") as? SearchViewController {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "solutionVC") as? SolutionViewController {
            vc.solutionId = homeNotes[indexPath.item].id
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func tutorialMode () {
        button1.frame = CGRect(x: 15, y: self.view.bounds.height - 262, width: self.view.bounds.width-30, height: 50)
//        button1.translatesAutoresizingMaskIntoConstraints = false
//         NSLayoutConstraint.activate([
//            button1.heightAnchor.constraint(equalToConstant: 50),
//            button1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
//            button1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
//            button1.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 262)
//         ])
        button1.titleLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        button1.setTitle("Take Tutorial", for: .normal)
        print("taked")
        button1.backgroundColor = .black
        button1.clipsToBounds = true
        button1.layer.cornerRadius = 6.0
        button1.titleLabel?.textColor = .white
        button1.tag = 0
        button1.addTarget(self, action: #selector(self.takeTutorial(sender:)), for: .touchUpInside)
        button2.frame = CGRect(x: 15, y: self.view.bounds.height - 205, width: self.view.frame.width-30, height: 50)
        button2.backgroundColor = .gray
         button2.titleLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        button2.setTitle("Skip Tutorial", for: .normal)
        button2.layer.cornerRadius = 6.0
        button2.clipsToBounds = true
        button2.titleLabel?.textColor = .white
        button2.addTarget(self, action: #selector(self.skipTutorial), for: .touchUpInside)
        self.nextBut.addTarget(self, action: #selector(self.takeTutorial(sender:)), for: .touchUpInside)
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                print("iPhone 5 or 5S or 5C")
                
            case 1334:
                print("iPhone 6/6S/7/8")
                
            case 1920, 2208:
                print("iPhone 6+/6S+/7+/8+")
                
            case 2436:
                print("iPhone X, XS")
               button1.frame = CGRect(x: 15, y: self.view.frame.height - 255, width: self.view.frame.width-30, height: 50)
                button2.frame = CGRect(x: 15, y: self.view.frame.height - 195, width: self.view.frame.width-30, height: 50)
            case 2532, 2556:
                button1.frame = CGRect(x: 15, y: self.view.frame.height - 255, width: self.view.frame.width-30, height: 50)
                 button2.frame = CGRect(x: 15, y: self.view.frame.height - 195, width: self.view.frame.width-30, height: 50)
            case 2688:
                print("iPhone XS Max")
                button1.frame = CGRect(x: 15, y: self.view.frame.height - 255, width: self.view.frame.width-30, height: 50)
                button2.frame = CGRect(x: 15, y: self.view.frame.height - 195, width: self.view.frame.width-30, height: 50)
            case 2778, 2796:
                button1.frame = CGRect(x: 15, y: self.view.frame.height - 255, width: self.view.frame.width-30, height: 50)
                button2.frame = CGRect(x: 15, y: self.view.frame.height - 195, width: self.view.frame.width-30, height: 50)
            case 1792:
                print("iPhone XR")
                button1.frame = CGRect(x: 15, y: self.view.frame.height - 255, width: self.view.frame.width-30, height: 50)
                button2.frame = CGRect(x: 15, y: self.view.frame.height - 195, width: self.view.frame.width-30, height: 50)
            default:
                button1.frame = CGRect(x: 15, y: self.view.frame.height - 255, width: self.view.frame.width-30, height: 50)
                 button2.frame = CGRect(x: 15, y: self.view.frame.height - 195, width: self.view.frame.width-30, height: 50)
            }
        } else if UIDevice().userInterfaceIdiom == .pad {
            button1.frame = CGRect(x: 15, y: self.view.frame.height - 255, width: self.view.frame.width-30, height: 50)
            button2.frame = CGRect(x: 15, y: self.view.frame.height - 195, width: self.view.frame.width-30, height: 50)
        }
        self.view.addSubview(button2)
        self.view.addSubview(button1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 25.0, execute: {
            self.button1.removeFromSuperview()
            self.button2.removeFromSuperview()
        })
        
    }
    let tutView = UIView()
    let tutTextTitle = UILabel()
    let tutText = UILabel()
    let nextBut = UIButton()
    @objc func skipTutorial () {
        button2.removeFromSuperview()
        button1.removeFromSuperview()
        tutView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        tutView.layer.cornerRadius = 8
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                print("iPhone 5 or 5S or 5C")
                 tutView.frame = CGRect(x: 5, y: self.view.frame.height - 300, width: self.view.frame.width - 10, height: 250)
            case 1334:
                print("iPhone 6/6S/7/8")
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 300, width: self.view.frame.width - 10, height: 250)
            case 1920, 2208:
                print("iPhone 6+/6S+/7+/8+")
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 310, width: self.view.frame.width - 10, height: 250)
            case 2436:
                print("iPhone X, XS")
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 400, width: self.view.frame.width - 10, height: 250)
            case 2532, 2556:
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 400, width: self.view.frame.width - 10, height: 250)
            case 2688:
                print("iPhone XS Max")
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 400, width: self.view.frame.width - 10, height: 250)
            case 2778, 2796:
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 400, width: self.view.frame.width - 10, height: 250)
            case 1792:
                print("iPhone XR")
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 400, width: self.view.frame.width - 10, height: 250)
            default:
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 400, width: self.view.frame.width - 10, height: 250)
            }
        } else if UIDevice().userInterfaceIdiom == .pad {
            tutView.frame = CGRect(x: 5, y: self.view.frame.height - 650, width: self.view.frame.width - 10, height: 500)
        }
        
        tutTextTitle.frame = CGRect(x: 10, y: 20, width: tutView.frame.width - 20, height: 28)
        tutText.frame = CGRect(x: 10, y: 38, width: tutView.frame.width - 20, height: tutView.frame.height - 60)
        tutText.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        tutText.textColor = .white
        tutTextTitle.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        tutTextTitle.textColor = .white
        tutText.textAlignment = .center
        tutTextTitle.textAlignment = .center
        tutText.text = "BidNote is a platform that rewards students for helping other students learn. Plagiarized material including tutoring, lessons, hw help, etc will not be allowed on the application."
        tutTextTitle.text = "One More Thing!"
        tutText.numberOfLines = 0
        nextBut.frame = CGRect(x: 50, y: tutView.frame.height - 50, width: tutView.frame.width - 100, height: 38)
        nextBut.backgroundColor = .black
        nextBut.setTitleColor(.white, for: .normal)
        nextBut.setTitle("Done", for: .normal)
        nextBut.layer.cornerRadius = 6.0
        nextBut.addTarget(self, action: #selector(endDecline), for: .touchUpInside)
        tutView.addSubview(tutText)
        tutView.addSubview(tutTextTitle)
        tutView.addSubview(nextBut)
        self.view.addSubview(tutView)
        UserDefaults.standard.set("showTutorial", forKey: "showTutorial")
    }
    @objc func endDecline() {
        tutView.removeFromSuperview()
    }
    @objc func takeTutorial (sender:UIButton) {
        self.button1.removeFromSuperview()
        self.button2.removeFromSuperview()
        tutView.backgroundColor = UIColor(red: 0.2353, green: 0.2353, blue: 0.2353, alpha: 1.0)
        tutView.layer.cornerRadius = 8
        if sender.tag == 0 {
            if UIDevice().userInterfaceIdiom == .phone {
                switch UIScreen.main.nativeBounds.height {
                case 1136:
                    print("iPhone 5 or 5S or 5C")
                     tutView.frame = CGRect(x: 5, y: self.view.frame.height - 310, width: self.view.frame.width - 10, height: 220)
                case 1334:
                    print("iPhone 6/6S/7/8")
                     tutView.frame = CGRect(x: 5, y: self.view.frame.height - 310, width: self.view.frame.width - 10, height: 220)
                case 1920, 2208:
                    print("iPhone 6+/6S+/7+/8+")
                    tutView.frame = CGRect(x: 5, y: self.view.frame.height - 320, width: self.view.frame.width - 10, height: 220)
                case 2436:
                    print("iPhone X, XS")
                    tutView.frame = CGRect(x: 5, y: self.view.frame.height - 410, width: self.view.frame.width - 10, height: 220)
                case 2532, 2556:
                    tutView.frame = CGRect(x: 5, y: self.view.frame.height - 410, width: self.view.frame.width - 10, height: 220)
                case 2688:
                    print("iPhone XS Max")
                    tutView.frame = CGRect(x: 5, y: self.view.frame.height - 410, width: self.view.frame.width - 10, height: 220)
                case 2778, 2796:
                    tutView.frame = CGRect(x: 5, y: self.view.frame.height - 410, width: self.view.frame.width - 10, height: 220)
                case 1792:
                    print("iPhone XR")
                    tutView.frame = CGRect(x: 5, y: self.view.frame.height - 410, width: self.view.frame.width - 10, height: 220)
                default:
                    tutView.frame = CGRect(x: 5, y: self.view.frame.height - 410, width: self.view.frame.width - 10, height: 220)
                }
            } else if UIDevice().userInterfaceIdiom == .pad {
                tutView.frame = CGRect(x: 5, y: self.view.frame.height - 710, width: self.view.frame.width - 10, height: 220)
            }
            tutTextTitle.frame = CGRect(x: 10, y: 20, width: tutView.frame.width - 20, height: 28)
            tutText.frame = CGRect(x: 10, y: 38, width: tutView.frame.width - 20, height: tutView.frame.height - 60)
            tutText.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
            tutText.textColor = .white
            tutTextTitle.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
            tutTextTitle.textColor = .white
            tutText.textAlignment = .center
            tutTextTitle.textAlignment = .center
            tutText.text = "Tutoring, lessons, flashcards, notes, homework help, test prep, and so much more. Create your own material and then click the button below to offer it to other students!"
            tutTextTitle.text = "Create and Offer Material"
            tutText.numberOfLines = 0
            nextBut.frame = CGRect(x: 50, y: tutView.frame.height - 50, width: tutView.frame.width - 100, height: 38)
            nextBut.backgroundColor = .black
            nextBut.setTitleColor(.white, for: .normal)
            nextBut.setTitle("Next", for: .normal)
            nextBut.layer.cornerRadius = 6.0
            tutView.addSubview(tutText)
            tutView.addSubview(tutTextTitle)
            tutView.addSubview(nextBut)
            self.view.addSubview(tutView)
            self.nextBut.tag = 1
            UserDefaults.standard.set("showTutorial", forKey: "showTutorial")
        }
        if sender.tag == 3 {
           tutView.removeFromSuperview()
        }
        if sender.tag == 2 {
            if UIDevice().userInterfaceIdiom == .phone {
                switch UIScreen.main.nativeBounds.height {
                case 1136:
                    print("iPhone 5 or 5S or 5C")
                    tutView.frame = CGRect(x: 5, y: 310, width: self.view.frame.width - 10, height: 220)
                case 1334:
                    print("iPhone 6/6S/7/8")
                    tutView.frame = CGRect(x: 5, y: 310, width: self.view.frame.width - 10, height: 220)
                case 1920, 2208:
                    print("iPhone 6+/6S+/7+/8+")
                    tutView.frame = CGRect(x: 5, y: 310, width: self.view.frame.width - 10, height: 220)
                case 2436:
                    print("iPhone X, XS")
                    tutView.frame = CGRect(x: 5, y: 330, width: self.view.frame.width - 10, height: 220)
                case 2532, 2556:
                    tutView.frame = CGRect(x: 5, y: 330, width: self.view.frame.width - 10, height: 220)
                case 2688:
                    print("iPhone XS Max")
                    tutView.frame = CGRect(x: 5, y: 330, width: self.view.frame.width - 10, height: 220)
                case 2778, 2796:
                    tutView.frame = CGRect(x: 5, y: 330, width: self.view.frame.width - 10, height: 220)
                case 1792:
                    print("iPhone XR")
                    tutView.frame = CGRect(x: 5, y: 330, width: self.view.frame.width - 10, height: 220)
                default:
                    tutView.frame = CGRect(x: 5, y: 330, width: self.view.frame.width - 10, height: 220)
                }
            } else if UIDevice().userInterfaceIdiom == .pad {
                tutView.frame = CGRect(x: 5, y: 330, width: self.view.frame.width - 10, height: 220)
            }
            tutText.text = "BidNote is a platform that rewards students for helping other students learn. Plagiarized material including tutoring, lessons, hw help, etc will not be allowed on the application."
            tutTextTitle.text = "One More Thing"
            nextBut.setTitle("Done", for: .normal)
            nextBut.tag = 3
        }
        if sender.tag == 1 {
            if UIDevice().userInterfaceIdiom == .phone {
                switch UIScreen.main.nativeBounds.height {
                case 1136:
                    print("iPhone 5 or 5S or 5C")
                    tutView.frame = CGRect(x: 5, y: 210, width: self.view.frame.width - 10, height: 220)
                case 1334:
                    print("iPhone 6/6S/7/8")
                    tutView.frame = CGRect(x: 5, y: 210, width: self.view.frame.width - 10, height: 220)
                case 1920, 2208:
                    print("iPhone 6+/6S+/7+/8+")
                    tutView.frame = CGRect(x: 5, y: 220, width: self.view.frame.width - 10, height: 220)
                case 2436:
                    print("iPhone X, XS")
                    tutView.frame = CGRect(x: 5, y: 230, width: self.view.frame.width - 10, height: 220)
                case 2532, 2556:
                    tutView.frame = CGRect(x: 5, y: 230, width: self.view.frame.width - 10, height: 220)
                case 2688:
                    print("iPhone XS Max")
                    tutView.frame = CGRect(x: 5, y: 230, width: self.view.frame.width - 10, height: 220)
                case 2778, 2796:
                    tutView.frame = CGRect(x: 5, y: 230, width: self.view.frame.width - 10, height: 220)
                case 1792:
                    print("iPhone XR")
                    tutView.frame = CGRect(x: 5, y: 230, width: self.view.frame.width - 10, height: 220)
                default:
                    print("Unknown")
                    tutView.frame = CGRect(x: 5, y: 230, width: self.view.frame.width - 10, height: 220)
                }
            } else if UIDevice().userInterfaceIdiom == .pad {
                tutView.frame = CGRect(x: 5, y: 230, width: self.view.frame.width - 10, height: 220)
            }
            tutText.text = "Find all of the educational help you need. Search for courses, schools, and test preps to start learning."
            tutTextTitle.text = "Find Any Material"
            nextBut.tag = 2
        }
    }
    
    
    

}

class mainCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var backView: UIView!
    
    @IBOutlet weak var imageView1: UIImageView!
    
   // @IBOutlet weak var colorView: UIView!
    
    @IBOutlet weak var imageView2: UIImageView!
    
    @IBOutlet weak var titleCellLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var happyImage: UIImageView!
    
    @IBOutlet weak var percentLikedLabel: UILabel!
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleCellLabel.numberOfLines = 4
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                print("iPhone 5 or 5S or 5C")
                layoutScreen(type: 2, width: contentView.frame.width, height: contentView.frame.height)
            case 1334:
                print("iPhone 6/6S/7/8")
                layoutScreen(type: 2, width: contentView.frame.width, height: contentView.frame.height)
            case 1920, 2208:
                print("iPhone 6+/6S+/7+/8+")
                layoutScreen(type: 2, width: contentView.frame.width, height: contentView.frame.height)
            case 2436:
                print("iPhone X, XS")
                layoutScreen(type: 7, width: contentView.frame.width, height: contentView.frame.height)
            case 2532, 2556:
                layoutScreen(type: 5, width: contentView.frame.width, height: contentView.frame.height)
                print("iPhone 12 Pro")
            case 2688:
                layoutScreen(type: 5, width: contentView.frame.width, height: contentView.frame.height)
                print("iPhone XS Max")
            case 2778, 2796:
                layoutScreen(type: 3, width: contentView.frame.width, height: contentView.frame.height)
                print("iPhone 13 Pro Max")
            case 1792:
                print("iPhone XR")
                layoutScreen(type: 4, width: contentView.frame.width, height: contentView.frame.height)
            default:
                layoutScreen(type: 2, width: contentView.frame.width, height: contentView.frame.height)
                print("Unknown")
            }
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                layoutScreen(type: 6, width: contentView.frame.width, height: contentView.frame.height)
            }
        }
    }
    
    func layoutScreen(type: Int, width: Double, height: Double) {
        backView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        imageView1.frame = CGRect(x: 15, y: 5, width: 90, height: 90)
        imageView2.frame = CGRect(x: 20, y: 5, width: 90, height: 90)
        priceLabel.frame = CGRect(x: 20, y: contentView.frame.height - 40, width: 85, height: 38)
        tagsLabel.frame = CGRect(x: 120, y: contentView.frame.height - 40, width: contentView.frame.width - 130, height: 28)
        timeLabel.frame = CGRect(x: 120, y: contentView.frame.height - 60, width: contentView.frame.width - 130, height: 25)
        titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        titleCellLabel.textAlignment = .left
        titleCellLabel.textColor = .white
        imageView1.layer.borderWidth = 1
        imageView1.layer.borderColor = UIColor.clear.cgColor
        imageView2.layer.cornerRadius = 3.0
        priceLabel.layer.cornerRadius = 3.0
        priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 11)
        tagsLabel.font = UIFont(name: "HelveticaNeue", size: 14)
        tagsLabel.textColor = UIColor(red: 0.9765, green: 0.8, blue: 0, alpha: 1.0)
        priceLabel.clipsToBounds = true
        priceLabel.textAlignment = .center
        happyImage.isHidden = true
        percentLikedLabel.isHidden = true
        tagsLabel.textAlignment = .left
        titleCellLabel.numberOfLines = 3
        imageView1.layer.cornerRadius = 3.0
        imageView1.clipsToBounds = true
        imageView2.layer.cornerRadius = 3.0
        imageView2.clipsToBounds = true
        // UIColor(red: 0.1059, green: 0.9098, blue: 0, alpha: 1.0)
        if type == 1 {
            titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
            titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            titleCellLabel.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: 10).isActive = true
            titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
            titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -15).isActive = true
//
        } else if type == 2 {
            titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
            titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            titleCellLabel.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: 10).isActive = true
            titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
            titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -15).isActive = true
        } else if type == 3 {
            tagsLabel.frame = CGRect(x: 155, y: contentView.frame.height - 40, width: contentView.frame.width - 160, height: 28)
            timeLabel.frame = CGRect(x: 155, y: contentView.frame.height - 65, width: contentView.frame.width - 140, height: 25)
            titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
            titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            titleCellLabel.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: 10).isActive = true
            titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
            titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -15).isActive = true
            imageView1.frame = CGRect(x: 15, y: 5, width: 125, height: 125)
            imageView2.frame = CGRect(x: 20, y: 5, width: 125, height: 125)
            priceLabel.frame = CGRect(x: 20, y: contentView.frame.height - 40, width: 120, height: 35)
            titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 19)
            priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 14)
            timeLabel.font = UIFont(name: "HelveticaNeue", size: 16)
            tagsLabel.font = UIFont(name: "HelveticaNeue", size: 17)
           
        } else if type == 4 {
            tagsLabel.frame = CGRect(x: 140, y: contentView.frame.height - 40, width: contentView.frame.width - 145, height: 28)
            timeLabel.frame = CGRect(x: 140, y: contentView.frame.height - 65, width: contentView.frame.width - 140, height: 25)
            titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
            titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            titleCellLabel.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: 10).isActive = true
            titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
            titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -15).isActive = true
            imageView1.frame = CGRect(x: 15, y: 5, width: 110, height: 110)
            imageView2.frame = CGRect(x: 20, y: 5, width: 110, height: 110)
            priceLabel.frame = CGRect(x: 20, y: contentView.frame.height - 40, width: 105, height: 35)
            titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
            priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 12)
            timeLabel.font = UIFont(name: "HelveticaNeue", size: 14)
            tagsLabel.font = UIFont(name: "HelveticaNeue", size: 16)
        } else if type == 5 {
            tagsLabel.frame = CGRect(x: 140, y: contentView.frame.height - 40, width: contentView.frame.width - 145, height: 28)
            timeLabel.frame = CGRect(x: 140, y: contentView.frame.height - 65, width: contentView.frame.width - 140, height: 25)
            titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
            titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            titleCellLabel.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: 10).isActive = true
            titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
            titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -15).isActive = true
            imageView1.frame = CGRect(x: 15, y: 5, width: 110, height: 110)
            imageView2.frame = CGRect(x: 20, y: 5, width: 110, height: 110)
            priceLabel.frame = CGRect(x: 20, y: contentView.frame.height - 40, width: 105, height: 35)
            titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
            priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 12)
            timeLabel.font = UIFont(name: "HelveticaNeue", size: 14)
            tagsLabel.font = UIFont(name: "HelveticaNeue", size: 15)
        } else if type == 6 {
            //ipad only
            tagsLabel.frame = CGRect(x: 195, y: contentView.frame.height - 40, width: contentView.frame.width - 200, height: 28)
            timeLabel.frame = CGRect(x: 195, y: contentView.frame.height - 65, width: contentView.frame.width - 200, height: 25)
            titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
            titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            titleCellLabel.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: 10).isActive = true
            titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50).isActive = true
            titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -15).isActive = true
            imageView1.frame = CGRect(x: 15, y: 5, width: 165, height: 165)
            imageView2.frame = CGRect(x: 20, y: 5, width: 165, height: 165)
            priceLabel.frame = CGRect(x: 20, y: contentView.frame.height - 40, width: 160, height: 35)
            titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 22)
            priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
            timeLabel.font = UIFont(name: "HelveticaNeue", size: 18)
            tagsLabel.font = UIFont(name: "HelveticaNeue", size: 19)
        } else if type == 7 {
            //iphone 11pro, 10s, 12pro
            tagsLabel.frame = CGRect(x: 130, y: contentView.frame.height - 40, width: contentView.frame.width - 135, height: 28)
            timeLabel.frame = CGRect(x: 130, y: contentView.frame.height - 65, width: contentView.frame.width - 135, height: 25)
            titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
            titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            titleCellLabel.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: 10).isActive = true
            titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
            titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -15).isActive = true
            imageView1.frame = CGRect(x: 15, y: 5, width: 100, height: 100)
            imageView2.frame = CGRect(x: 20, y: 5, width: 100, height: 100)
            priceLabel.frame = CGRect(x: 20, y: contentView.frame.height - 40, width: 95, height: 35)
            titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
            priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 11)
            timeLabel.font = UIFont(name: "HelveticaNeue", size: 14)
            tagsLabel.font = UIFont(name: "HelveticaNeue", size: 15)
            
        } else if type == 8 {

        } else if type == 9 {

        }

    }
    
}
extension CALayer {

  func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {

    let border = CALayer()

    switch edge {
    case UIRectEdge.top:
        border.frame = CGRect(x: 0, y: 0, width: frame.width, height: thickness)

    case UIRectEdge.bottom:
        border.frame = CGRect(x:0, y: frame.height - thickness, width: frame.width, height:thickness)

    case UIRectEdge.left:
        border.frame = CGRect(x:0, y:0, width: thickness, height: frame.height)

    case UIRectEdge.right:
        border.frame = CGRect(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)

    default: do {}
    }

    border.backgroundColor = color.cgColor

    addSublayer(border)
 }
}
