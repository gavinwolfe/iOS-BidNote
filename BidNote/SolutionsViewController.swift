//
//  SolutionsViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 7/20/23.
//

import UIKit
import Firebase

class SolutionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let buttonClickySearch = UIButton()
    var selectedIndx : Int?
    var settings = ["Material you purchased", "Your Material", "Inbox", "Your Commission Payouts", "Commissions and Pricing Information", "BidNote? Whats that? + Help/Tax Info", "Account Information + Settings"]
    var tagOrPub: Int?
    var cats = [categori]()
    var tagedOrNot: Int?
    let buttonCam = UIButton()
    var isAdmin = false
    var hasNotifications = false
    var timer : Timer?
    var counter = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCats()
        buttonCam.frame = CGRect(x: 0, y: self.view.frame.height - 135, width: view.frame.width, height: 50)
        buttonCam.backgroundColor = .systemBlue
        buttonCam.addTarget(self, action: #selector(self.buttonCameraAction), for: .touchUpInside)
        buttonCam.setTitle("Post New Question", for: .normal)
        buttonCam.titleLabel?.textColor = .white
        buttonCam.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        //view.addSubview(self.buttonCam)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.placeholder = "Molecular Biology Help..."
        //searchBar.layer.borderWidth = 1
        searchBar.tintColor = .white
        searchBar.barTintColor = .secondarySystemBackground
        self.checkNotifications()
        fetchAdmins()
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.tableView.reloadData()
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = Timer.scheduledTimer(timeInterval:1, target:self, selector:#selector(prozessTimer), userInfo: nil, repeats: true)
    }
    func loadCats() {
        let defaults = UserDefaults.standard
        let namedArray = defaults.stringArray(forKey: "namedCats") ?? [String]()
        
        for each in namedArray {
            let newPub = categori()
            let catsIDArray = defaults.stringArray(forKey: "savedCats") ?? [String]()
            let idversion = each.replacingOccurrences(of: " ", with: "").lowercased()
            if let index = catsIDArray.firstIndex(of: idversion) {
                newPub.id = catsIDArray[index]
            }
            newPub.titleString = each
            newPub.isFollowing = true
            self.cats.append(newPub)
        }
        
        if cats.count == 0 {
            let newPub = categori()
            newPub.titleString = "Physics"
            newPub.id = "physics"
            newPub.isFollowing = false
            self.cats.append(newPub)
            let newPub1 = categori()
            newPub1.titleString = "Computer Science"
            newPub1.id = "computer-science"
            newPub1.isFollowing = false
            self.cats.append(newPub1)
            let newPub2 = categori()
            newPub2.titleString = "Biology"
            newPub2.id = "biology"
            newPub2.isFollowing = false
            self.cats.append(newPub2)
        }
        self.tableView.reloadSections([0], with: .automatic)
    }
    
    @objc func buttonCameraAction() {
       print("new question")
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))
            buttonClickySearch.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
            buttonClickySearch.addTarget(self, action: #selector(self.moveToSearch), for: .touchUpInside)
            self.searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
            view.backgroundColor = .secondarySystemBackground
            if #available(iOS 11.0, *) {
                searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
            }
            view.addSubview(searchBar)
            view.addSubview(buttonClickySearch)
            return view
        }
        let view = UIView()
        return view
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return 215
            }
            return 230
        }
        return 50
    }
    let searchBar = UISearchBar()
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            return 50
        }
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return settings.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            
            let cell1 = tableView.dequeueReusableCell(withIdentifier: "cell1Solutions", for: indexPath) as! cell1Solutions
            cell1.productVC = self
            cell1.whatSection = 1
            cell1.buttonMoveon.tag = 1
            cell1.cats = cats
            cell1.buttonMoveon.addTarget(self, action: #selector(self.MoveToPubsOrTags(sender:)), for: .touchUpInside)
            return cell1
            
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell3Solutions", for: indexPath) as? settingsTableViewCell
        cell?.labelMain.text = settings[indexPath.row]
        if self.hasNotifications && indexPath.row == 2 {
            cell?.notifView.isHidden = false
        } else {
            cell?.notifView.isHidden = true
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 3 {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "adminVC") as? AdminViewController, isAdmin {
                self.present(vc, animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "segueTaxInfo", sender: self)
            }
        } else if indexPath.section == 1 && indexPath.row == 2 {
            self.hasNotifications = false
            self.tableView.reloadRows(at: [IndexPath(row: 2, section: 1)], with: .automatic)
            self.performSegue(withIdentifier: "inboxSegue", sender: self)
        } else if indexPath.section == 1 && indexPath.row == 4 {
            if let url = URL(string: "https://bidnoteapp.com/pricing-policy") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else if indexPath.section == 1 && indexPath.row == 0 {
            self.performSegue(withIdentifier: "seguePurchased", sender: self)
        } else if indexPath.section == 1 && indexPath.row == 1 {
            self.performSegue(withIdentifier: "yourSolutionsSegue", sender: self)
        } else if indexPath.section == 1 && indexPath.row == 5 {
            self.performSegue(withIdentifier: "helpSegue", sender: self)
        } else if indexPath.section == 1 && indexPath.row == 6 {
            self.performSegue(withIdentifier: "settingsSegue", sender: self)
        }
    }

    func fetchAdmins() {
        let ref = Database.database().reference()
        if let uid = Auth.auth().currentUser?.uid {
            ref.child("adminUsers").child(uid).observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    self.isAdmin = true
                }
            })
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
    
    @objc func prozessTimer() {
        counter += 1
        if counter == 3 {
            self.checkNotifications()
            counter = 1
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
           timer = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueSelectedCat" {
            if let dest = segue.destination as? SelectedCatViewController {
                if let selectedIndex = selectedIndx {
                    dest.catId = cats[selectedIndex].id
                    dest.catName = cats[selectedIndex].titleString
                }
            }
        }
    }
    
    func checkNotifications() {
        let ref = Database.database().reference()
        if let uid = Auth.auth().currentUser?.uid {
            ref.child("users").child(uid).child("inboxUnseen").observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    self.hasNotifications = true
                    self.tableView.reloadRows(at: [IndexPath(row: 2, section: 1)], with: .automatic)
                } else {
                    self.hasNotifications = false
                }
            })
        }
    }
    
    @objc func MoveToPubsOrTags (sender: UIButton) {
       self.performSegue(withIdentifier: "segueViewCats", sender: self)
    }
    @objc func moveToSearch () {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "searchVC") as? SearchViewController {
            self.present(vc, animated: true, completion: nil)
        }
    }

}

