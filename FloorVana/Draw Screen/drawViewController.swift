import UIKit
import Photos

// Response structs for API
struct FloorPlanResponse: Codable {
    let message: String
    let status: FloorPlanStatus
    let paths: FloorPlanPaths
    let images: FloorPlanImages
    
    // Optionally include these fields for error handling
    let error: String?
    let visualization_error: String?
}

struct FloorPlanImages: Codable {
    let normalized: String
    let visualization: String?
}

struct FloorPlanStatus: Codable {
    let synthesis: String
    let normalization: String
    let visualization: String?
}

struct FloorPlanPaths: Codable {
    let synthesis: String
    let normalized: String
    let visualization: String?
}

// Create a singleton to store the generated image
class ImageDataStore {
    static let shared = ImageDataStore()
    var generatedImage: UIImage?
    
    private init() {}
}

class DrawViewController: UIViewController {

    @IBOutlet weak var canvasContainerView: UIView!
    @IBOutlet weak var inputDimensionsButton: UIButton!
   // @IBOutlet weak var uploadImageButton: UIButton! // New button for uploading image

    private var currentLine: CAShapeLayer?
    private var path = UIBezierPath()
    private var lastPoint: CGPoint?
    private var allLines: [(layer: CAShapeLayer, path: UIBezierPath, textLayer: CATextLayer?)] = []
    private let closeThreshold: CGFloat = 20
    private var startPoint: CGPoint?
    private var lengthTextLayer: CATextLayer?
    private var startPointLayer: CAShapeLayer?
    private var uploadedImage: UIImage? // To store the uploaded image
    private var tutorialOverlay: UIView?
    private var handImageView: UIImageView?
    private var isLoading: Bool = false
    private var loadingIndicator: UIActivityIndicatorView?
    private var scaleFactor: CGFloat = 76.2 // Default scale factor (pixels per foot)
    
    // Add a view your results button
    private var viewResultsButton: UIButton?

    // Properties for image processing
    private var points: [CGPoint] = []
    private var pointLayers: [CAShapeLayer] = []
    private var lineLayers: [CAShapeLayer] = []
    private var isDrawingComplete = false
    private let pointRadius: CGFloat = 6
    private let lineWidth: CGFloat = 8 // earliear was 9 change by nav
    private let imageSize: Int = 256
    private var image: UIImage!
    private var channelInfoLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCanvasView()
        setupNavigationButtons()
        setupLoadingIndicator()
        setupGestures()
        
