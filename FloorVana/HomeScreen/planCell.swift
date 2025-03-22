//
//  planCell.swift
//  FloorVana
//
//  Created by Navdeep    on 08/03/25.
//

import UIKit

class PlanCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cardView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Card Aesthetic Styling
//        cardView.layer.cornerRadius = 10
//        cardView.backgroundColor = UIColor.systemGray4
//        cardView.layer.shadowColor = UIColor.black.cgColor
//        cardView.layer.shadowOffset = CGSize(width: 3.0, height: 4.0)
//        cardView.layer.shadowRadius = 2.0
//        cardView.layer.shadowOpacity = 0.5
//        cardView.layer.masksToBounds = false
        
        cardView.layer.cornerRadius = 10
        cardView.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
        

        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 1, height:1)
        cardView.layer.shadowRadius = 3
        cardView.layer.shadowOpacity = 0.37
        cardView.layer.masksToBounds = false
        
        // Image Styling
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.layer.backgroundColor = UIColor.white.cgColor
        
        // Label Styling
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        

    }
}

