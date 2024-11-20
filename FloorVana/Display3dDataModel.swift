//
//  ImageDataModel.swift
//  FloorVana
//
//  Created by Navdeep    on 13/11/24.
//

// ImageDataModel.swift

import UIKit

struct Display3dDataModel {
    let image3DName: String
    let image2D: UIImage?

    static func fetchImageData(capturedImage: UIImage?) -> Display3dDataModel {
        return Display3dDataModel(
            image3DName: "a",
            image2D: capturedImage
        )
    }
}
