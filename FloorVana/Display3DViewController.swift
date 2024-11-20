//
//  Display3DViewController.swift
//  FloorVana
//
//  Created by Navdeep    on 13/11/24.
//

import UIKit

class Display3DViewController: UIViewController {
    
    @IBOutlet weak var preview3d: UIButton!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var capturedImage: UIImage?
    private var imageDataModel: Display3dDataModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageDataModel = Display3dDataModel.fetchImageData(capturedImage: capturedImage)
        
        imageView.image = UIImage(named: imageDataModel.image3DName)
        
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    @objc func segmentChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            imageView.image = UIImage(named: imageDataModel.image3DName)
        case 1:
            imageView.image = imageDataModel.image2D
        default:
            break
        }
    }
    
    @IBAction func preview3D(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Instantiate the view controller with identifier "capture"
        if let captureVC = mainStoryboard.instantiateViewController(withIdentifier: "d3show") as? ModelViewController {
            // Set modal presentation style to full screen
            captureVC.modalPresentationStyle = .fullScreen
            
            // Add a custom back button to dismiss the view controller
            captureVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(dismissCaptureVC))
            
            // Present modally within a navigation controller
            let navController = UINavigationController(rootViewController: captureVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true, completion: nil)
            
        }
    }
    @objc func dismissCaptureVC() {
        dismiss(animated: true, completion: nil)
    }

}
