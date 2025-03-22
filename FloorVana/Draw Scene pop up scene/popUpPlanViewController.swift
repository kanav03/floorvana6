//
//  popUpPlanViewController.swift
//  FloorVana
//
//  Created by Navdeep    on 18/11/24.
//

import UIKit

class popUpPlanViewController: UIViewController {
    
    @IBOutlet weak var gettStart: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    @objc func dismissCaptureVC() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func gettStart(_ sender: UIButton) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        
        if let drawVC = mainStoryboard.instantiateViewController(withIdentifier: "drawViewController") as? DrawViewController {
            
            
            if let navigationController = self.navigationController {
                navigationController.pushViewController(drawVC, animated: true)
            } else {
                
                print("Error: No Navigation Controller available.")
            }
        }
    }
      
        
    }

