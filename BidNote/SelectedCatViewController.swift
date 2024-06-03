//
//  SelectedCatViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/22/23.
//

import UIKit
import Firebase
import Kingfisher

class SelectedCatViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var notes = [solutionObject]()
    var catId: String?
    var userId: String?
    var catName: String?
    var timesRan = 2
    let viewy = UIView()
    var working = false
    var dontShowAuthorsInNextSolutionVC: Bool?
    var labli = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        guard let catId = self.catId else {
            self.navigationItem.title = "More By The Author"
            if let author = self.userId {
                self.getSolutionsByAuthor()
            }
            return
        }
        if let catId = self.catId {
            let defaults = UserDefaults.standard
            let myarray = defaults.stringArray(forKey: "savedCats") ?? [String]()
            if myarray.contains(catId) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Un-Follow", style: .plain, target: self, action: #selector(unfollowTapped))
            } else {
                let rightBarFollowButton = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
                rightBarFollowButton.backgroundColor = .systemBlue
                rightBarFollowButton.setTitle("Follow", for: .normal)
                rightBarFollowButton.layer.cornerRadius = 10.0
                rightBarFollowButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
                rightBarFollowButton.titleLabel?.textColor = .white
                rightBarFollowButton.addTarget(self, action: #selector(self.followTapped), for: .touchUpInside)
                let rightBarButton = UIBarButtonItem(customView: rightBarFollowButton)
                        navigationItem.rightBarButtonItem = rightBarButton
            }
            self.getNotesOfCat(content: catId,limit: 10, completion: { (outcome) -> Void in
                if outcome != "" {
                    
                    self.collectionView.reloadData()
                    if self.notes.count == 0 {
                        self.viewy.backgroundColor = .systemBlue
                        self.viewy.layer.cornerRadius = 8
                        self.viewy.clipsToBounds = true
                        self.viewy.frame = CGRect(x: 25, y: self.view.frame.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                        self.labli = UILabel(frame: CGRect(x: 10, y: 10, width: self.viewy.frame.width - 20, height: 40))
                        self.labli.textColor = .white
                        self.labli.textAlignment = .center
                        self.labli.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
                        self.labli.text = "No Material Found!"
                        self.viewy.addSubview(self.labli)
                        self.view.addSubview(self.viewy)
                    }
                }
            })
        }
        if let catName = self.catName {
            self.navigationItem.title = catName
        }
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Do any additional setup after loading the view.
    }
    
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.collectionView.reloadData()
                self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                self.labli.frame = CGRect(x: 10, y: 10, width: self.viewy.bounds.width - 20, height: 40)
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.collectionView.reloadData()
                    self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                    self.labli.frame = CGRect(x: 10, y: 10, width: self.viewy.bounds.width - 20, height: 40)
                })
            }
        }
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    
    @objc func followTapped() {
        if let catId = self.catId, let catName = self.catName {
            let defaults = UserDefaults.standard
            var myarray = defaults.stringArray(forKey: "savedCats") ?? [String]()
            myarray.append(catId)
            var namedArray = defaults.stringArray(forKey: "namedCats") ?? [String]()
            namedArray.append(catName)
            defaults.set(myarray, forKey: "savedCats")
            defaults.set(namedArray, forKey: "namedCats")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Un-Follow", style: .plain, target: self, action: #selector(unfollowTapped))
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2532, 2556:
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.52)
            case 1334:
                print("iPhone 6/6S/7/8")
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
            case 1920, 2208:
                print("iPhone 6+/6S+/7+/8+")
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
            case 2796:
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.73)
            case 2778:
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.75)
            case 2436:
                print("iPhone X, XS")
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
            default:
                print("Unknown")
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
            }
        } else if UIDevice().userInterfaceIdiom == .pad {
            if UIScreen.main.nativeBounds.height == 2732 {
                
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 3.5)
            }
            if  UIScreen.main.nativeBounds.height <= 2266 {
                
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.7)
            }
            if UIScreen.main.nativeBounds.width >= 1500 {
                return CGSize(width: collectionView.frame.width, height: view.frame.width / 3.8)
            }
            return CGSize(width: collectionView.frame.width, height: view.frame.width / 2.9)
        }
        return CGSize(width: collectionView.frame.width, height: view.frame.width / 3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let solid = notes[indexPath.row].id {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "solutionVC") as? SolutionViewController {
                vc.solutionId = solid
                if let dontShow = self.dontShowAuthorsInNextSolutionVC {
                    vc.dontShowAuthor = dontShow
                }
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func getSolutionsByAuthor() {
        let ref = Database.database().reference()
        if let authorId = self.userId {
            ref.child("users").child(authorId).child("approvedSolutions").observeSingleEvent(of: .value, with: { snap in
                if let data = snap.value as? [String: String] {
                    let array = Array(data.keys)
                    let dispatch = DispatchGroup()
                    for each in array {
                        dispatch.enter()
                        ref.child("solutions").child(each).observeSingleEvent(of: .value, with: { snapshot in
                            let vals = snapshot.value as? [String: AnyObject]
                            if let title = vals?["solTitle"] as? String, let tags = vals?["solTags"] as? [String: String], let coverImages = vals?["blurredImages"] as? [String: String], let finalCreatorId = vals?["creatorId"] as? String, let price = vals?["price"] as? Double, let time = vals?["time"] as? Int, let solId = vals?["solId"] as? String {
                                let solution = solutionObject()
                                solution.id = solId
                                solution.titleString = title
                                solution.time = time
                                solution.price = price
                                solution.weight = Int.random(in: 0..<10)
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
                                if solution.dislikes.count >= 1 && solution.likes.count == 0 {
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
                                    solution.timeString = "\(timer)s ago"
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
                                    solution.timeString = "\(days)days ago"
                                    if days == 1 {
                                        solution.timeString = "\(days)day ago"
                                    }
                                }
                                if timer > 2592000 {
                                    let months = timer/2592000
                                    solution.timeString = "\(months)months ago"
                                    if months == 1 {
                                        solution.timeString = "\(months)month ago"
                                    }
                                }
                                if let unblurP = vals?["unblurPreview"] as? String {
                                    solution.coverImage = unblurP
                                }
                                if !self.notes.contains( where: { $0.id == solution.id } ) {
                                    self.notes.append(solution)
                                    self.notes.sort(by: { $0.weight > $1.weight })
                                }
                            }
                            dispatch.leave()
                        })
                    }
                    dispatch.notify(queue: DispatchQueue.main) {
                        print("reloading")
                        self.collectionView.reloadData()
                    }
                }
            })
        }
    }
    
    @objc func unfollowTapped() {
        if let catId = self.catId, let namedCat = self.catName {
            let defaults = UserDefaults.standard
            var myarray = defaults.stringArray(forKey: "savedCats") ?? [String]()
            if let index = myarray.firstIndex(of: catId) {
                myarray.remove(at: index)
            }
            var mynamed = defaults.stringArray(forKey: "namedCats") ?? [String]()
            if let index = mynamed.firstIndex(of: namedCat) {
                mynamed.remove(at: index)
            }
            defaults.set(myarray, forKey: "savedCats")
            defaults.set(mynamed, forKey: "namedCats")
            let rightBarFollowButton = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
            rightBarFollowButton.backgroundColor = .systemBlue
            rightBarFollowButton.setTitle("Follow", for: .normal)
            rightBarFollowButton.layer.cornerRadius = 10.0
            rightBarFollowButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
            rightBarFollowButton.titleLabel?.textColor = .white
            rightBarFollowButton.addTarget(self, action: #selector(self.followTapped), for: .touchUpInside)
            let rightBarButton = UIBarButtonItem(customView: rightBarFollowButton)
                    navigationItem.rightBarButtonItem = rightBarButton
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCat1", for: indexPath) as! collectionViewCatCell
        cell.titleCellLabel.text = notes[indexPath.item].titleString
        cell.likesLabel.text = "\(notes[indexPath.item].percentLike ?? 0)% liked"
        if let price = notes[indexPath.item].price {
            if price.decimalCount() == 1 {
                cell.priceLabel.text = "Access: $\(price)0"
            } else if price.decimalCount() == 0 {
                cell.priceLabel.text = "Access: $\(price)0"
            } else if price.decimalCount() == 2 {
                cell.priceLabel.text = "Access: $\(price)"
            }
            if price == 0.0 {
                cell.priceLabel.text = "Access: Free"
            }
        }
        if let image = self.notes[indexPath.item].coverImage {
            if let url = URL(string: image) {
                cell.imageView.kf.setImage(with: url)
            }
        }
        if let percentLike = notes[indexPath.row].percentLike {
            if percentLike < 50 {
                cell.likesLabel.textColor = .systemRed
            } else if percentLike >= 50 && percentLike < 65 {
                cell.likesLabel.textColor = .systemYellow
            } else {
                cell.likesLabel.textColor = .systemGreen
            }
        }
        if let tags = notes[indexPath.item].tags {
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
            cell.tagsLabel.attributedText = tagsString.withBoldText(text: "Tags/Course Name:", font: UIFont(name: "HelveticaNeue", size: 16))
        }
        cell.timeLabel.text = notes[indexPath.item].timeString
        
        return cell
    }
    
    func getNotesOfCat(content: String, limit: Int, completion: @escaping (String) -> Void) {
        var maxDrop = 2
        let defaults = UserDefaults.standard
        let purchasedSave = defaults.stringArray(forKey: "purchased") ?? [String]()
        let ref = Database.database().reference().child("searchKeys")
        let ref2 = Database.database().reference().child("solutions")
        ref.child(content).queryLimited(toLast: UInt(limit)).observeSingleEvent(of: .value, with: { snapshot in
            if let data = snapshot.value as? [String: String] {
                let dispatch = DispatchGroup()
                for (solid,_) in data {
                    if self.notes.contains( where: { $0.id == solid } ) {
                        if let firstIndex = self.notes.firstIndex(where: { $0.id == solid }) {
                            self.notes[firstIndex].weight+=10
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
                                    solution.weight = Int.random(in: 0..<10)
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
                                    if solution.dislikes.count >= 1 && solution.likes.count == 0 {
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
                                        solution.timeString = "\(timer)s ago"
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
                                        solution.timeString = "\(days)days ago"
                                        if days == 1 {
                                            solution.timeString = "\(days)day ago"
                                        }
                                    }
                                    if timer > 2592000 {
                                        let months = timer/2592000
                                        solution.timeString = "\(months)months ago"
                                        if months == 1 {
                                            solution.timeString = "\(months)month ago"
                                        }
                                    }
                                    if !self.notes.contains( where: { $0.id == solution.id } ) {
                                        self.notes.append(solution)
                                        self.notes.sort(by: { $0.weight > $1.weight })
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
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        // UITableView only moves in one direction, y axis
        
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 10.0 {
            
            if scrollView == collectionView {
                if self.timesRan < 10 {
                    if self.working == false, let catId = self.catId {
                        self.working = true
                        let grabCount = 10*timesRan
                        if let pub = self.catId {
                            self.getNotesOfCat(content: catId,limit: grabCount, completion: { (outcome) -> Void in
                                if outcome != "" {
                                    self.collectionView.reloadData()
                                    self.timesRan+=1
                                    self.working = false
                                }
                            })
                        }
                    }
                }
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

class collectionViewCatCell: UICollectionViewCell {
    
    @IBOutlet weak var divideView: UIView!
    
    @IBOutlet weak var likesLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var likeImage: UIImageView!
    
    @IBOutlet weak var titleCellLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleCellLabel.numberOfLines = 3
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
                layoutScreen(type: 2, width: contentView.frame.width, height: contentView.frame.height)
            case 2532:
                layoutScreen(type: 4, width: contentView.frame.width, height: contentView.frame.height)
                print("iPhone 12 Pro")
            case 2688, 2556:
                layoutScreen(type: 4, width: contentView.frame.width, height: contentView.frame.height)
                print("iPhone XS Max")
            case 2796:
                layoutScreen(type: 4, width: contentView.frame.width, height: contentView.frame.height)
            case 2778:
                layoutScreen(type: 4, width: contentView.frame.width, height: contentView.frame.height)
                print("iPhone 13 Pro Max")
            case 1792:
                print("iPhone XR")
                layoutScreen(type: 2, width: contentView.frame.width, height: contentView.frame.height)
            default:
                layoutScreen(type: 2, width: contentView.frame.width, height: contentView.frame.height)
                print("Unknown")
            }
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                layoutScreen(type: 3, width: contentView.frame.width, height: contentView.frame.height)
            }
        }
    }
    
    func layoutScreen(type: Int, width: Double, height: Double) {
       // colorView.frame = CGRect(x: 0, y: 5, width: 15, height: contentView.frame.height - 5)
        imageView.frame = CGRect(x: 15, y: 5, width: 90, height: 90)
        //imageView2.frame = CGRect(x: 20, y: 5, width: 90, height: 90)
        titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        titleCellLabel.textAlignment = .left
        //titleCellLabel.numberOfLines = 0
        titleCellLabel.textColor = .white
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.clear.cgColor
        //imageView2.layer.cornerRadius = 3.0
        //priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
        priceLabel.textColor = .white
        priceLabel.backgroundColor = UIColor(red: 0.0314, green: 0.3765, blue: 0.1294, alpha: 1.0)
        priceLabel.textAlignment = .center
        likeImage.frame = CGRect(x: 15, y: contentView.frame.height - 30, width: 25, height: 25)
        likesLabel.frame = CGRect(x: 43, y: contentView.frame.height - 30, width: 80, height: 25)
        
        timeLabel.frame = CGRect(x: contentView.frame.width - 110, y: 5, width: 100, height: 25)
        priceLabel.layer.cornerRadius = 3.0
        priceLabel.clipsToBounds = true
        tagsLabel.textAlignment = .left
        //tagsLabel.textColor = .lightGray
        //frames
       // imageView1.layer.addBorder(edge: .right, color:  UIColor(red: 0.1882, green: 0.2667, blue: 0.1529, alpha: 1.0), thickness: 2)
        titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
        titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26).isActive = true
        titleCellLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10).isActive = true
        titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30).isActive = true
        titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -8).isActive = true
        priceLabel.frame = CGRect(x: 115, y: 6, width: 120, height: 28)
        priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 12)
        tagsLabel.sizeToFit()
        imageView.layer.cornerRadius = 3.0
        imageView.clipsToBounds = true
        //imageView2.layer.cornerRadius = 3.0
        //imageView2.clipsToBounds = true
        divideView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        // UIColor(red: 0.1059, green: 0.9098, blue: 0, alpha: 1.0)
        if type == 1 {
            tagsLabel.translatesAutoresizingMaskIntoConstraints = false
            tagsLabel.topAnchor.constraint(equalTo: titleCellLabel.bottomAnchor, constant: 5).isActive = true
            tagsLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        } else if type == 2 {
            priceLabel.frame = CGRect(x: 115, y: 5, width: 120, height: 25)
            timeLabel.frame = CGRect(x: contentView.frame.width - 110, y: 3, width: 100, height: 25)
            tagsLabel.translatesAutoresizingMaskIntoConstraints = false
            tagsLabel.topAnchor.constraint(equalTo: titleCellLabel.bottomAnchor, constant: 3).isActive = true
            tagsLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        } else if type == 3 {
            titleCellLabel.translatesAutoresizingMaskIntoConstraints = false
            titleCellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24).isActive = true
            titleCellLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10).isActive = true
            titleCellLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
            titleCellLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -8).isActive = true
            imageView.frame = CGRect(x: 15, y: 5, width: 230, height: 230)
            //imageView2.frame = CGRect(x: 20, y: 5, width: 230, height: 230)
            priceLabel.frame = CGRect(x: 270, y: 6, width: 120, height: 25)
            titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 30)
            priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 12)
            likesLabel.font = UIFont(name: "HelveticaNeue", size: 20)
            likeImage.frame = CGRect(x: 15, y: contentView.frame.height - 36, width: 32, height: 32)
            timeLabel.font = UIFont(name: "HelveticaNeue", size: 20)
            tagsLabel.font = UIFont(name: "HelveticaNeue", size: 20)
            tagsLabel.translatesAutoresizingMaskIntoConstraints = false
            likesLabel.frame = CGRect(x: 50, y: contentView.frame.height - 33, width: 200, height: 25)
            tagsLabel.topAnchor.constraint(equalTo: titleCellLabel.bottomAnchor, constant: 5).isActive = true
            tagsLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -13).isActive = true
            timeLabel.frame = CGRect(x: contentView.frame.width - 210, y: 5, width: 200, height: 25)
        } else if type == 4 {
            imageView.frame = CGRect(x: 15, y: 5, width: 110, height: 110)
            priceLabel.frame = CGRect(x: 135, y: 6, width: 120, height: 25)
            titleCellLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
            likesLabel.font = UIFont(name: "HelveticaNeue", size: 15)
            likeImage.frame = CGRect(x: 15, y: contentView.frame.height - 36, width: 32, height: 32)
            timeLabel.font = UIFont(name: "HelveticaNeue", size: 14)
            tagsLabel.font = UIFont(name: "HelveticaNeue", size: 16)
            tagsLabel.translatesAutoresizingMaskIntoConstraints = false
            likesLabel.frame = CGRect(x: 50, y: contentView.frame.height - 33, width: 80, height: 25)
            tagsLabel.topAnchor.constraint(equalTo: titleCellLabel.bottomAnchor, constant: 5).isActive = true
            tagsLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12).isActive = true
        } else if type == 5 {
            
        } else if type == 6 {
            
        } else if type == 7 {
            
        } else if type == 8 {
            
        } else if type == 9 {
            
        }
    }
    
}
