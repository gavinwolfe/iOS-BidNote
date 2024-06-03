//
//  HelpViewController.swift
//  BidNote
//
//  Created by Gavin Wolfe on 11/15/23.
//

import UIKit

class HelpViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    
    @IBOutlet weak var tableView: UITableView!
    
    var items = ["Wait what's this whole commission thing?", "So let's say you made a great study guide for Psychology 101. You post it to BidNote and select $2.00 to be the price. Enter a valid email/phone number and click post. You'll hear back shortly if your material and merchant application is approved (within 30mins). When someone purchases the material in the app, BidNote is the seller. You the author recieve a commission between 65%-75% of the original price. Each day you will recieve a commission payout total to your valid PayPal or Venmo account. Welcome to the new way to study and learn.", "How does tutoring work?", "Tutoring is a form of material avaible on BidNote. Tutoring on BidNote is done asynchronously. Unlike other tutoring apps, BidNote ensures that tutoring content is high quality and informative prior to a users purchase. This means that tutors can create guided video lessons and informative lecture-style lessons. These tutoring services can be one-time or multi-lesson material. ", "So everyone can see my Venmo or PayPal account now? NO!", "We know that your privacy and security are important to you. This is why BidNote DOES NOT give any PayPal or Venmo account information (including email/phone numbers) to anyone on the app. This includes students who purchase material, post material, create material, and recieve payout commissions + vice versa. BidNote is the seller. We take the payment for lessons/tutoring. Then reward a commission payout to the author each day. That's it. No one sees your private information, the way it should be.", "What material/tutoring services can I offer on BidNote?", "Any educational content that is created by you or can be credited to you is allowed. This includes video tutoring lessons, practice study guides, notes, notetaking, hand-written or typed lessons, or many other forms of goods/services. What is not allowed is copyrighted content. You cannot offer other people's work or content as a good/service on the app. In instances where tutoring/lesson content may seem copyrighted: BidNote may contact the author before being approved. Any material that contains visibly copyrighted content will be rejected. Please see our terms of service and privacy page at bidnoteapp.com for further information.", "BidNote In App Purchase Tier System", "Because educational goods/services range in price on BidNote, we have implemented a tier system for pricing. All in app purchases include access to goods or services created by educators + author support. The quality and substance of these Goods/Services are dependent on the tier. Tiers and Prices: Tier1 ($0.99), Tier2 ($1.99), Tier3 ($2.99), Tier4 ($3.99), Tier5 ($4.99), Tier6 ($5.99), Tier7 ($6.99), Tier8 ($7.99), Tier10 ($9.99), Tier13 ($12.99), Tier15 ($14.99), and Tier20 ($19.99). Please note that quality and extensiveness of material/tutoring increases with Tier value.","What should I do if I get a new phone/reinstall the app?", "Contact a BidNote administrator through our support email: bidnoteconnect@gmail.com Please have the names of the purchased material, last four digits of the card you paid with, and the PIN you created ready. You will get a response with further details within 3 business days.", "Who do I contact if I have any errors with my account/general questions?", "Please email bidnoteconnect@gmail.com your question and information/problem. We usually get back withing 1-3 business days. Also visit our website bidnoteapp.com", "What should I know about taxes?", "BidNote recieves a 1099k from PayPal at the end of each tax year. This 1099k details all transactions, and is used in BidNote's yearly filing. Please note this excerpt from PayPal's tax clause: PayPal tax reporting is required when the sender identifies the product as goods and services to the IRS, even if it was a mistake. This requirement applies once you receive $600 USD or more from this type of payment. So merchants on BidNote are legally required to disclose commission payments recieved, to the IRS, if the total yearly amount exceeds $600 and must do so in Schedule C of their personal tax returns. For more information please see the irs infomration button at the top of the Your Commission Payouts section in the BidNote app.", "How do I claim my commission payout?", "You only need to 'claim' a commission payout when the Venmo or PayPal account you specified does not already have an account linked to that email/phone number. If you entered the correct email or phone number connected to your Active PayPal or Venmo account: You should recieve the commission payout for total daily sales within 24 hours. If you entered an in-active Venmo or PayPal account, read as follows: You have within 5 Days to claim each commission payout to that account. If you entered a phone number that is not linked to a Venmo/PayPal account. The phone number you specified will recieve a text message asking you to claim the commission. If you entered an email that is not linked to a Venmo/PayPal account, that email will recieve an email prompting you to claim the rewards. If you do not claim the commission and create a new PayPal/Venmo account with that email/phone number within 5 days: the payout will be redacted. If you entered an email or phone number that ended up linking to the wrong Venmo/Paypal account or no account. You MUST email BidNote within 48hours of the FIRST commission payout. If and only if the commission has not been claimed, then we can correct this for you and add the new account details and payout to the next daily payout. Please email BidNote ASAP in the case of this. bidnoteconnect@gmail.com.", "Do you like this app and want to be part of the team?", "BidNote LLC is a small startup who's team are UCSB / Isla Vista residents. If you want to be part of this movement, please contact the founders email: gavin@bidnoteapp.com. We are looking for people that are passionate about seeing BidNote on colleges across the world. No college degree required. Look forward to talking soon! (:"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 68.0
        tableView.rowHeight = UITableView.automaticDimension
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if  indexPath.row == 0 || indexPath.row == 2 || indexPath.row == 4 || indexPath.row == 6 || indexPath.row == 8 || indexPath.row == 10 || indexPath.row == 12 || indexPath.row == 14 || indexPath.row == 16 || indexPath.row == 18 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellBoldHelp", for: indexPath) as? cellBoldHelp
            cell?.labelData.text = items[indexPath.row]
            return cell ?? UITableViewCell()
        } else if indexPath.row == 1 || indexPath.row == 3 || indexPath.row == 5 || indexPath.row == 7 || indexPath.row == 9 || indexPath.row == 11 || indexPath.row == 13 || indexPath.row == 15 || indexPath.row == 17 || indexPath.row == 19 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellRegHelp", for: indexPath) as? cellRegHelp
            cell?.labelData.text = items[indexPath.row]
            return cell ?? UITableViewCell()
        }
        return UITableViewCell()
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
class cellBoldHelp: UITableViewCell {
    
    @IBOutlet weak var labelData: UILabel!
    
    
}
class cellRegHelp: UITableViewCell {
    
    
    @IBOutlet weak var labelData: UILabel!
    
}
