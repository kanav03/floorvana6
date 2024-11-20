//
//  ImageModel.swift
//  imageCapture
//
//  Created by Navdeep    on 14/11/24.
//

import UIKit

struct ImageModel {
    var imageData: Data
    var date: Date

    static var allImages = [ImageModel]()

    static func saveImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 1.0) {
            let newImage = ImageModel(imageData: data, date: Date())
            allImages.append(newImage)
        }
    }

    static func getMostRecentImage() -> UIImage? {
        return allImages.last.flatMap { UIImage(data: $0.imageData) }
    }
}