        canvasContainerView.layer.borderColor = UIColor.lightGray.cgColor
        canvasContainerView.layer.borderWidth = 0.6
        // setupViewResultsButton()
        self.title = "Let's Plan"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21, weight: .bold)
        ]
        navigationController?.navigationBar.titleTextAttributes = attributes

        if isFirstLaunch() {
            showTutorialOverlay()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func navigateToGeneratedScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let generatedVC = storyboard.instantiateViewController(withIdentifier: "GeneratedScreen") as? GeneratedScreenViewController {
            // No need to pass the image directly, the view controller will get it from ImageDataStore
            self.navigationController?.pushViewController(generatedVC, animated: true)
        }
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator?.hidesWhenStopped = true
        loadingIndicator?.center = view.center
        if let loadingIndicator = loadingIndicator {
            view.addSubview(loadingIndicator)
        }
    }
    
    // MARK: - Tutorial Implementation
    private func isFirstLaunch() -> Bool {
        let launchedBefore = UserDefaults.standard.bool(forKey: "HasSeenTutorial")
        return !launchedBefore
    }

    private func showTutorialOverlay() {
        guard tutorialOverlay == nil else { return }

        if let window = UIApplication.shared.windows.first {
            tutorialOverlay = UIView(frame: window.bounds)
            tutorialOverlay?.backgroundColor = UIColor.black.withAlphaComponent(0.85)
            tutorialOverlay?.alpha = 0.0
            window.addSubview(tutorialOverlay!)
        }
        UIView.animate(withDuration: 0.3) {
            self.tutorialOverlay?.alpha = 1.0
        }

        let tutorialLabel = UILabel(frame: CGRect(x: 20, y: view.center.y - 250, width: view.bounds.width - 40, height: 60))
        tutorialLabel.text = "Tap to Draw the outlines  Please Start from Vertical line !"
        tutorialLabel.textColor = .white
        tutorialLabel.textAlignment = .center
        tutorialLabel.font = UIFont.boldSystemFont(ofSize: 22)
        tutorialLabel.numberOfLines = 2
        tutorialOverlay?.addSubview(tutorialLabel)

        handImageView = UIImageView(image: UIImage(systemName: "hand.point.up"))
        handImageView?.tintColor = .white
        handImageView?.frame = CGRect(x: view.center.x - 35, y: view.center.y - 100, width: 50, height: 50)
        tutorialOverlay?.addSubview(handImageView!)

        let drawingLayer = CAShapeLayer()
        drawingLayer.strokeColor = UIColor.white.cgColor
        drawingLayer.lineWidth = 6
        drawingLayer.fillColor = nil
        drawingLayer.lineCap = .round
        tutorialOverlay?.layer.addSublayer(drawingLayer)

        animateHandDrawing(with: drawingLayer)

        let gotItButton = UIButton(frame: CGRect(x: view.center.x - 80, y: view.center.y + 259, width: 170, height: 48))
        gotItButton.setTitle("Got It", for: .normal)

        gotItButton.layer.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1.0).cgColor

        gotItButton.setTitleColor(UIColor(red: 0.75, green: 0.6, blue: 0.25, alpha: 1.0), for: .normal)
        gotItButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        gotItButton.layer.cornerRadius = 12
        gotItButton.addTarget(self, action: #selector(dismissTutorial), for: .touchUpInside)
        tutorialOverlay?.addSubview(gotItButton)
    }
    
    
    private func animateHandDrawing(with drawingLayer: CAShapeLayer) {
        guard let hand = handImageView else { return }

        let squareSize: CGFloat = 240

            // Calculate the starting position to keep the square centered
            let startX = (view.bounds.width - squareSize) / 2
            let startY = (view.bounds.height - squareSize) / 2
        // Define points in anti-clockwise order
        let topLeft = CGPoint(x: startX, y: startY)
        let bottomLeft = CGPoint(x: startX, y: startY + squareSize)
        let bottomRight = CGPoint(x: startX + squareSize, y: startY + squareSize)
        let topRight = CGPoint(x: startX + squareSize, y: startY)

        let dotSize: CGFloat = 14.0 // Bigger dots
        let dotPositions = [topLeft, bottomLeft, bottomRight, topRight, topLeft] // Loop back to start

        func animateStep(index: Int) {
            guard index < dotPositions.count - 1 else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self else { return } // Prevent strong reference cycle
                    drawingLayer.sublayers?.removeAll()
                    self.animateHandDrawing(with: drawingLayer) // Restart animation
                }
                return
            }

            let currentPoint = dotPositions[index]
            let nextPoint = dotPositions[index + 1]

            // Move hand to tap first point
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                hand.center = currentPoint
            } completion: { _ in
                // Create dot
                let dotLayer = CAShapeLayer()
                let dotPath = UIBezierPath(ovalIn: CGRect(x: currentPoint.x - dotSize / 2,
                                                          y: currentPoint.y - dotSize / 2,
                                                          width: dotSize,
                                                          height: dotSize))
                dotLayer.path = dotPath.cgPath
                dotLayer.fillColor = UIColor.white.cgColor
                dotLayer.strokeColor = UIColor.clear.cgColor
                drawingLayer.addSublayer(dotLayer)

                // Move hand to tap second point
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                        hand.center = nextPoint
                    } completion: { _ in
                        // Create second dot
                        let nextDotLayer = CAShapeLayer()
                        let nextDotPath = UIBezierPath(ovalIn: CGRect(x: nextPoint.x - dotSize / 2,
                                                                      y: nextPoint.y - dotSize / 2,
                                                                      width: dotSize,
                                                                      height: dotSize))
                        nextDotLayer.path = nextDotPath.cgPath
                        nextDotLayer.fillColor = UIColor.white.cgColor
                        nextDotLayer.strokeColor = UIColor.clear.cgColor
                        drawingLayer.addSublayer(nextDotLayer)

                        // Draw line after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let lineLayer = CAShapeLayer()
                            let linePath = UIBezierPath()
                            linePath.move(to: currentPoint)
                            linePath.addLine(to: nextPoint)

                            lineLayer.path = linePath.cgPath
                            lineLayer.strokeColor = UIColor.black.cgColor
                            lineLayer.fillColor = UIColor.clear.cgColor
                            lineLayer.lineWidth = 4.0
                            lineLayer.lineCap = .round
                            drawingLayer.addSublayer(lineLayer)

                            // Continue to next step
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                animateStep(index: index + 1)
                            }
                        }
                    }
                }
            }
        }

        animateStep(index: 0) // Start animation
    }



    @objc private func dismissTutorial() {
        UIView.animate(withDuration: 0.3, animations: {
            self.tutorialOverlay?.alpha = 0.0
        }) { _ in
            self.tutorialOverlay?.removeFromSuperview()
            self.tutorialOverlay = nil
            self.handImageView?.layer.removeAllAnimations()
            UserDefaults.standard.set(true, forKey: "HasSeenTutorial")
        }
    }

    // MARK: - Canvas Setup
    private func setupCanvasView() {
        canvasContainerView.backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 0.95)
    }

    // MARK: - Undo and Clear Functions
    @objc private func undoLastLine() {
        // Check if we have any point to remove
        guard !points.isEmpty else { return }
        
        // If we have a complete shape, make it incomplete first
        if isDrawingComplete {
            isDrawingComplete = false
            
            // Remove the last line (the one that closes the shape)
            if let lastLineLayer = lineLayers.popLast() {
                lastLineLayer.removeFromSuperlayer()
            }
        } else {
            // Remove the last point
            points.removeLast()
            
            // Remove the last point marker
            if let lastPointLayer = pointLayers.popLast() {
                lastPointLayer.removeFromSuperlayer()
            }
            
            // Remove the last line connecting to this point (if there was one)
            if points.count > 0 && !lineLayers.isEmpty {
                if let lastLineLayer = lineLayers.popLast() {
                    lastLineLayer.removeFromSuperlayer()
                }
            }
        }
    }

    @objc private func clearCanvas() {
        // Remove all points
        points.removeAll()
        
        // Remove all point markers
        for layer in pointLayers {
            layer.removeFromSuperlayer()
        }
        pointLayers.removeAll()
        
        // Remove all lines
        for layer in lineLayers {
            layer.removeFromSuperlayer()
        }
        lineLayers.removeAll()
        
        // Reset drawing state
        isDrawingComplete = false
        
        // Also clear any uploaded image
        for subview in canvasContainerView.subviews {
            if subview is UIImageView {
                subview.removeFromSuperview()
            }
        }
        uploadedImage = nil
        
        // Clear the legacy drawing elements
        allLines.forEach {
            $0.layer.removeFromSuperlayer()
            $0.textLayer?.removeFromSuperlayer()
        }
        allLines.removeAll()
        lastPoint = nil

        startPointLayer?.removeFromSuperlayer()
        startPoint = nil
    }

    private func setupNavigationButtons() {
        let clearButton = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(clearCanvas))
        let undoButton = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.left"), style: .plain, target: self, action: #selector(undoLastLine))
        navigationItem.rightBarButtonItems = [clearButton, undoButton]
    }


    
    @IBAction func inputDimensionsTapped(_ sender: UIButton) {
        print("Saving Drawing...")
        
        // Check if we have enough points for a valid floor plan
        guard points.count >= 3 else {
            showAlert(message: "Please draw a complete floor plan with at least 3 points first.")
            return
        }
        
        // If the drawing isn't complete, close the shape
        if (!isDrawingComplete) {
            let firstPoint = points[0]
            let lastPoint = points.last!
            addLine(from: lastPoint, to: firstPoint)
            isDrawingComplete = true
        }
        
        // Generate the image from the current drawing
        let drawnImage = generateImage()
        
        // Store in ImageDataStore for possible later use
        ImageDataStore.shared.generatedImage = drawnImage
        
        // Start the loading indicator
        loadingIndicator?.startAnimating()
        
        // Disable the button to prevent multiple taps
        inputDimensionsButton.isEnabled = false
        
        // Process the image with your ML pipeline - using the corrected API URL
        if let imageData = drawnImage.pngData() {
            // Use the correct API endpoint
            sendImageToCorrectAPI(imageData: imageData)
        } else {
            showAlert(message: "Failed to process the drawing.")
            // Stop the loading indicator if image data is nil
            loadingIndicator?.stopAnimating()
            inputDimensionsButton.isEnabled = true
        }
    }


    private func sendImageToCorrectAPI(imageData: Data) {
        // Use the correct API URL
        let url = URL(string: "https://w960g57g-8000.inc1.devtunnels.ms/generate_floorplan")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set a longer timeout (15 minutes)
        request.timeoutInterval = 900.0
        
        // Create multipart/form-data with boundary
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Generate a unique filename
        let filename = "floorplan_\(UUID().uuidString).png"
        
        // Create the request body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("Starting API request to: \(url.absoluteString)")
        print("Image data size: \(imageData.count) bytes")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // Stop the loading indicator
                self.loadingIndicator?.stopAnimating()
                // Re-enable the button
                self.inputDimensionsButton.isEnabled = true
                
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    self.showAlert(message: "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid HTTP response")
                    self.showAlert(message: "Invalid server response")
                    return
                }
                
                print("Response received with status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("Server error: \(httpResponse.statusCode)")
                    
                    // Try to parse error message if available
                    if let data = data {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let errorMessage = json["error"] as? String {
                                self.showAlert(message: "Server error: \(errorMessage)")
                                return
                            }
                        } catch {
                            // Continue with generic error if JSON parsing fails
                        }
                    }
                    
                    self.showAlert(message: "Server error: \(httpResponse.statusCode)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    self.showAlert(message: "No data received from server")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(FloorPlanResponse.self, from: data)
                    
                    // First try visualization if available, fall back to normalized
                    let imageBase64 = response.images.visualization ?? response.images.normalized
                    
                    // Convert base64 string to image
                    guard let imageData = Data(base64Encoded: imageBase64) else {
                        print("Invalid base64 image data")
                        self.showAlert(message: "Invalid image data received")
                        return
                    }
                    
                    guard let image = UIImage(data: imageData) else {
                        print("Could not create image from data")
                        self.showAlert(message: "Could not create image from received data")
                        return
                    }
                    
                    // Store the generated image instead of immediately showing the generated screen
                    ImageDataStore.shared.generatedImage = image
                    
                    // Show success alert and navigate to GenerateViewController
                    self.showAlert(title: "Success", message: "Floor plan analyzed successfully!") {
                        // Perform segue to GenerateViewController
                        self.navigateToGenerateViewController()
                    }
                    
                } catch {
                    print("Error parsing response: \(error)")
                    self.showAlert(message: "Error parsing server response: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }

    
    // Helper method to navigate to GenerateViewController
    private func navigateToGenerateViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let generateVC = storyboard.instantiateViewController(withIdentifier: "GenerateViewController") as? HouseSpecificationsViewController {
            self.navigationController?.pushViewController(generateVC, animated: true)
        }
    }

    // Updated showAlert method with completion handler
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        self.present(alert, animated: true)
    }
    // Helper method to show alerts
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvasContainerView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: canvasContainerView)
        // Check if tapping near the first point to close the shape
        if points.count > 2 {
            let firstPoint = points[0]
            let distance = hypot(location.x - firstPoint.x, location.y - firstPoint.y)
            if distance < pointRadius * 2 {
                // Close the shape by adding a line back to the first point
                let lastPoint = points.last!
                addLine(from: lastPoint, to: firstPoint)
                isDrawingComplete = true
                return
            }
        }
        // Add new point
        points.append(location)
        addPointMarker(at: location)
        // Connect with previous point if exists
        if points.count > 1 {
            let previousPoint = points[points.count - 2]
            let currentPoint = points.last!
            addLine(from: previousPoint, to: currentPoint)
        }
    }

    private func addPointMarker(at point: CGPoint) {
        let pointLayer = CAShapeLayer()
        let path = UIBezierPath(arcCenter: point, radius: pointRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        pointLayer.path = path.cgPath
        pointLayer.fillColor = UIColor.white.cgColor
        pointLayer.strokeColor = UIColor.white.cgColor
        pointLayer.lineWidth = 2
        canvasContainerView.layer.addSublayer(pointLayer)
        pointLayers.append(pointLayer)
    }

    private func addLine(from startPoint: CGPoint, to endPoint: CGPoint) {
        let lineLayer = CAShapeLayer()
        let path = UIBezierPath()
        let deltaX = abs(endPoint.x - startPoint.x)
        let deltaY = abs(endPoint.y - startPoint.y)
        let straightEndPoint: CGPoint
        if deltaX > deltaY {
            straightEndPoint = CGPoint(x: endPoint.x, y: startPoint.y)
        } else {
            straightEndPoint = CGPoint(x: startPoint.x, y: endPoint.y)
        }
        path.move(to: startPoint)
        path.addLine(to: straightEndPoint)
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor.black.cgColor
        lineLayer.lineWidth = 6
        lineLayer.lineCap = .round
        canvasContainerView.layer.insertSublayer(lineLayer, below: pointLayers.first)
        lineLayers.append(lineLayer)
        if points.count > 1 && points.last != startPoint {
            points[points.count - 1] = straightEndPoint
        }
    }

    @objc private func generateButtonTapped() {
        guard points.count >= 3 else {
            showAlert(message: "Please add at least 3 points to create a floor plan.")
            return
        }
        if !isDrawingComplete {
            let firstPoint = points[0]
            let lastPoint = points.last!
            addLine(from: lastPoint, to: firstPoint)
            isDrawingComplete = true
        }
        let image = generateImage()
        ImageDataStore.shared.generatedImage = image
    }

    private func generateImage() -> UIImage {
        let size = CGSize(width: imageSize, height: imageSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.setShouldAntialias(true)
            context.cgContext.setAllowsAntialiasing(true)
            context.cgContext.interpolationQuality = .high
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            guard !points.isEmpty else { return }
            let scaleX = size.width / canvasContainerView.bounds.width
            let scaleY = size.height / canvasContainerView.bounds.height
            let scaledPoints = points.map { CGPoint(x: $0.x * scaleX, y: $0.y * scaleY) }
            UIColor(red: 127/255, green: 0, blue: 0, alpha: 1).setStroke()
            if !points.isEmpty {
                let wallPath = UIBezierPath()
                wallPath.move(to: scaledPoints[0])
                for i in 1..<scaledPoints.count {
                    wallPath.addLine(to: scaledPoints[i])
                }
                if isDrawingComplete && scaledPoints.count > 2 {
                    wallPath.addLine(to: scaledPoints[0])
                }
                wallPath.lineWidth = 7.2
                wallPath.lineCapStyle = .square
               
                wallPath.stroke()
                if isDrawingComplete {
                    let fillPath = UIBezierPath(cgPath: wallPath.cgPath)
                    fillPath.close()
                    UIColor.black.setFill()
                    fillPath.fill()
                }
            }
            if scaledPoints.count > 1 {
                let firstWallStart = scaledPoints[0]
                let firstWallEnd = scaledPoints[1]
                
                // Calculate the door vector direction
                let vectorX = firstWallEnd.x - firstWallStart.x
                let vectorY = firstWallEnd.y - firstWallStart.y
                let length = sqrt(vectorX * vectorX + vectorY * vectorY)
                
                // If we have a valid wall length, draw the door
                if length > 0 {
                    // Normalize the vector (make it unit length)
                    let normalizedVectorX = vectorX / length
                    let normalizedVectorY = vectorY / length
                    
                    // Door parameters
                    let doorLength = min(length * 0.15, 20) // 15% of wall length, but max 20 pixels
                    let doorWidth = 3.0 // Same as the line width
                    let offsetDistance = doorWidth /* / 2.0*/
                    // Offset from the wall edge
                    
                    // Calculate offset perpendicular to the wall for the door position
                    // This ensures the door is drawn ON the wall, not outside it
                    let perpVectorX = -normalizedVectorY * offsetDistance
                    let perpVectorY = normalizedVectorX * offsetDistance
                    
                    // Calculate door start and end points
                    let doorStartX = firstWallStart.x + perpVectorX
                    let doorStartY = firstWallStart.y + perpVectorY + 10
                    let doorEndX = doorStartX + normalizedVectorX * doorLength
                    let doorEndY = doorStartY + normalizedVectorY * doorLength
                    
                    // Draw the door
                    let doorPath = UIBezierPath()
                    doorPath.move(to: CGPoint(x: doorStartX, y: doorStartY))
                    doorPath.addLine(to: CGPoint(x: doorEndX, y: doorEndY))
                    doorPath.lineWidth = doorWidth
                    doorPath.lineCapStyle = .square
                    UIColor(red: 1, green: 0, blue: 0, alpha: 1).setStroke()
                    doorPath.stroke()
                }
            }
            UIColor(red: 0, green: 127/255, blue: 0, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    private func createIndexedPNG() -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let width = imageSize
        let height = imageSize
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data?.assumingMemoryBound(to: UInt8.self) else { return nil }
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let alpha = pixelData[offset + 3]
                if alpha < 128 {
                    pixelData[offset] = 0
                    pixelData[offset+1] = 0
                    pixelData[offset+2] = 0
                    pixelData[offset+3] = 0
                } else {
                    let r = pixelData[offset]
                    let g = pixelData[offset+1]
                    let b = pixelData[offset+2]
                    if r == 255 && g == 0 && b == 0 {
                        pixelData[offset] = 255
                        pixelData[offset+1] = 0
                        pixelData[offset+2] = 0
                        pixelData[offset+3] = 255
                    } else if r == 127 && g == 0 && b == 0 {
                        pixelData[offset] = 127
                        pixelData[offset+1] = 0
                        pixelData[offset+2] = 0
                        pixelData[offset+3] = 255
                    } else if g == 127 && r == 0 && b == 0 {
                        pixelData[offset] = 0
                        pixelData[offset+1] = 127
                        pixelData[offset+2] = 0
                        pixelData[offset+3] = 255
                    } else {
                        pixelData[offset] = 0
                        pixelData[offset+1] = 0
                        pixelData[offset+2] = 0
                        pixelData[offset+3] = 255
                    }
                }
            }
        }
        guard let outputImage = context.makeImage() else { return nil }
        return UIImage(cgImage: outputImage).pngData()
    }
}
