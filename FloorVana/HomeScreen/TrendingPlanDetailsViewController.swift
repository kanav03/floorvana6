//
//  Untitled.swift
//  FloorVana
//
//  Created by Navdeep    on 08/03/25.
//

//
//  TrendingPlanDetailsViewController.swift
//  FloorVana
//
//  Created by Navdeep on 08/03/25.
//

import UIKit
import SDWebImage
import Photos

class TrendingPlanDetailsViewController: UIViewController {
    
    @IBOutlet weak var planImageView: UIImageView!
    @IBOutlet weak var planTitleLabel: UILabel!
    @IBOutlet weak var exportButton: UIButton!
    
    var plan: Plan?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        if let plan = plan {
            planTitleLabel.text = plan.title
            if let url = URL(string: plan.imageURL) {
                planImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
            } else {
                planImageView.image = UIImage(named: "placeholder")
            }
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        planImageView.layer.cornerRadius = 10
        planImageView.layer.shadowColor = UIColor.black.cgColor
        planImageView.backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 0.95)
//        planImageView.layer.shadowOffset = CGSize(width: 3, height: 3)
//        planImageView.layer.shadowRadius = 6
//        planImageView.layer.shadowOpacity = 0.56
//        planImageView.layer.masksToBounds = false
        
    }
    
    // MARK: - Export Image Function
    @IBAction func exportImage(_ sender: UIButton) {
        guard let image = planImageView.image else {
            showAlert(title: "Error", message: "No image to save.")
            return
        }
        
        // Request photo library permission before saving
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
                } else {
                    self.showAlert(title: "Permission Denied", message: "Enable photo library access in settings to save images.")
                }
            }
        }
    }
    
    // MARK: - Image Save Callback
    @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: "Save Failed", message: error.localizedDescription)
        } else {
            showAlert(title: "Success", message: "Image saved to your Photos!")
        }
    }
    
    // MARK: - Helper Alert Function
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
