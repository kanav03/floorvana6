import SwiftUI
import SceneKit
import UIKit
import ModelIO
import SceneKit.ModelIO

// MARK: - Data Models

struct FloorPlanData: Codable {
    let height: Double
    let width: Double
    let averageDoor: Double
    let classes: [ClassElement]
    let points: [Point]
    
    // Add coding keys to handle the capitalized keys from the backend
    enum CodingKeys: String, CodingKey {
        case height = "Height"
        case width = "Width"
        case averageDoor = "averageDoor"
        case classes = "classes"
        case points = "points"
    }
}

struct ClassElement: Codable {
    let name: String
}

struct Point: Codable {
    let x1: Double
    let x2: Double
    let y1: Double
    let y2: Double
}

// MARK: - Main SwiftUI View

struct FloorPlanView: View {
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var floorPlanData: FloorPlanData? = nil
    @State private var selectedImage: UIImage?
    @State private var showingShareSheet = false
    @State private var exportURL: URL? = nil
    
    // Add initializer to accept image from GeneratedScreenViewController
    init(generatedImage: UIImage? = nil) {
        _selectedImage = State(initialValue: generatedImage)
        print("FloorPlanView initialized with image: \(generatedImage != nil ? "yes" : "no")")
    }
    // Define a constant for the gold color to ensure consistency
    private let goldColor = UIColor(red: 199/255, green: 180/255, blue: 105/255, alpha: 1.0)
    