class cell1Solutions: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var whatSection: Int?
    //    var tags = [Tagi]()
    var cats = [categori]()
    //var whatQuad: Int?
    @IBOutlet weak var labelAbove: UILabel!
    
    var productVC: SolutionsViewController?
    
    var subbedPubs = [String]()
   // var subbedTags = [String]()

    @IBOutlet weak var collectionViewLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var collectionViewer: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionViewer.delegate = self
        collectionViewer.dataSource = self
       
        // Initialization code
    }
    override func layoutSubviews() {
       labelAbove.frame = CGRect(x: 8, y: 0, width: 100, height: 20)
        collectionViewer.frame = CGRect(x: 8, y: 20, width: contentView.frame.width - 8, height: 140)
        collectionViewer.backgroundColor = .secondarySystemBackground
        contentView.backgroundColor = .secondarySystemBackground
        buttonMoveon.frame = CGRect(x: 15, y: 175, width: contentView.frame.width - 30, height: 43)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        productVC?.selectedIndx = indexPath.row
        productVC?.tagOrPub = whatSection
        productVC?.performSegue(withIdentifier: "segueSelectedCat", sender: nil)
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 130)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
    
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if whatSection == 2 {
//            return tags.count
//        }
        
        return cats.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionViewer.dequeueReusableCell(withReuseIdentifier: "cellCollectionViewSolutions", for: indexPath) as! collectionViewCellSolutions
        print("calledr")
        
       cell.mainImagerView.frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height)
        cell.mainImagerView.layer.cornerRadius = 15.0
        cell.mainImagerView.backgroundColor = randomColor()
         cell.labelMain.text = cats[indexPath.row].titleString
        if indexPath.row == 1 {
          //  cell.mainImagerView.image = #imageLiteral(resourceName: "fox")
            cell.labelMain.text = cats[indexPath.row].titleString
        }
        if whatSection == 2 {
          
        }
        return cell
    }
    
    
    
    func randomColor () -> UIColor {
         let radOne = Int.random(in: 1..<8)
        // there are 7
        if radOne == 1 {
            return UIColor(red: 0.8392, green: 0.5294, blue: 0, alpha: 1.0)
        }
        if radOne == 2 {
            return UIColor(red: 0, green: 0.6353, blue: 0.7176, alpha: 1.0)
        }
        if radOne == 3 {
            return UIColor(red: 0.7294, green: 0, blue: 0.0118, alpha: 1.0)
        }
        if radOne == 4 {
            return UIColor(red: 0.3059, green: 0, blue: 0.7098, alpha: 1.0)
        }
        if radOne == 5 {
            return UIColor(red: 0, green: 0.2039, blue: 0.6784, alpha: 1.0)
        }
        if radOne == 6 {
            return UIColor(red: 0.6863, green: 0.3216, blue: 0, alpha: 1.0)
        }
        if radOne == 7 {
            return UIColor(red: 0, green: 0.6784, blue: 0.5647, alpha: 1.0)
        }
        return UIColor.blue
    }
    
    
    
    @IBOutlet weak var buttonMoveon: UIButton!
}
class cell2Solutions: UITableViewCell {
    
