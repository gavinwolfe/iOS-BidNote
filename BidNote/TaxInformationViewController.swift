//
//  TaxInformationViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 11/15/23.
//

import UIKit
import Firebase

class TaxInformationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var tableView: UITableView!
    var items = [taxInfoObject]()
    let viewy = UIView()
    @IBOutlet weak var irsButton: UIButton!
    var labli = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.frame = CGRect(x: 0, y: 100, width: view.frame.width, height: view.frame.height - 100)
//        irsButton.frame = CGRect(x: 30, y: 40, width: view.frame.width - 60, height: 38)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 68.0
        tableView.rowHeight = UITableView.automaticDimension
        getData()
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.tableView.reloadData()
                self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                
                self.labli.frame = CGRect(x: 10, y: 0, width: self.viewy.bounds.width - 20, height: 90)
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.tableView.reloadData()
                    self.viewy.frame = CGRect(x: 25, y: self.view.bounds.height / 2 - 50, width: self.view.frame.width - 50, height: 60)
                   
                    self.labli.frame = CGRect(x: 10, y: 0, width: self.viewy.bounds.width - 20, height: 90)
                })
            }
        }
    }
    
    func getData() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users")
            ref.child(uid).child("payoutsPast").observeSingleEvent(of: .value, with: {snapshot in
                if let values = snapshot.value as? [String: Double] {
                    for (timestam, pricestam) in values {
                        let object = taxInfoObject()
                        object.pricePaid = pricestam
                        object.timeCompleted = Int(timestam)
                        let timeStamp: Int = Int(NSDate().timeIntervalSince1970)
                        let timer = timeStamp - (Int(timestam) ?? 0)
                        if timer <= 59 {
                            object.timeString = "\(timer)s ago"
                        }
                        if timer > 59 && timer < 3600 {
                            let minuters = timer / 60
                            object.timeString = "\(minuters) mins ago"
                            if minuters == 1 {
                                object.timeString = "\(minuters) min ago"
                            }
                        }
                        if timer > 59 && timer >= 3600 && timer < 86400 {
                            let hours = timer / 3600
                            if hours == 1 {
                                object.timeString = "\(hours) hr ago"
                            } else {
                                object.timeString = "\(hours) hrs ago"
                            }
                        }
                        if timer > 86400 {
                            let days = timer / 86400
                            object.timeString = "\(days) days ago"
                            if days == 1 {
                                object.timeString = "\(days) day ago"
                            }
                        }
                        if timer > 2592000 {
                            let months = timer/2592000
                            object.timeString = "\(months) months ago"
                            if months == 1 {
                                object.timeString = "\(months) month ago"
                            }
                        }
                        self.items = self.items.sorted { $0.timeCompleted > $1.timeCompleted }
                        self.items.append(object)
                    }
                }
                self.tableView.reloadData()
                if self.items.count == 0 {
                    self.viewy.backgroundColor = .systemBlue
                    self.viewy.layer.cornerRadius = 8
                    self.viewy.clipsToBounds = true
                    self.viewy.frame = CGRect(x: 25, y: self.view.frame.height / 2 - 50, width: self.view.frame.width - 50, height: 90)
                    self.labli = UILabel(frame: CGRect(x: 10, y: 10, width: self.viewy.frame.width - 20, height: 70))
                    self.labli.numberOfLines = 2
                    self.labli.textColor = .white
                    self.labli.textAlignment = .center
                    self.labli.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
                    self.labli.text = "Past commission payouts will show here!"
                    self.viewy.addSubview(self.labli)
                    self.view.addSubview(self.viewy)
                } else {
                    self.viewy.removeFromSuperview()
                }
            })
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellTaxInfo", for: indexPath) as? taxInfoTBCell
        if let price = items[indexPath.row].pricePaid, let timeString = items[indexPath.row].timeString {
            cell?.dataLabel.text = "Payout \(timeString) for $\(price) : Completed"
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    @IBAction func irsAction(_ sender: Any) {
        if let url = URL(string: "https://www.irs.gov/businesses/understanding-your-form-1099-k#:~:text=or%20Provide%20Services-,You%20may%20get%20a%20Form%201099%2DK%20if%20you%20received,selling%20items%20as%20a%20hobby.") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
class taxInfoTBCell: UITableViewCell {
    
    @IBOutlet weak var dataLabel: UILabel!
    
}
