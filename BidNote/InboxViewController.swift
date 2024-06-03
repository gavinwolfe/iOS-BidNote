//
//  InboxViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/9/23.
//

import UIKit
import Firebase
import Kingfisher

class InboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var items = [inboxObject]()
    var labli = UILabel()
    
    @IBOutlet weak var tableView: UITableView!
    let viewy = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 68.0
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.rowHeight = UITableView.automaticDimension
        getMessages()
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.tableView.reloadData()
                self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                self.labli.frame = CGRect(x: 10, y: 10, width: self.viewy.bounds.width - 20, height: 40)
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.tableView.reloadData()
                    self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                    self.labli.frame = CGRect(x: 10, y: 10, width: self.viewy.bounds.width - 20, height: 40)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellInbox", for: indexPath) as? inboxCell
        if let content = items[indexPath.row].contentString, let image = items[indexPath.row].iconImage, let type = items[indexPath.row].type {
            cell?.contentLabel.text = content
            cell?.iconImageView.image = UIImage(systemName: image)
            if type == "reject" {
                cell?.iconImageView.tintColor = UIColor.systemRed
            } else if type == "purchase" {
                cell?.iconImageView.tintColor = UIColor.systemBlue
            } else if type == "approval" {
                cell?.iconImageView.tintColor = UIColor.systemGreen
            } else if type == "like" {
                cell?.iconImageView.tintColor = UIColor.systemIndigo
            } else if type == "payout" {
                cell?.iconImageView.tintColor = UIColor.systemGreen
            } else {
                cell?.iconImageView.tintColor = .orange
            }
            if UIDevice().userInterfaceIdiom == .pad {
                cell?.contentLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
            }
        }
        return cell ?? UITableViewCell()
    }
    
    func getMessages() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users")
            ref.child(uid).child("inbox").observeSingleEvent(of: .value, with: { snap in
                if let vals = snap.value as? [String: AnyObject] {
                    for (_,each) in vals {
                        if let id = each["key"] as? String, let content = each["content"] as? String, let type = each["type"] as? String, let time = each["time"] as? Int {
                            let newObject = inboxObject()
                            newObject.contentString = content
                            newObject.id = id
                            newObject.type = type
                            newObject.time = time
                            if let read = each["read"] as? Int {
                                newObject.read = read
                            }
                            if type == "reject" {
                                newObject.iconImage = "exclamationmark.triangle.fill"
                            } else if type == "purchase" {
                                newObject.iconImage = "burst.fill"
                            } else if type == "approval" {
                                newObject.iconImage = "checkmark.seal.fill"
                            } else if type == "like"{
                                newObject.iconImage = "heart.fill"
                            } else if type == "payout" {
                                newObject.iconImage = "dollarsign.square.fill"
                            } else {
                                newObject.iconImage = "envelope.fill"
                            }
                            if !self.items.contains( where: { $0.id == newObject.id } ) {
                                self.items.append(newObject)
                                self.items.sort(by: { $0.time > $1.time })
                            }
                        }
                    }
                }
                self.tableView.reloadData()
                self.clearReads()
                if self.items.count == 0 {
                    self.viewy.backgroundColor = .systemBlue
                    self.viewy.layer.cornerRadius = 8
                    self.viewy.clipsToBounds = true
                    self.viewy.frame = CGRect(x: 25, y: self.view.frame.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                    self.labli = UILabel(frame: CGRect(x: 10, y: 10, width: self.viewy.bounds.width - 20, height: 40))
                    self.labli.textColor = .white
                    self.labli.textAlignment = .center
                    self.labli.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
                    self.labli.text = "Inbox is empty!"
                    self.viewy.addSubview(self.labli)
                    self.view.addSubview(self.viewy)
                } else {
                    self.viewy.removeFromSuperview()
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func clearReads() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let ref = Database.database().reference()
            if self.items.count != 0, let uid = Auth.auth().currentUser?.uid {
                for each in self.items {
                    ref.child("users").child(uid).child("inbox").child(each.id).updateChildValues(["read": 1])
                }
                ref.child("users").child(uid).child("inboxUnseen").removeValue()
            }
        }
    }
    

}
class inboxCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    @IBOutlet weak var contentLabel: UILabel!
    
   
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
}
