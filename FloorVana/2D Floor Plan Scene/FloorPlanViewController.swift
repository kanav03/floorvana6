import UIKit
import SpriteKit

class FloorPlanViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBOutlet weak var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        if let skView = skView {
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            
            let scene = FloorPlanScene(size: skView.bounds.size)
            scene.scaleMode = .aspectFit
            
           
            skView.presentScene(scene)
            
        
            let pinchGesture = UIPinchGestureRecognizer(target: scene, action: #selector(scene.handlePinch(_:)))
            skView.addGestureRecognizer(pinchGesture)
            
            let panGesture = UIPanGestureRecognizer(target: scene, action: #selector(scene.handlePan(_:)))
            skView.addGestureRecognizer(panGesture)
        }
    }
}
