//
//  CategoriesListViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 10/24/23.
//

import UIKit
import Firebase

class CategoriesListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var cats = [categori]()
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        getCats()
       
        // Do any additional setup after loading the view.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cats.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "catsListCell", for: indexPath) as? catsCell
        cell?.titleLabelCell.text = cats[indexPath.row].titleString
        return cell ?? UITableViewCell()
    }
    
    func getCats() {
        let ref = Database.database().reference()
        ref.child("categories").observeSingleEvent(of: .value, with: { snap in
            if let cats = snap.value as? [String: String] {
                for (id,each) in cats {
                    let cat = categori()
                    cat.id = id
                    cat.titleString = each
                    self.cats.append(cat)
                }
            }
            self.tableView.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "segueSelectedTags", sender: self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueSelectedTags", let vc = segue.destination as? SelectedCatViewController, let indexPath = tableView.indexPathForSelectedRow {
            vc.catId = cats[indexPath.row].id
            vc.catName = cats[indexPath.row].titleString
        }
    }

}

class catsCell: UITableViewCell {
    
    @IBOutlet weak var titleLabelCell: UILabel!
}