    var backView = UIView()
    var shadowImageView = UIView()
    var imagerView = UIImageView()
    var titleLabel = UILabel()
    var tagsLabel = UILabel()
    var priceLabel = UILabel()
    var correctLabel = UILabel()
    var viewsLabel = UILabel()
    var viewsImageView = UIImageView()

    override func layoutSubviews() {
        //add each object
        contentView.addSubview(imagerView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(tagsLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(correctLabel)
        contentView.addSubview(viewsLabel)
        contentView.addSubview(viewsImageView)
        contentView.backgroundColor = UIColor(red: 0.1333, green: 0.1647, blue: 0.1216, alpha: 1.0)
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
                layoutScreen(type: 2, width: contentView.frame.width, height: contentView.frame.height)
            case 2532:
                layoutScreen(type: 1, width: contentView.frame.width, height: contentView.frame.height)
                print("iPhone 12 Pro")
            case 2688:
                print("iPhone XS Max")
            case 2778:
                print("iPhone 13 Pro Max")
            case 1792:
                print("iPhone XR")
                
            default:
                print("Unknown")
            }
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                print("iPad")
            }
        }
                
                
    }
    
    func layoutScreen(type: Int, width: Double, height: Double) {
        imagerView.frame = CGRect(x: 15, y: 10, width: 90, height: 90)
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 15)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .white
        priceLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
        priceLabel.textColor = UIColor(red: 0.9765, green: 0.8, blue: 0, alpha: 1.0)
        priceLabel.textAlignment = .left
        correctLabel.textAlignment = .left
        correctLabel.font = UIFont(name: "HelveticaNeue", size: 12)
        correctLabel.textColor = UIColor(red: 0.1059, green: 0.9098, blue: 0, alpha: 1.0)
        correctLabel.numberOfLines = 2
        correctLabel.text = "• for a correct answer"
        viewsImageView.image = UIImage(systemName: "magnifyingglass.circle.fill")
        viewsLabel.textAlignment = .left
        viewsLabel.font = UIFont(name: "HelveticaNeue", size: 10)
        viewsLabel.textColor = .lightGray
        tagsLabel.font = UIFont(name: "HelveticaNeue", size: 10)
        tagsLabel.textAlignment = .left
        tagsLabel.textColor = .lightGray
        //frames
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 27).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: imagerView.trailingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -5).isActive = true
        priceLabel.frame = CGRect(x: 115, y: 5, width: 60, height: 25)
        correctLabel.frame = CGRect(x: 165 , y: 5, width: 190, height: 25)
        viewsImageView.frame = CGRect(x: width - 82, y: height - 28, width: 18, height: 18)
        viewsImageView.tintColor = .lightGray
        viewsLabel.frame = CGRect(x: width - 60, y: height - 30, width: 50, height: 20)
        tagsLabel.sizeToFit()
        imagerView.layer.cornerRadius = 5.0
        imagerView.clipsToBounds = true
        viewsImageView.contentMode = .scaleAspectFill
        // UIColor(red: 0.1059, green: 0.9098, blue: 0, alpha: 1.0)
        if type == 1 {
            tagsLabel.translatesAutoresizingMaskIntoConstraints = false
            tagsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5).isActive = true
            tagsLabel.leadingAnchor.constraint(equalTo: imagerView.trailingAnchor, constant: 10).isActive = true
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50).isActive = true
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12).isActive = true
        } else if type == 2 {
            tagsLabel.translatesAutoresizingMaskIntoConstraints = false
            tagsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3).isActive = true
            tagsLabel.leadingAnchor.constraint(equalTo: imagerView.trailingAnchor, constant: 10).isActive = true
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50).isActive = true
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14).isActive = true
        } else if type == 3 {
            
        } else if type == 4 {
            
        } else if type == 5 {
            
        } else if type == 6 {
            
        } else if type == 7 {
            
        } else if type == 8 {
            
        } else if type == 9 {
            
        }







    }
    
}
class collectionViewCellSolutions: UICollectionViewCell {
    
        override func layoutSubviews() {
            super.layoutSubviews()
            
            labelMain.frame = CGRect(x: 0, y: 5, width: contentView.frame.width, height: contentView.frame.height - 10)
            labelMain.textAlignment = .center
            labelMain.numberOfLines = 0
            labelMain.font = UIFont(name: "Verdana", size: 18)
            labelMain.textColor = .white
           
            contentView.addSubview(labelMain)
        }

        var labelMain = UILabel()
       
        @IBOutlet weak var mainImagerView: UIImageView!
    //cellCollectionViewSolutions
}

class settingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var labelMain: UILabel!
    override func layoutSubviews() {
        super.layoutSubviews()
        labelMain.frame = CGRect(x: 15, y: 5, width: contentView.frame.width - 30, height: 40)
        notifView.frame = CGRect(x: contentView.frame.width - 50, y: 5, width: 30, height: 30)
        notifView.layer.cornerRadius = 15
    }
    
    @IBOutlet weak var notifView: UIView!
    
}
