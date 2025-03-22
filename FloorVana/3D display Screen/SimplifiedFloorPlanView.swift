




import SwiftUI
import SceneKit
import UIKit

struct SimplifiedFloorPlanView: View {
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var floorPlanData: FloorPlanData? = nil

    // Image is now passed in via init rather than selected via UI
    @State private var selectedImage: UIImage?

    init(selectedImage: UIImage?) {
        _selectedImage = State(initialValue: selectedImage)
    }

    var body: some View {
        ZStack {
            if let data = floorPlanData {
                FloorPlan3DView(floorPlanData: data, onExportModel: {_ in }) // Fixed missing argument
            } else {
                VStack(spacing: 20) {
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
                }
                .padding()
                .onAppear {
                    // Automatically process the image when the view appears
                    if let image = selectedImage {
                        processFloorPlanImage(image)
                    } else {
                        errorMessage = "No image provided"
                    }
                }
            }
        }
        .navigationBarTitle("3D Floor Plan", displayMode: .inline)
    }

    // Add this new function to resize images
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat = 1000) -> UIImage {
        let originalSize = image.size

        // Check if resizing is needed
        if originalSize.width <= maxDimension && originalSize.height <= maxDimension {
            return image
        }

        // Calculate new size while maintaining aspect ratio
        var newSize: CGSize
        if originalSize.width > originalSize.height {
            let ratio = maxDimension / originalSize.width
            newSize = CGSize(width: maxDimension, height: originalSize.height * ratio)
        } else {
            let ratio = maxDimension / originalSize.height
            newSize = CGSize(width: originalSize.width * ratio, height: maxDimension)
        }

        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return resizedImage
    }

    private func processFloorPlanImage(_ image: UIImage) {
        isLoading = true
        errorMessage = nil

        // Resize image if needed
        let processedImage = resizeImageIfNeeded(image)

        // Check image type and convert to appropriate format
        let imageData: Data?
        let mimeType: String
        let filename: String

        // Set a maximum file size (4MB is a common limit for many APIs)
        let maxFileSize = 4 * 1024 * 1024

        // Try PNG first, but with size check
        if let pngData = processedImage.pngData(), pngData.count < maxFileSize {
            imageData = pngData
            mimeType = "image/png"
            filename = "floorplan.png"
        } else {
            // Force JPEG with compression if PNG is too large
            var compressionQuality: CGFloat = 0.8
            var jpegData = processedImage.jpegData(compressionQuality: compressionQuality)

            // Try progressively lower quality if still too large
            while let data = jpegData, data.count > maxFileSize && compressionQuality > 0.1 {
                compressionQuality -= 0.1
                jpegData = processedImage.jpegData(compressionQuality: compressionQuality)
            }

            if let data = jpegData, data.count <= maxFileSize {
                imageData = data
                mimeType = "image/jpeg"
                filename = "floorplan.jpg"
            } else {
                isLoading = false
                errorMessage = "Image is too large to process even after compression. Please use a smaller image."
                return
            }
        }

        guard let data = imageData else {
            isLoading = false
            errorMessage = "Failed to process image"
            return
        }

        // Log file size for debugging
        print("Image size being sent: \(Double(data.count) / 1024.0 / 1024.0) MB")

        // Create URL request
        let url = URL(string: "https://floorplan-api-344505445307.us-central1.run.app")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Prepare body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Set timeout to be longer for large uploads
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120.0  // 2 minutes
        configuration.timeoutIntervalForResource = 300.0 // 5 minutes
        let session = URLSession(configuration: configuration)

        // Send request
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .timedOut:
                            self.errorMessage = "Request timed out. The server may be busy or the image too large."
                        case .notConnectedToInternet:
                            self.errorMessage = "No internet connection available."
                        default:
                            self.errorMessage = "Network error: \(error.localizedDescription)"
                        }
                    } else {
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }

                // Check for specific status codes
                if httpResponse.statusCode == 413 {
                    self.errorMessage = "Image exceeds maximum size allowed by server. Please use a smaller image."
                    return
                } else if !(200...299).contains(httpResponse.statusCode) {
                    self.errorMessage = "Server error: Status code \(httpResponse.statusCode)"

                    // Try to get more details from the response if available
                    if let data = data, let errorText = String(data: data, encoding: .utf8) {
                        print("Server error details: \(errorText)")
                        if !errorText.isEmpty {
                            self.errorMessage = "Server error: \(errorText)"
                        }
                    }
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received from server"
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let decodedData = try decoder.decode(FloorPlanData.self, from: data)
                    self.floorPlanData = decodedData
                } catch {
                    print("Decoding error: \(error)")

                    // Print response data for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response data: \(responseString)")
                    }

                    self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }

        // Start the task
        task.resume()
    }
}


