//
//  Note.swift
//  BidNote
//
//  Created by Gavin Wolfe on 2/20/23.
//

import UIKit

class Note: NSObject {

    var id: String!
    var titleString: String!
    var subTitle: String!
    var images:[UIImage]!
    var bidValue: Double!
    var currentBid: Double!
    var inAnswering: Bool!
    var answered: Bool!
    var answerers: [String : Int]!
    var comments: [String : String]!
    var likes: Int!
    var dislikes: Int!
    var timeStamp: Int!
    
    
}

class Solution: NSObject {
    
    var id: String!
    var titleString: String!
    var subTitle: String!
    var cost: Double!
    var images: [UIImage]!
    var likes: Int!
    var dislikes: Int!
    var flagged: Bool!
    var reviews: [String : String]!
    
}


class solutionObject: NSObject {
    var id: String!
    var titleString: String!
    var descipt: String!
    var tags: [String]!
    var likes: [String]!
    var dislikes: [String]!
    var price: Double!
    var time: Int!
    var percentLike: Int!
    var coverImage: String!
    var timeString: String!
    var weight: Int!
    var creatorId: String!
}

class categori: NSObject {
    var id: String!
    var titleString: String!
    var isFollowing: Bool!
}

class photo: NSObject {
    var id: String!
    var imager: UIImage! 
}

class purchasedObject: NSObject {
    var id: String!
    var titleString: String!
}

class review: NSObject {
    var id: String!
    var userId: String!
    var reviewString: String!
    var time: Int!
}
class adminReviewObject: NSObject {
    var type: String!
    var images: [String]!
    var userId: String!
    var payoutId: String!
    var titleString: String!
    var descript: String!
    var usingRating:Int!
    var usersFirstPost: Bool!
    var phoneId: String!
    var possibleRisk: Int!
    var userBanned: Bool!
    var sid: String!
    var purchased: [String]!
    var approvedCount: Int!
    var userJoinTime: Int!
    var createdTime: Int!
    var price: Double!
    var update: String!
    var tags: [String]!
    var solLink: String?
    var isJustImageUpdate: Bool!
}

class inboxObject: NSObject {
    var id: String!
    var contentString: String!
    var iconImage: String!
    var type: String!
    var time: Int!
    var read: Int!
}

class taxInfoObject: NSObject {
    var timeCompleted: Int!
    var pricePaid: Double!
    var timeString: String!
}
class imageObj: NSObject {
    var order: Int!
    var url: String!
    var img: UIImage!
}
class adminPayoutObject: NSObject {
    var key: String!
    var timeVal: Int!
    var payoutNumber: Int!
    var idsAndPayTotals: [String]!
}
