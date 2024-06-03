//
//  YourSolutionsViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 11/4/23.
//

import UIKit
import Firebase
import Kingfisher

class YourSolutionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var items = [purchasedObject]()
    var adminItems = [purchasedObject]()
    @IBOutlet weak var tableView: UITableView!
    let buttonCam = UIButton()
    var labli = UILabel()
    let viewy = UIView()
    let loading = UIActivityIndicatorView()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loading.frame = view.bounds
        loading.color = .lightGray
        loading.style = .large
        loading.startAnimating()
        view.addSubview(loading)
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        getYours()
        buttonCam.frame = CGRect(x: 0, y: self.view.frame.height - 135, width: view.frame.width, height: 50)
        buttonCam.backgroundColor = .systemBlue
        buttonCam.addTarget(self, action: #selector(self.buttonCameraAction), for: .touchUpInside)
        buttonCam.setTitle("Post New Material", for: .normal)
        buttonCam.titleLabel?.textColor = .white
        buttonCam.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        view.addSubview(self.buttonCam)
        if UIScreen.main.nativeBounds.height <= 1634 || UIScreen.main.nativeBounds.height == 2208 || UIScreen.main.nativeBounds.height == 1920 {
            buttonCam.frame = CGRect(x: 0, y: self.view.frame.height - 105, width: view.frame.width, height: 60)
        }
        if UIDevice().userInterfaceIdiom == .pad {
            buttonCam.frame = CGRect(x: 0, y: self.view.frame.height - 120, width: view.frame.width, height: 60)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.tableView.reloadData()
                self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                self.buttonCam.frame = CGRect(x: 0, y: self.view.frame.height - 120, width: self.view.frame.width, height: 60)
                self.labli.frame = CGRect(x: 10, y: 0, width: self.viewy.bounds.width - 20, height: 90)
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.tableView.reloadData()
                    self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                    self.buttonCam.frame = CGRect(x: 0, y: self.view.frame.height - 120, width: self.view.frame.width, height: 60)
                    self.labli.frame = CGRect(x: 10, y: 0, width: self.viewy.bounds.width - 20, height: 90)
                })
            }
        }
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return adminItems.count
        }
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell1YourSolutions", for: indexPath) as? yourSolutionsCell
        if indexPath.section == 0 {
            cell?.labelTitle.text = adminItems[indexPath.row].titleString
        } else {
            cell?.labelTitle.text = items[indexPath.row].titleString
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view1 = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
        view.backgroundColor = .clear
        let labelHeaderTitle = UILabel(frame: CGRect(x: 10, y: 5, width: view1.frame.width - 10, height: 30))
        labelHeaderTitle.textColor = .lightGray
        labelHeaderTitle.font = UIFont(name: "HelveticaNueue", size: 14)
        labelHeaderTitle.textAlignment = .left
        if section == 0 && adminItems.count != 0 {
            labelHeaderTitle.text = "Processing Material: "
        } else if section == 1 && self.items.count != 0 {
            labelHeaderTitle.text = "Live Material: "
            labelHeaderTitle.textColor = .systemGreen
        }
        view1.addSubview(labelHeaderTitle)
        return view1
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && adminItems.count != 0 {
            return 40
        } else if section == 0 && adminItems.count == 0 {
            return 0
        } else if section == 1 && items.count == 0 {
            return 0
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func getYours() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users")
            let solRef = Database.database().reference().child("solutions")
            ref.child(uid).child("solutionsPosted").observeSingleEvent(of: .value, with: { snap in
                if let vals = snap.value as? [String: String] {
                    let dispatch = DispatchGroup()
                    for (_,each) in vals {
                        dispatch.enter()
                        solRef.child(each).observeSingleEvent(of: .value, with: { snapshot in
                            let values = snapshot.value as? [String : AnyObject]
                            if let title = values?["solTitle"] as? String, let id = values?["solId"] as? String {
                                let object = purchasedObject()
                                object.id = id
                                object.titleString = title
                                if !self.items.contains( where: { $0.id == object.id } ) {
                                    self.items.append(object)
                                }
                            }
                            dispatch.leave()
                        })
                    }
                    dispatch.notify(queue: DispatchQueue.main) {
                        self.getYourAdminPosts(vals: vals)
                    }
                } else {
                    self.handleNone()
                }
                
            })
        }
    }
    
    
    
    func getYourAdminPosts(vals: [String: String]) {
        if let uid = Auth.auth().currentUser?.uid {
            let solRef = Database.database().reference().child("adminQueue")
            let dispatch = DispatchGroup()
            for (_,each) in vals {
                dispatch.enter()
                solRef.child(each).observeSingleEvent(of: .value, with: { snapshot in
                    let values = snapshot.value as? [String : AnyObject]
                    if let title = values?["solTitle"] as? String, let id = values?["solId"] as? String {
                        let object = purchasedObject()
                        object.id = id
                        object.titleString = title
                        if !self.adminItems.contains( where: { $0.id == object.id } ) {
                            self.adminItems.append(object)
                        }
                    }
                    dispatch.leave()
                })
            }
            dispatch.notify(queue: DispatchQueue.main) {
                self.handleNone()
            }
        }
    }
    
    func handleNone() {
        self.loading.stopAnimating()
        self.loading.removeFromSuperview()
        self.tableView.reloadData()
        self.viewy.removeFromSuperview()
        if self.adminItems.count == 0 && self.items.count == 0 {
            self.viewy.backgroundColor = .systemBlue
            self.viewy.layer.cornerRadius = 8
            self.viewy.clipsToBounds = true
            self.viewy.frame = CGRect(x: 25, y: self.view.frame.height / 2 - 50, width: self.view.frame.width - 50, height: 90)
            labli = UILabel(frame: CGRect(x: 10, y: 0, width: self.viewy.bounds.width - 20, height: 90))
            labli.numberOfLines = 3
            labli.textColor = .white
            labli.textAlignment = .center
            labli.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
            labli.text = "Start posting content/tutoring lessons and find them here!"
            self.viewy.addSubview(labli)
            self.view.addSubview(self.viewy)
            
        }
    }
    
    @objc func buttonCameraAction() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NewSolutionVC") as! UINavigationController
        if let viewCon = vc.viewControllers[0] as? NewSolutionViewController {
            
        }
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if let id = items[indexPath.row].id {
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "solutionVC") as? SolutionViewController {
                    vc.solutionId = id
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }
    }

}

class yourSolutionsCell: UITableViewCell {

    @IBOutlet weak var labelTitle: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        labelTitle.frame = CGRect(x: 15, y: 10, width: contentView.frame.width - 20, height: 35)
    }
    
}

