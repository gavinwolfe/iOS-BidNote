//
//  SearchViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/25/23.
//

import UIKit
import Firebase
import Kingfisher

class SearchViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource {
    
    
    
    @IBOutlet weak var tableView: UITableView!
    let searchController = UISearchController(searchResultsController: nil)
    @IBOutlet weak var collectionView: UICollectionView!
    private var numberOfItemsInRow = 2
    private var minimumSpacing = 16
    private var edgeInsetPadding = 20
    var searchTagResults = [String]()
    var filteredResults = [String]()
    
    var initialArray = [solutionObject]()
    var filteredArray = [solutionObject]()
    let searchBar = UISearchBar()
    let buttoner = UIButton()
    var searching = false
    let loading = UIActivityIndicatorView()
    override func viewDidLoad() {
        super.viewDidLoad()
        buttoner.addTarget(self, action: #selector(self.buttonSelected), for: .touchUpInside)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.dataSource = self
        tableView.isHidden = true
        collectionView.delegate = self
        collectionView.dataSource = self
        loading.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        loading.color = .systemBlue
        tableView.frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: 44)
        definesPresentationContext = true
        collectionView.frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: self.view.frame.height - 60)
        if UIDevice().userInterfaceIdiom == .pad {
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
                collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
                collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0)
            ])
        }
        tableView.tableHeaderView = searchController.searchBar
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .words
        //collectionView.backgroundColor = UIColor(red: 0.2200, green: 0.2200, blue: 0.2200, alpha: 1.0)
        initalGrab()
        searchBar.placeholder = "College Alg Practice..."
        collectionView.register(headerView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerView")
        getTags()
        // Do any additional setup after loading the view.
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searching {
            return filteredArray.count
        }
        return initialArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "searchCell", for: indexPath) as? searchCell
        if searching, let title = filteredArray[indexPath.item].titleString, let price = filteredArray[indexPath.item].price, let percentLike = filteredArray[indexPath.item].percentLike, let image = filteredArray[indexPath.item].coverImage, let timestring = filteredArray[indexPath.item].timeString {
            cell?.titleLabel.text = title
            if let url = URL(string: image) {
                cell?.imageView.kf.setImage(with: url)
            }
            if price.decimalCount() == 1 {
                cell?.priceLabel.text = "$\(price)0"
            } else if price.decimalCount() == 0 {
                cell?.priceLabel.text = "$\(price)0"
            } else if price.decimalCount() == 2 {
                cell?.priceLabel.text = "$\(price)"
            }
            if price == 0.0 {
                cell?.priceLabel.text = "Free"
            }
            cell?.timeLabel.text = timestring
            cell?.percentLikedLabel.text = "\(percentLike)% liked"
            if percentLike < 40 {
                cell?.percentLikedLabel.textColor = .systemRed
            } else if percentLike >= 40 && percentLike < 65 {
                cell?.percentLikedLabel.textColor = .systemYellow
            } else {
                cell?.percentLikedLabel.textColor = .systemGreen
            }
        } else if let title = initialArray[indexPath.item].titleString, let price = initialArray[indexPath.item].price, let percentLike = initialArray[indexPath.item].percentLike, let image = initialArray[indexPath.item].coverImage, let timestring = initialArray[indexPath.item].timeString {
            cell?.titleLabel.text = title
            if let url = URL(string: image) {
                cell?.imageView.kf.setImage(with: url)
            }
            if price.decimalCount() == 1 {
                cell?.priceLabel.text = "$\(price)0"
            } else if price.decimalCount() == 0 {
                cell?.priceLabel.text = "$\(price)0"
            } else if price.decimalCount() == 2 {
                cell?.priceLabel.text = "$\(price)"
            }
            if price == 0.0 {
                cell?.priceLabel.text = "Free"
            }
            cell?.timeLabel.text = timestring
            cell?.percentLikedLabel.text = "\(percentLike)% liked"
            if percentLike < 50 {
                cell?.percentLikedLabel.textColor = .systemRed
            } else if percentLike >= 50 && percentLike < 65 {
                cell?.percentLikedLabel.textColor = .systemYellow
            } else {
                cell?.percentLikedLabel.textColor = .systemGreen
            }
        }
        return cell ?? UICollectionViewCell()
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredResults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchTBCell", for: indexPath) as? searchTableViewCell
        cell?.labelTitle.text = filteredResults[indexPath.row]
        return cell ?? UITableViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            let inset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        edgeInsetPadding = Int(inset.left+inset.right)
            return inset
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(minimumSpacing)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(minimumSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (Int(UIScreen.main.bounds.size.width) - (numberOfItemsInRow - 1) * minimumSpacing - edgeInsetPadding) / numberOfItemsInRow
        let half2 = Int(Double(width) * 1.5)
        if UIDevice().userInterfaceIdiom == .pad {
            return CGSize(width: 200, height:  250)
        }
        return CGSize(width: width, height:  half2)
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
            
        case UICollectionView.elementKindSectionHeader:
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerView", for: indexPath)
            headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
            searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: headerView.frame.height)
            if #available(iOS 11.0, *) {
                searchBar.heightAnchor.constraint(equalToConstant: 50).isActive = true
            }
            headerView.addSubview(searchBar)
            buttoner.setTitle("", for: .normal)
           buttoner.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: headerView.frame.height)
            headerView.addSubview(buttoner)
            return headerView
            
       
        default:
            
            assert(false, "Unexpected element kind")
        }
        let headerView = UICollectionReusableView()
        return headerView
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width:collectionView.frame.size.width, height: 50.0)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func initalGrab() {
        var maxDrop = 2
        let defaults = UserDefaults.standard
        let purchasedSave = defaults.stringArray(forKey: "purchased") ?? [String]()
        let ref = Database.database().reference().child("solutions")
        ref.queryLimited(toLast: 50).queryOrdered(byChild: "weight").observeSingleEvent(of: .value, with: { snap in
            if let values = snap.value as? [String: AnyObject] {
                for (_,each) in values {
                    if let title = each["solTitle"] as? String, let time = each["time"] as? Int, let tags = each["solTags"] as? [String: String], let price = each["price"] as? Double, let id = each["solId"] as? String {
                        if maxDrop > 0 && purchasedSave.contains(id) {
                            maxDrop -= 1
                        } else {
                            let solution = solutionObject()
                            solution.id = id
                            solution.titleString = title
                            solution.time = time
                            solution.price = price
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
                            if !self.initialArray.contains( where: { $0.id == solution.id } ) {
                                self.initialArray.append(solution)
                                //self.initialArray.sort(by: { $0.weight > $1.weight })
                            }
                        }
                    }
                }
                self.collectionView.reloadData()
            } else {
                //no solutions
            }
        })
    }
    func searchGrab1(content: String, completion: @escaping (String) -> Void) {
        var maxDrop = 2
        let defaults = UserDefaults.standard
        let purchasedSave = defaults.stringArray(forKey: "purchased") ?? [String]()
        let ref = Database.database().reference().child("solutions")
        ref.queryLimited(toLast: 10).queryOrdered(byChild: "searchTitle").queryStarting(atValue: content).queryEnding(atValue: "\(content)\u{f8ff}").observeSingleEvent(of: .value, with: { (snapshot) in
            if let values = snapshot.value as? [String: AnyObject] {
                for (_,each) in values {
                    if let title = each["solTitle"] as? String, let time = each["time"] as? Int, let tags = each["solTags"] as? [String: String], let price = each["price"] as? Double, let id = each["solId"] as? String {
                        if maxDrop > 0 && purchasedSave.contains(id) {
                            maxDrop -= 1
                        } else {
                            
                            let solution = solutionObject()
                            solution.id = id
                            solution.titleString = title
                            solution.time = time
                            solution.price = price
                            solution.weight = Int.random(in: 5..<15)
                            solution.tags = tags.values.map({$0})
                            solution.dislikes = [String]()
                            solution.likes = [String]()
                            if let coverImage = each["blurredImages"] as? [String: String] {
                                solution.coverImage = coverImage.values.map({$0})[0]
                            }
                            if let likes = each["likes"] as? [String: String]{
                                solution.likes = likes.values.map({$0})
                            }
                            if let dislikes = each["dislikes"] as? [String: String] {
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
                            if !self.filteredArray.contains( where: { $0.id == solution.id } ) {
                                self.filteredArray.append(solution)
                                self.filteredArray.sort(by: { $0.weight > $1.weight })
                            } else {
                                if let firstIndex = self.filteredArray.firstIndex(where: { $0.id == solution.id }) {
                                    self.filteredArray[firstIndex].weight+=10
                                }
                            }
                        }
                    }
                }
            }
            completion("done")
        })
    }
    
    func searchGrab2(content: String, limit: Int, completion: @escaping (String) -> Void) {
        var maxDrop = 2
        let defaults = UserDefaults.standard
        let purchasedSave = defaults.stringArray(forKey: "purchased") ?? [String]()
        let ref = Database.database().reference().child("searchKeys")
        let ref2 = Database.database().reference().child("solutions")
        ref.child(content).queryLimited(toLast: UInt(limit)).observeSingleEvent(of: .value, with: { snapshot in
            if let data = snapshot.value as? [String: String] {
                let dispatch = DispatchGroup()
                for (solid,_) in data {
                    if self.filteredArray.contains( where: { $0.id == solid } ) {
                        if let firstIndex = self.filteredArray.firstIndex(where: { $0.id == solid }) {
                            self.filteredArray[firstIndex].weight+=10
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
                                    if !self.filteredArray.contains( where: { $0.id == solution.id } ) {
                                        self.filteredArray.append(solution)
                                        self.filteredArray.sort(by: { $0.weight > $1.weight })
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if searching {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "solutionVC") as? SolutionViewController {
                vc.solutionId = filteredArray[indexPath.item].id
                self.present(vc, animated: true, completion: nil)
            }
        } else {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "solutionVC") as? SolutionViewController {
                vc.solutionId = initialArray[indexPath.item].id
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func getTags() {
        let ref = Database.database().reference().child("popularTags")
        ref.queryLimited(toLast: 100).queryOrderedByValue().observeSingleEvent(of: .value, with: { snap in
            if let data = snap.value as? [String: Int] {
                for each in data {
                    let fixed = each.key.trimmingTrailingSpaces.replacingOccurrences(of: "-", with: " ").capitalized
                    self.searchTagResults.append(fixed)
                }
            }
            self.filteredResults = self.searchTagResults
            self.tableView.reloadData()
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text?.lowercased(), text != "" {
            filteredResults.removeAll()
            filteredResults = searchTagResults.filter { $0.lowercased().contains(text) }
            self.tableView.reloadData()
        } else {
            filteredResults = searchTagResults
            self.tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar == self.searchController.searchBar {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.tableView.frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: 44)
        }, completion: {(_) -> Void in
            self.searchController.resignFirstResponder()
            self.searchBar.resignFirstResponder()
            self.searchBar.delegate = self
            self.tableView.isHidden = true
            })
        }
        else {
            print("self")
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.filteredArray.removeAll()
        view.addSubview(loading)
        loading.startAnimating()
        var inputText = searchBar.text ?? ""
        self.searchBar.text = inputText
        self.searchBar.placeholder = "  "
        searching = true
        searchBar.isUserInteractionEnabled = false
        self.searchBar.isUserInteractionEnabled = false
        tableView.isUserInteractionEnabled = false
        if let text = searchBar.text?.trimmingTrailingSpaces {
            self.searchGrab1(content: text.lowercased(), completion: { (outcome) -> Void in
                if outcome == "done" {
                    let lineTagSearchText = text.lowercased().replacingOccurrences(of: " ", with: "-")
                    var limitQuery = 30
                    if self.filteredArray.count > 40 {
                        limitQuery = 10
                    }
                    self.searchGrab2(content: lineTagSearchText, limit: limitQuery, completion: { (outcome2) -> Void in
                        if outcome != "" {
                            let noSpaces = text.lowercased().components(separatedBy: CharacterSet.whitespacesAndNewlines)
                            let totalWords = noSpaces.count
                            var counter = 0
                            for each in noSpaces {
                                if !each.contains(" ") && each != "" {
                                    print("")
                                    if self.filteredArray.count > 80 {
                                        limitQuery = 5
                                    }
                                    self.searchGrab2(content: each, limit: limitQuery, completion: { (outcome3) -> Void in
                                        if outcome3 != "" {
                                            counter += 1
                                            if counter == totalWords {
                                                self.loading.stopAnimating()
                                                self.loading.removeFromSuperview()
                                                self.collectionView.reloadData()
                                                self.handleUIAfterSearch()
                                                searchBar.resignFirstResponder()
                                                self.searchBar.isUserInteractionEnabled = true
                                                searchBar.isUserInteractionEnabled = true
                                                self.tableView.isUserInteractionEnabled = true
                                                return
                                            }
                                        }
                                    })
                                } else {
                                    counter += 1
                                    if counter == totalWords {
                                        self.loading.stopAnimating()
                                        self.loading.removeFromSuperview()
                                        self.collectionView.reloadData()
                                        self.handleUIAfterSearch()
                                        searchBar.resignFirstResponder()
                                        self.searchBar.isUserInteractionEnabled = true
                                        searchBar.isUserInteractionEnabled = true
                                        self.tableView.isUserInteractionEnabled = true
                                        return
                                    }
                                }
                            }
                        } else {
                            
                        }
                    })
                }
            })
        }
    }
    
    func handleUIAfterSearch() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.tableView.frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: 44)
        }, completion: {(_) -> Void in
            self.tableView.isHidden = true
            self.searchController.searchBar.isHidden = true
            self.searchController.isActive = false
            self.searchController.isEditing = false
        })
    }
    
    @objc func buttonSelected () {
        tableView.isHidden = false
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.tableView.frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: self.view.frame.height - 5)
            
        }, completion: nil)
        self.searchController.searchBar.isHidden = false
        self.searchController.searchBar.becomeFirstResponder()
        self.searchController.searchBar.text = self.searchBar.text ?? ""
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if self.searchBar == searchBar {
            self.searchBar.text = ""
            self.searchBar.resignFirstResponder()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var tag = self.searchTagResults[indexPath.row].lowercased().replacingOccurrences(of: " ", with: "-")
        if searchController.searchBar.text != "" {
            tag = self.filteredResults[indexPath.row].lowercased().replacingOccurrences(of: " ", with: "-")
        }
        self.filteredArray.removeAll()
        view.addSubview(loading)
        loading.startAnimating()
        searching = true
        searchBar.isUserInteractionEnabled = false
        self.searchBar.placeholder = "  "
        self.searchBar.text = tag.capitalized.replacingOccurrences(of: "-", with: " ")
        self.searchBar.isUserInteractionEnabled = false
        tableView.isUserInteractionEnabled = false
        self.searchGrab2(content: tag, limit: 80, completion: { (outcome3) -> Void in
            if outcome3 != "" {
                self.loading.stopAnimating()
                self.loading.removeFromSuperview()
                self.collectionView.reloadData()
                self.handleUIAfterSearch()
                self.searchBar.isUserInteractionEnabled = true
                self.tableView.isUserInteractionEnabled = true
                return
            }
                
        })
        
    }

}
class searchCell: UICollectionViewCell {
    
    
    var blur = true
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let divideViewHeight = contentView.frame.height * (2/5)
        divideView.clipsToBounds = true
        imageView.clipsToBounds = true
        divideView.layer.cornerRadius = 6
        //contentView.backgroundColor = UIColor(red: 0.2200, green: 0.2200, blue: 0.2200, alpha: 1.0)
        imageView.layer.cornerRadius = 6
        divideView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: divideViewHeight)
        imageView.frame = CGRect(x: 15, y: 15, width: contentView.frame.width - 30, height: divideViewHeight-5)
        priceLabel.frame = CGRect(x: 15, y: divideViewHeight + 8, width: contentView.frame.width / 2 - 30, height: 28)
        if self.traitCollection.userInterfaceStyle == .light {
            priceLabel.textColor = UIColor(red: 0.8078, green: 0.5098, blue: 0, alpha: 1.0)
            percentLikedLabel.textColor = UIColor(red: 0.2157, green: 0.5686, blue: 0, alpha: 1.0)
            
        }
        timeLabel.frame = CGRect(x: contentView.frame.width/2 - 15 , y: divideViewHeight + 8, width: contentView.frame.width/1.9, height: 28)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
               NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),
                   titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant:  8),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
                   titleLabel.widthAnchor.constraint(equalToConstant: contentView.frame.width),
                titleLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 70)
               ])
        titleLabel.sizeToFit()
        heartImage.frame = CGRect(x: contentView.frame.width / 2 - 48, y: contentView.frame.height - 40, width: 25, height: 25)
        percentLikedLabel.frame = CGRect(x: contentView.frame.width / 2 - 12, y: contentView.frame.height - 40, width: 150, height: 28)
        
    }
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var divideView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var heartImage: UIImageView!
    
    
    @IBOutlet weak var percentLikedLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
}
class headerView:  UICollectionReusableView {
    
}
class searchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var labelTitle: UILabel!
    
}