    var body: some View {
        ZStack {
            if let data = floorPlanData {
                FloorPlan3DView(floorPlanData: data, onExportModel: { url in
                    self.exportURL = url
                    self.showingShareSheet = true
                })
            } else {
                VStack(spacing: 20) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300) // Increased from 200 to 300
                            .cornerRadius(8)
                    } else {
                        Text("No image selected")
                            .foregroundColor(.gray)
                    }
                    
                    if isLoading {
                        ProgressView("Processing image...")
                            .padding()
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .multilineTextAlignment(.center)
                    }
                    
                    // Add a manual processing button for testing
                    if let _ = selectedImage, !isLoading {
                        Button("Process Floor Plan") {
                            if let img = selectedImage {
                                processFloorPlanImage(image: img)
                            }
                        }
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .onAppear {
                    // Auto-process the image if we received one from GeneratedScreenViewController
                    if let image = selectedImage {
                        print("FloorPlanView appeared with image, size: \(image.size)")
                        if floorPlanData == nil && !isLoading {
                            print("Auto-processing floor plan image...")
                            processFloorPlanImage(image: image)
                        }
                    } else {
                        print("FloorPlanView appeared without an image")
                    }
                }
            }
        }
        .navigationBarTitle("3D Floor Plan", displayMode: .inline)
        .navigationBarItems(
            trailing: Group {
                if floorPlanData != nil {
                    HStack {
                        Button(action: {
                            // This will trigger the export process in FloorPlan3DView
                            NotificationCenter.default.post(name: .exportModelRequested, object: nil)
                            
                            // Add a small delay to ensure the export process completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if !showingShareSheet && exportURL != nil {
                                    showingShareSheet = true
                                }
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(UIColor(red: 199/255, green: 180/255, blue: 105/255, alpha: 1.0)))
                        }
                        
                        Button(action: {
                            floorPlanData = nil
                            print("Reset button pressed, clearing floor plan data")
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color(UIColor(red: 199/255, green: 180/255, blue: 105/255, alpha: 1.0)))
                        }
                    }
                } else {
                    Button(action: {
                        floorPlanData = nil
                        print("Reset button pressed, clearing floor plan data")
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(UIColor(red: 199/255, green: 180/255, blue: 105/255, alpha: 0.5))) // Semi-transparent when disabled
                    }
                    .disabled(true)
                }
            }
        )
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func processFloorPlanImage(image: UIImage) {
        print("Starting to process image with dimensions: \(image.size.width) x \(image.size.height)")
        isLoading = true
        errorMessage = nil
        
        // Check if image has content
        if image.cgImage == nil && image.ciImage == nil {
            print("WARNING: Image has no content (cgImage and ciImage are nil)")
            isLoading = false
            errorMessage = "Invalid image - no content"
            return
        }
        
        // Check image type and convert to appropriate format
        let imageData: Data?
        let mimeType: String
        let filename: String
        
        // Try PNG first as it's lossless
        if let pngData = image.pngData() {
            print("Converting image to PNG format")
            imageData = pngData
            mimeType = "image/png"
            filename = "floorplan.png"
        } else if let jpegData = image.jpegData(compressionQuality: 0.8) {
            print("Converting image to JPEG format")
            imageData = jpegData
            mimeType = "image/jpeg"
            filename = "floorplan.jpg"
        } else {
            print("ERROR: Failed to convert image to PNG or JPEG format")
            isLoading = false
            errorMessage = "Failed to process image - unsupported format"
            return
        }
        
        guard let data = imageData else {
            print("ERROR: Failed to get image data after conversion")
            isLoading = false
            errorMessage = "Failed to process image"
            return
        }
        
        print("Image data size: \(data.count) bytes")
        
        // Create URL request
        let url = URL(string: "https://floorplan-api-344505445307.us-central1.run.app")!
        print("Sending request to URL: \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        print("Using boundary: \(boundary) for multipart form data")
        
        // Prepare body
        var body = Data()
        
        // Add image data - CHANGED "file" to "image" to match Flask backend expectation
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close the form
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set the body to the request
        request.httpBody = body
        print("Request body size: \(body.count) bytes")
        
        // Create the URL session task
        print("Starting network request...")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print("Network request completed")
            if let error = error {
                print("Network error: \(error)")
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP status code: \(httpResponse.statusCode)")
                print("HTTP headers: \(httpResponse.allHeaderFields)")
            }
            if let data = data {
                print("Received \(data.count) bytes of data")
                // Try to print the first bit of the response
                if let responseString = String(data: data.prefix(500), encoding: .utf8) {
                    print("Response preview: \(responseString)")
                }
            } else {
                print("No data received from the server")
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Setting error message for network error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid HTTP response")
                    self.errorMessage = "Invalid response from server"
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    print("Non-200 status code: \(httpResponse.statusCode)")
                    self.errorMessage = "Server error: Status \(httpResponse.statusCode)"
                    return
                }
                
                guard let data = data else {
                    print("No data in response")
                    self.errorMessage = "No data received from server"
                    return
                }
                
                do {
                    // For debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response data: \(responseString)")
                    }
                    
                    print("Attempting to decode JSON response...")
                    let decoder = JSONDecoder()
                    let decodedData = try decoder.decode(FloorPlanData.self, from: data)
                    print("Successfully decoded JSON data")
                    print("Floor plan dimensions: \(decodedData.width) x \(decodedData.height)")
                    print("Number of elements: \(decodedData.classes.count)")
                    self.floorPlanData = decodedData
                } catch {
                    print("JSON Decoding error: \(error)")
                    
                    // Try to get more information about the error
                    if let responseString = String(data: data, encoding: .utf8) {
                        self.errorMessage = "Failed to decode response: \(error.localizedDescription)\nResponse: \(responseString.prefix(100))..."
                    } else {
                        self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        // Start the task
        print("Starting URLSession task")
        task.resume()
    }
}

// MARK: - Export Notification

extension Notification.Name {
    static let exportModelRequested = Notification.Name("exportModelRequested")
}

// MARK: - ShareSheet for iOS export

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - SceneKit View Container

struct FloorPlan3DView: UIViewRepresentable {
    var floorPlanData: FloorPlanData
    var onExportModel: (URL) -> Void
    
    func makeUIView(context: Context) -> SCNView {
        print("Creating SCNView")
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = UIColor(red: 0.1, green: 0.12, blue: 0.15, alpha: 1.0) // Dark blue-gray
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.isJitteringEnabled = true
        
        // Add export observer
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.exportModel),
            name: .exportModelRequested,
            object: nil
        )
        
        return sceneView
    }
    
    func updateUIView(_ sceneView: SCNView, context: Context) {
        print("Updating SCNView with floor plan data")
        sceneView.scene?.rootNode.childNodes.forEach { node in
            if node.name != "camera" && node.name != "light" {
                node.removeFromParentNode()
            }
        }
        context.coordinator.sceneView = sceneView
        setupScene(sceneView: sceneView)
        renderFloorPlan(sceneView: sceneView, data: floorPlanData)
        print("Floor plan rendering complete")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: FloorPlan3DView
        var sceneView: SCNView?
        
        init(_ parent: FloorPlan3DView) {
            self.parent = parent
        }
        
        @objc func exportModel() {
            guard let sceneView = sceneView, let scene = sceneView.scene else {
                print("Cannot export: Scene not available")
                return
            }
            
            print("Starting 3D model export process")
            
            // Use the app's documents directory which is accessible through the Files app
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            print("Documents directory: \(documentsDirectory.path)")
            
            // Create a FloorPlans subdirectory if it doesn't exist
            let floorPlansDirectory = documentsDirectory.appendingPathComponent("FloorPlans", isDirectory: true)
            
            do {
                try FileManager.default.createDirectory(at: floorPlansDirectory, withIntermediateDirectories: true, attributes: nil)
                print("Created FloorPlans directory at: \(floorPlansDirectory.path)")
            } catch {
                print("Error creating FloorPlans directory: \(error)")
                // Continue anyway, using the documents directory
            }
            
            // Try OBJ format first as it's most widely supported
            let timestamp = Int(Date().timeIntervalSince1970)
            let objFileName = "FloorPlan_\(timestamp).obj"
            let objURL = floorPlansDirectory.appendingPathComponent(objFileName)
            
            do {
                // Create an MDLAsset from the SCNScene
                let asset = MDLAsset(scnScene: scene)
                
                // Export to OBJ format
                try asset.export(to: objURL)
                print("Successfully exported OBJ to: \(objURL.path)")
                
                // Make sure the file exists before sharing
                if FileManager.default.fileExists(atPath: objURL.path) {
                    // Pass the OBJ file URL back to the parent view
                    DispatchQueue.main.async {
                        self.parent.onExportModel(objURL)
                    }
                } else {
                    throw NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "File was not created"])
                }
            } catch {
                print("Error during OBJ export: \(error)")
                
                // Try a simpler approach - save a screenshot of the 3D view
                let snapshot = sceneView.snapshot()
                let imageFileName = "FloorPlan_\(timestamp).png"
                let imageURL = floorPlansDirectory.appendingPathComponent(imageFileName)
                
                if let pngData = snapshot.pngData() {
                    do {
                        try pngData.write(to: imageURL)
                        print("Saved screenshot to: \(imageURL.path)")
                        
                        DispatchQueue.main.async {
                            self.parent.onExportModel(imageURL)
                        }
                        return
                    } catch {
                        print("Error saving screenshot: \(error)")
                    }
                }
                
                // If all else fails, show an error alert
                DispatchQueue.main.async {
                    let alertController = UIAlertController(
                        title: "Export Failed",
                        message: "Could not export the 3D model. Error: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    
                    // Find the top-most view controller to present the alert
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        var topController = rootViewController
                        while let presentedController = topController.presentedViewController {
                            topController = presentedController
                        }
                        topController.present(alertController, animated: true)
                    }
                }
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // MARK: - Scene Setup
    
    private func setupScene(sceneView: SCNView) {
        print("Setting up 3D scene")
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 500
        cameraNode.position = SCNVector3(x: 0, y: 35, z: 25)
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi/3.5, y: 0, z: 0)
        cameraNode.name = "camera"
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        // Improved lighting setup for better contrast
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.white.withAlphaComponent(0.5) // Reduced from 0.7 to 0.5
        ambientLight.name = "light"
        sceneView.scene?.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.eulerAngles = SCNVector3(x: -Float.pi/3, y: Float.pi/4, z: 0)
        directionalLight.light?.intensity = 2000 // Increased from 1500 to 2000
        directionalLight.light?.castsShadow = true
        directionalLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.7) // Added shadow color
        directionalLight.name = "light"
        sceneView.scene?.rootNode.addChildNode(directionalLight)
        
        // Add a second directional light from another angle for better illumination
        let secondaryLight = SCNNode()
        secondaryLight.light = SCNLight()
        secondaryLight.light?.type = .directional
        secondaryLight.eulerAngles = SCNVector3(x: -Float.pi/4, y: -Float.pi/4, z: 0)
        secondaryLight.light?.intensity = 800
        secondaryLight.name = "light"
        sceneView.scene?.rootNode.addChildNode(secondaryLight)
        
        addGroundPlane(sceneView: sceneView)
        print("Scene setup complete")
    }
    
    // MARK: - 3D Rendering
    
    private func renderFloorPlan(sceneView: SCNView, data: FloorPlanData) {
        print("Rendering floor plan - width: \(data.width), height: \(data.height)")
        let scaleFactor: CGFloat = 0.05
        let wallHeight: CGFloat = 5.0
        let wallThickness: CGFloat = 0.57
        
        let floorPlanNode = SCNNode()
        floorPlanNode.name = "floorPlan"
        sceneView.scene?.rootNode.addChildNode(floorPlanNode)
        
        addFloor(parentNode: floorPlanNode, width: CGFloat(data.width), height: CGFloat(data.height), scaleFactor: scaleFactor)
        
        // First pass: render all walls to ensure complete coverage
        for (index, classElement) in data.classes.enumerated() {
            guard index < data.points.count else {
                print("Warning: Missing point data for element \(index)")
                continue
            }
            
            if classElement.name == "wall" {
                let point = data.points[index]
                // Add a small buffer to wall endpoints to ensure they connect properly
                let bufferedPoint = Point(
                    x1: point.x1 - 0.1,
                    x2: point.x2 + 0.1,
                    y1: point.y1 - 0.1,
                    y2: point.y2 + 0.1
                )
                
                addWall(
                    parentNode: floorPlanNode,
                    point: bufferedPoint,
                    planWidth: CGFloat(data.width),
                    planHeight: CGFloat(data.height),
                    wallHeight: wallHeight,
                    wallThickness: wallThickness,
                    scaleFactor: scaleFactor
                )
            }
        }
        
        // Second pass: render doors and windows
        for (index, classElement) in data.classes.enumerated() {
            guard index < data.points.count else { continue }
            let point = data.points[index]
            
            switch classElement.name {
            case "door":
                addDoor(
                    parentNode: floorPlanNode,
                    point: point,
                    planWidth: CGFloat(data.width),
                    planHeight: CGFloat(data.height),
                    wallHeight: wallHeight,
                    wallThickness: wallThickness,
                    scaleFactor: scaleFactor
                )
            case "window":
                addWindow(
                    parentNode: floorPlanNode,
                    point: point,
                    planWidth: CGFloat(data.width),
                    planHeight: CGFloat(data.height),
                    wallHeight: wallHeight,
                    wallThickness: wallThickness,
                    scaleFactor: scaleFactor
                )
            default:
                break
            }
        }
        print("Finished rendering all \(data.classes.count) elements")
    }
    
    private func addGroundPlane(sceneView: SCNView) {
        print("Adding ground plane")
        let floor = SCNFloor()
        floor.reflectivity = 0.1 // Reduced from 0.15 to 0.1
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = UIColor(red: 0.1, green: 0.12, blue: 0.15, alpha: 1.0)
        floor.materials = [floorMaterial]
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(x: 0, y: -0.1, z: 0)
        sceneView.scene?.rootNode.addChildNode(floorNode)
    }
    
    private func addFloor(parentNode: SCNNode, width: CGFloat, height: CGFloat, scaleFactor: CGFloat) {
        print("Adding floor with dimensions: \(width * scaleFactor) x \(height * scaleFactor)")
        let floorGeometry = SCNBox(
            width: width * scaleFactor,
            height: 0.5,
            length: height * scaleFactor,
            chamferRadius: 0
        )
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = UIColor.systemGray4 // Slightly darker
        floorGeometry.materials = [floorMaterial]
        
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.position.y = -0.05
        parentNode.addChildNode(floorNode)
    }
    
    private func addWall(parentNode: SCNNode, point: Point, planWidth: CGFloat, planHeight: CGFloat, wallHeight: CGFloat, wallThickness: CGFloat, scaleFactor: CGFloat) {
        print("Adding wall")
        let (box, position, rotation) = calculateBoxGeometry(
            point: point,
            planWidth: planWidth,
            planHeight: planHeight,
            height: wallHeight,
            thickness: wallThickness,
            scaleFactor: scaleFactor
        )
        
        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = UIColor(red: 0.36, green: 0.36, blue: 0.36, alpha: 1.0)



 // Darker color for better contrast
        box.materials = [wallMaterial]
        
        let wallNode = SCNNode(geometry: box)
        wallNode.position = position
        wallNode.eulerAngles.y = rotation
        parentNode.addChildNode(wallNode)
    }
    
    private func addDoor(parentNode: SCNNode, point: Point, planWidth: CGFloat, planHeight: CGFloat, wallHeight: CGFloat, wallThickness: CGFloat, scaleFactor: CGFloat) {
        print("Adding door")
        let doorHeight = wallHeight * 0.85
        let (box, position, rotation) = calculateBoxGeometry(
            point: point,
            planWidth: planWidth,
            planHeight: planHeight,
            height: doorHeight,
            thickness: wallThickness * 0.6,
            scaleFactor: scaleFactor
        )
        
        let doorMaterial = SCNMaterial()
        doorMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0) // Darker wooden brown
        box.materials = [doorMaterial]
        
        let doorNode = SCNNode(geometry: box)
        doorNode.position = position
        doorNode.position.y = Float(doorHeight/2)
        doorNode.eulerAngles.y = rotation
        parentNode.addChildNode(doorNode)
        
        addDoorFrame(
            parentNode: parentNode,
            point: point,
            planWidth: planWidth,
            planHeight: planHeight,
            wallHeight: wallHeight,
            wallThickness: wallThickness,
            rotation: rotation,
            scaleFactor: scaleFactor
        )
    }
    
    private func addDoorFrame(parentNode: SCNNode, point: Point, planWidth: CGFloat, planHeight: CGFloat, wallHeight: CGFloat, wallThickness: CGFloat, rotation: Float, scaleFactor: CGFloat) {
        print("Adding door frame")
        let frameThickness = wallThickness * 0.15
        let frameMaterial = SCNMaterial()
        frameMaterial.diffuse.contents = UIColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0) // Even darker wood
        
        let centerX = CGFloat(point.x1 + (point.x2 - point.x1)/2) * scaleFactor - planWidth * scaleFactor/2
        let centerZ = CGFloat(point.y1 + (point.y2 - point.y1)/2) * scaleFactor - planHeight * scaleFactor/2
        
        // Vertical frames
        for offset in [-0.5, 0.5] {
            let frame = SCNBox(
                width: frameThickness,
                height: wallHeight * 0.9,
                length: frameThickness,
                chamferRadius: 0
            )
            frame.materials = [frameMaterial]
            let frameNode = SCNNode(geometry: frame)
            frameNode.position = SCNVector3(
                x: Float(centerX) + Float(offset * Double(wallThickness)),
                y: Float(wallHeight * 0.45),
                z: Float(centerZ)
            )
            frameNode.eulerAngles.y = rotation
            parentNode.addChildNode(frameNode)
        }
    }
    
    private func addWindow(parentNode: SCNNode, point: Point, planWidth: CGFloat, planHeight: CGFloat, wallHeight: CGFloat, wallThickness: CGFloat, scaleFactor: CGFloat) {
        print("Adding window")
        let windowHeight = wallHeight * 0.5
        let (box, position, rotation) = calculateBoxGeometry(
            point: point,
            planWidth: planWidth,
            planHeight: planHeight,
            height: windowHeight,
            thickness: wallThickness * 0.2,
            scaleFactor: scaleFactor
        )
        
        let glassMaterial = SCNMaterial()
        glassMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.8, blue: 0.9, alpha: 0.5) // Slightly darker blue
        glassMaterial.transparency = 0.5 // Less transparent
        glassMaterial.reflective.contents = UIColor(red: 0.75, green: 0.9, blue: 1.0, alpha: 0.2)

 // Add reflectivity
        box.materials = [glassMaterial]
        
        let windowNode = SCNNode(geometry: box)
        windowNode.position = position
        windowNode.position.y = Float(wallHeight * 0.6)
        windowNode.eulerAngles.y = rotation
        parentNode.addChildNode(windowNode)
        
        addWindowFrame(
            parentNode: parentNode,
            point: point,
            planWidth: planWidth,
            planHeight: planHeight,
            wallHeight: wallHeight,
            wallThickness: wallThickness,
            rotation: rotation,
            scaleFactor: scaleFactor
        )
    }
    
    private func addWindowFrame(parentNode: SCNNode, point: Point, planWidth: CGFloat, planHeight: CGFloat, wallHeight: CGFloat, wallThickness: CGFloat, rotation: Float, scaleFactor: CGFloat) {
        print("Adding window frame")
        let frameMaterial = SCNMaterial()
        frameMaterial.diffuse.contents = UIColor.lightGray // Changed from white to light gray
        
        let centerX = CGFloat(point.x1 + (point.x2 - point.x1)/2) * scaleFactor - planWidth * scaleFactor/2
        let centerZ = CGFloat(point.y1 + (point.y2 - point.y1)/2) * scaleFactor - planHeight * scaleFactor/2
        
        // Horizontal frames
        for yOffset in [0.3, 0.7] as [CGFloat] {
            let frame = SCNBox(
                width: CGFloat(max(point.x2 - point.x1, point.y2 - point.y1)) * scaleFactor,
                height: wallThickness * 0.2,
                length: wallThickness * 0.5,
                chamferRadius: 0
            )
            frame.materials = [frameMaterial]
            let frameNode = SCNNode(geometry: frame)
            frameNode.position = SCNVector3(
                x: Float(centerX),
                y: Float(wallHeight * yOffset),
                z: Float(centerZ)
            )
            frameNode.eulerAngles.y = rotation
            parentNode.addChildNode(frameNode)
        }
    }
    
    private func calculateBoxGeometry(point: Point, planWidth: CGFloat, planHeight: CGFloat, height: CGFloat, thickness: CGFloat, scaleFactor: CGFloat) -> (SCNBox, SCNVector3, Float) {
        let isHorizontal = abs(point.y2 - point.y1) < abs(point.x2 - point.x1)
        let width = CGFloat(isHorizontal ? abs(point.x2 - point.x1) : abs(point.y2 - point.y1)) * scaleFactor
        
        let box = SCNBox(width: width, height: height, length: thickness, chamferRadius: 0)
        
        let centerX = CGFloat(point.x1 + (point.x2 - point.x1)/2) * scaleFactor
        let centerZ = CGFloat(point.y1 + (point.y2 - point.y1)/2) * scaleFactor
        let adjustedX = centerX - planWidth * scaleFactor/2
        let adjustedZ = centerZ - planHeight * scaleFactor/2
        
        return (box, SCNVector3(adjustedX, height/2, adjustedZ), isHorizontal ? 0 : Float.pi/2)
    }
}

