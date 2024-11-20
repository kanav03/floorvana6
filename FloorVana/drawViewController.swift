
import UIKit
import PencilKit

class DrawViewController: UIViewController, PKCanvasViewDelegate {
    
   
    @IBOutlet weak var canvasContainerView: UIView!
    @IBOutlet weak var inputDimensionsButton: UIButton!
    
    @IBOutlet weak var toggleToolPickerButton: UIButton!
    
    // MARK: - Properties
    private var canvasView = PKCanvasView()
    private var toolPicker: PKToolPicker!
    private var isToolPickerVisible = true
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        setupCanvasView()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupToolPicker()
    }
    
    // MARK: - Setup Canvas View
    private func setupCanvasView() {
       
        canvasView = PKCanvasView(frame: canvasContainerView.bounds)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .systemGray5
        canvasView.layer.cornerRadius = 15
        canvasView.layer.masksToBounds = true
        canvasView.layer.borderWidth = 1
        canvasView.layer.borderColor = UIColor.gray.cgColor
        
       
        canvasContainerView.addSubview(canvasView)
        
        
        NSLayoutConstraint.activate([
            canvasView.leadingAnchor.constraint(equalTo: canvasContainerView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: canvasContainerView.trailingAnchor),
            canvasView.topAnchor.constraint(equalTo: canvasContainerView.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: canvasContainerView.bottomAnchor)
        ])
    }
    
    // MARK: - Setup Tool Picker
    private func setupToolPicker() {
       
        if let window = view.window {
            toolPicker = PKToolPicker.shared(for: window)
        } else {
            toolPicker = PKToolPicker()
        }
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
    }
    
    // MARK: - Actions
    @IBAction func inputDimensionsTapped(_ sender: UIButton) {
        print("Input Dimensions button tapped")
    }
    
   
    @IBAction func toggleToolPickerTapped(_ sender: UIButton) {
        if isToolPickerVisible {
            toolPicker.setVisible(false, forFirstResponder: canvasView)
            toggleToolPickerButton.setImage(UIImage(systemName: "pencil.tip.crop.circle"), for: .normal)
        } else {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toggleToolPickerButton.setImage(UIImage(systemName: "pencil.tip.crop.circle.fill"), for: .normal)
        }
        isToolPickerVisible.toggle()
    }
}
