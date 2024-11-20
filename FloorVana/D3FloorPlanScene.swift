import SpriteKit

class D3FloorPlanScene: SKScene {
    private var floorPlanNode: SKSpriteNode?
    private var lastScale: CGFloat = 1.0
    private var initialScale: CGFloat = 1.0
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        
       
        createGridBackground()
        
     
        let floorPlan2 = SKSpriteNode(imageNamed: "b")
        floorPlan2.position = CGPoint(x: frame.midX, y: frame.midY)
        floorPlan2.setScale(1.0)  // Initial scale
        addChild(floorPlan2)
        self.floorPlanNode = floorPlan2
        
       
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
        guard let floorPlan2 = floorPlanNode else { return }
        
        if gesture.state == .began {
            initialScale = floorPlan2.xScale
            lastScale = gesture.scale
        }
        
      
        let scale = gesture.scale
        let deltaScale = scale / lastScale
        lastScale = scale
        
        let newScale = floorPlan2.xScale * deltaScale
        if newScale >= 0.5 && newScale <= 3.0 {
            floorPlan2.setScale(newScale)
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let floorPlan2 = floorPlanNode else { return }
        
        let translation = gesture.translation(in: gesture.view)
        let newPosition = CGPoint(
            x: floorPlan2.position.x + translation.x,
            y: floorPlan2.position.y - translation.y  
        )
        
        floorPlan2.position = newPosition
        gesture.setTranslation(.zero, in: gesture.view)
    }
}
