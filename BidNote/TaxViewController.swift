//
//  TaxViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/6/23.
//

import UIKit
protocol clickedBidnoteAgree {
    func bidnoteAgree()
}
protocol clickedPaypalAgree {
    func paypalAgree()
}
protocol clickedIRSAgree {
    func irsAgree()
}
protocol clickedDone {
    func clickedDone()
}

class TaxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, clickedBidnoteAgree, clickedPaypalAgree, clickedIRSAgree, clickedDone {
 

    @IBOutlet weak var tableView: UITableView!
    var section1Completed = false
    var seciton2Completed = false
    var section3Completed = false
    var delegateNewSolution: completedTax?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableView.automaticDimension
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                //self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
                self.tableView.reloadData()
            })
        } else {
            if UIDevice().userInterfaceIdiom == .pad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                   // self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
                    self.tableView.reloadData()
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
        return 6
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "taxCell1", for: indexPath) as? tax1cell
            return cell ?? UITableViewCell()
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "taxCell2", for: indexPath) as? tax2cell
            return cell ?? UITableViewCell()
        } else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "taxCell3", for: indexPath) as? tax3cell
            if section1Completed {
                cell?.agreeButton.backgroundColor = .systemGreen
            } else {
                cell?.agreeButton.backgroundColor = .opaqueSeparator
            }
            cell?.delegate = self
            return cell ?? UITableViewCell()
        } else if indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "taxCell4", for: indexPath) as? tax4cell
            if seciton2Completed {
                cell?.agreeButton.backgroundColor = .systemGreen
            } else {
                cell?.agreeButton.backgroundColor = .opaqueSeparator
            }
            cell?.delegate = self
            return cell ?? UITableViewCell()
        } else if indexPath.row == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "taxCell5", for: indexPath) as? tax5cell
            if section3Completed {
                cell?.agreeButton.backgroundColor = .systemGreen
            } else {
                cell?.agreeButton.backgroundColor = .opaqueSeparator
            }
            cell?.delegate = self
            return cell ?? UITableViewCell()
        } else if indexPath.row == 5 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "taxCell6", for: indexPath) as? tax6cell
            cell?.delegate = self
            return cell ?? UITableViewCell()
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 60
        } else if indexPath.row == 1 {
            return UITableView.automaticDimension
        } else if indexPath.row == 2 {
            return UITableView.automaticDimension
        } else if indexPath.row == 3 {
            return UITableView.automaticDimension
        } else if indexPath.row == 4 {
            return UITableView.automaticDimension
        } else if indexPath.row == 5 {
            return 120
        }
        return 100
    }
    
    func bidnoteAgree() {
        self.section1Completed = true
        tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
    }
    
    func paypalAgree() {
        self.seciton2Completed = true
        tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .automatic)
    }
    
    func irsAgree() {
        self.section3Completed = true
        tableView.reloadRows(at: [IndexPath(row: 4, section: 0)], with: .automatic)
    }
    
    func clickedDone() {
        guard section1Completed && seciton2Completed && section3Completed else {
            print("did not completed")
            return
        }
        
        self.dismiss(animated: true, completion: {
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: "taxRead")
            self.delegateNewSolution?.allCheckedComplete()
        })
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


class tax1cell: UITableViewCell {
    
    @IBOutlet weak var readLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
}
class tax2cell: UITableViewCell {
    
    @IBOutlet weak var taxLabel: UILabel!
}
class tax3cell: UITableViewCell {
    
    var delegate: clickedBidnoteAgree?
    
    @IBOutlet weak var termsLabel: UILabel!
    
    @IBOutlet weak var contentLabel: UILabel!
    
    @IBOutlet weak var fullTermsButton: UIButton!
    
    @IBOutlet weak var agreeButton: UIButton!
    
    
    @IBAction func agreeAction(_ sender: Any) {
        delegate?.bidnoteAgree()
    }
    
    
    @IBAction func fullTermsAction(_ sender: Any) {
        if let url = URL(string: "https://bidnoteapp.com/terms-of-service") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        agreeButton.layer.cornerRadius = 12.0
    }
}
class tax4cell: UITableViewCell {
    
    var delegate: clickedPaypalAgree?
    
    @IBOutlet weak var termsLabel: UILabel!
    
    @IBOutlet weak var contentLabel: UILabel!
    
    
    @IBOutlet weak var fullTermsButton: UIButton!
    
    @IBOutlet weak var agreeButton: UIButton!
    override func layoutSubviews() {
        super.layoutSubviews()
        agreeButton.layer.cornerRadius = 12.0
    }
    
    
    @IBAction func fullTermsAction(_ sender: Any) {
        if let url = URL(string: "https://www.paypal.com/us/legalhub/platform-seller-agreement") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    
    @IBAction func agreeAction(_ sender: Any) {
        delegate?.paypalAgree()
    }
    
}

class tax5cell: UITableViewCell {
    
    var delegate: clickedIRSAgree?
    
    
    @IBOutlet weak var termsLabel: UILabel!
    
    @IBOutlet weak var contentLabel: UILabel!
    
    
    @IBOutlet weak var fullTermsButton: UIButton!
    
    @IBOutlet weak var agreeButton: UIButton!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        agreeButton.layer.cornerRadius = 12.0
    }
    
    @IBAction func agreeAction(_ sender: Any) {
        delegate?.irsAgree()
    }
    
    
    @IBAction func fullTermsAction(_ sender: Any) {
        if let url = URL(string: "https://www.irs.gov/businesses/understanding-your-form-1099-k#:~:text=or%20Provide%20Services-,You%20may%20get%20a%20Form%201099%2DK%20if%20you%20received,selling%20items%20as%20a%20hobby.") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    
}

class tax6cell: UITableViewCell {
    
    var delegate: clickedDone?
    
    @IBOutlet weak var doneButton: UIButton!
    override func layoutSubviews() {
        super.layoutSubviews()
        doneButton.layer.cornerRadius = 14.0
    }
    
    @IBAction func doneAction(_ sender: Any) {
        if let delegate = delegate {
            delegate.clickedDone()
        }
    }
    
    
}
