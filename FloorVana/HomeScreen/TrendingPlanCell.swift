//
//  TrendingPlanCell.swift
//  FloorVana
//
//  Created by Navdeep    on 08/03/25.
//

import UIKit

class TrendingPlanCell: UICollectionViewCell {
    
    @IBOutlet weak var planImageView: UIImageView!
    @IBOutlet weak var planTitleLabel: UILabel!
    
    @IBOutlet weak var cardView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Card Aesthetic Styling
        
        cardView.layer.cornerRadius = 10
        cardView.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 1, height:1)
        cardView.layer.shadowRadius = 3
        cardView.layer.shadowOpacity = 0.37
        cardView.layer.masksToBounds = false
        
//        cardView.layer.cornerRadius = 10
//        cardView.layer.shadowColor = UIColor.black.cgColor
//        cardView.layer.shadowOpacity = 0.2
//        cardView.layer.shadowOffset = CGSize(width: 3, height: 3)
//        cardView.layer.shadowRadius = 6
//        cardView.backgroundColor = UIColor.systemGray4
//        
        
        
        // Image Styling
        planImageView.layer.cornerRadius = 10
        planImageView.layer.masksToBounds = true
        planImageView.backgroundColor = .white
        planTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        planTitleLabel.textColor = .black
        planTitleLabel.textAlignment = .center
    }
}

