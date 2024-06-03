//
//  PurchasedViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 11/3/23.
//

import UIKit
import Firebase
import Kingfisher


class PurchasedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var items = [purchasedObject]()
    @IBOutlet weak var tableView: UITableView!
    let viewy = UIView()
    var labli = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        getPurchased()
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.tableView.reloadData()
                self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                self.labli.frame = CGRect(x: 10, y: 0, width: self.viewy.frame.width - 20, height: 90)
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.tableView.reloadData()
                    self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                    self.labli.frame = CGRect(x: 10, y: 0, width: self.viewy.frame.width - 20, height: 90)
                })
            }
        }
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell1Purchased", for: indexPath) as? purchasedCell
        cell?.titleLabel.text = items[indexPath.row].titleString
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let solid = items[indexPath.row].id {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "solutionVC") as? SolutionViewController {
                vc.solutionId = solid
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func getPurchased() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users")
            let solRef = Database.database().reference().child("solutions")
            ref.child(uid).child("purchased").observeSingleEvent(of: .value, with: { snap in
                if let vals = snap.value as? [String: AnyObject] {
                    let dispatch = DispatchGroup()
                    for (each,_) in vals {
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
                        if self.items.count == 0 {
                            self.viewy.backgroundColor = .systemBlue
                            self.viewy.layer.cornerRadius = 8
                            self.viewy.clipsToBounds = true
                            self.viewy.frame = CGRect(x: 25, y: self.view.frame.height / 2 - 50, width: self.view.frame.width - 50, height: 90)
                            self.labli = UILabel(frame: CGRect(x: 10, y: 0, width: self.viewy.frame.width - 20, height: 90))
                            self.labli.numberOfLines = 3
                            self.labli.textColor = .white
                            self.labli.textAlignment = .center
                            self.labli.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
                            self.labli.text = "Your purchased material will show up here!"
                            self.viewy.addSubview(self.labli)
                            self.view.addSubview(self.viewy)
                        } else {
                            self.viewy.removeFromSuperview()
                        }
                        self.tableView.reloadData()
                    }
                } else {
                    self.viewy.backgroundColor = .systemBlue
                    self.viewy.layer.cornerRadius = 8
                    self.viewy.clipsToBounds = true
                    self.viewy.frame = CGRect(x: 25, y: self.view.frame.height / 2 - 50, width: self.view.frame.width - 50, height: 90)
                    self.labli = UILabel(frame: CGRect(x: 10, y: 0, width: self.viewy.bounds.width - 20, height: 90))
                    self.labli.numberOfLines = 3
                    self.labli.textColor = .white
                    self.labli.textAlignment = .center
                    self.labli.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
                    self.labli.text = "Your purchased material will show up here!"
                    self.viewy.addSubview(self.labli)
                    self.view.addSubview(self.viewy)
                }
                
            })
        }
    }

}

class purchasedCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 15, y: 10, width: contentView.frame.width - 20, height: 35)
    }
    
}
