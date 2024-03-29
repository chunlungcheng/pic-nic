//
//  PostCell.swift
//  Pic-nic
//
//  Created by Isaiah Suarez on 3/4/23.
//

import UIKit

class PostCell: UITableViewCell {
    static let reuseIdentifer = "PostCell"
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var savePhotoButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likesButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var commentButton: UIButton!
    
    func animateHeart() {
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.2, options: .allowUserInteraction, animations: {
            self.heartImageView.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
            self.heartImageView.alpha = 1.0
        }) { finished in
            UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction, animations: {
                self.heartImageView.alpha = 0.0
                self.heartImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        }
    }
}