// MARK: - Data Helper Extensions

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - SwiftUI Hosting Extension for UIKit Integration
extension UIViewController {
    func presentFloorPlanView(with image: UIImage) {
        print("UIViewController presenting FloorPlanView with image size: \(image.size)")
        
        let floorPlanView = FloorPlanView(generatedImage: image)
            .navigationBarTitleDisplayMode(.inline)
        
        let hostingController = UIHostingController(rootView: floorPlanView)
        
        // Create custom back button
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: nil,
            action: nil
        )
        backButton.tintColor = UIColor(red: 199/255, green: 180/255, blue: 105/255, alpha: 1.0)
        
        // Create navigation controller
        let navController = UINavigationController(rootViewController: hostingController)
        navController.navigationBar.topItem?.leftBarButtonItem = backButton
        
        // Add swipe back gesture
        navController.interactivePopGestureRecognizer?.delegate = nil
        
        // Handle back action
        navController.navigationBar.topItem?.leftBarButtonItem?.action = #selector(handleBackAction)
        navController.navigationBar.topItem?.leftBarButtonItem?.target = self
        
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true) {
            print("FloorPlanView presentation completed")
        }
    }
    
    @objc private func handleBackAction() {
        self.dismiss(animated: true)
    }
}

// MARK: - Preview Provider

struct FloorPlanView_Previews: PreviewProvider {
    static var previews: some View {
        FloorPlanView()
    }
}
