import SpriteKit

class FloorPlanScene: SKScene {
    private var floorPlanNode: SKSpriteNode?
    private var lastScale: CGFloat = 1.0
    private var initialScale: CGFloat = 1.0
    
  
    var selectedImageName: String = ""

    override func didMove(to view: SKView) {
        backgroundColor = .white
        
       
        createGridBackground()
        
       
        let floorPlan = SKSpriteNode(imageNamed: "myProject3")
        floorPlan.position = CGPoint(x: frame.midX, y: frame.midY)
        floorPlan.setScale(1.0)
        addChild(floorPlan)
        self.floorPlanNode = floorPlan
        
        view.isMultipleTouchEnabled = true
    }

    private func createGridBackground() {
        let gridTexture = SKTexture(imageNamed: "grid")
        let backgroundNode = SKSpriteNode(texture: gridTexture)
        
        backgroundNode.size = self.size
        backgroundNode.position = CGPoint(x: frame.midX, y: frame.midY)
        backgroundNode.zPosition = -1
        
        addChild(backgroundNode)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let floorPlan = floorPlanNode else { return }
        
        if gesture.state == .began {
            initialScale = floorPlan.xScale
            lastScale = gesture.scale
        }
        
        let scale = gesture.scale
        let deltaScale = scale / lastScale
        lastScale = scale
        
        let newScale = floorPlan.xScale * deltaScale
        if newScale >= 0.5 && newScale <= 3.0 {
            floorPlan.setScale(newScale)
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let floorPlan = floorPlanNode else { return }
        
        let translation = gesture.translation(in: gesture.view)
        let newPosition = CGPoint(
            x: floorPlan.position.x + translation.x,
            y: floorPlan.position.y - translation.y
        )
        
        floorPlan.position = newPosition
        gesture.setTranslation(.zero, in: gesture.view)
    }
}
