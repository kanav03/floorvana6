
//  FirebaseManager.swift
//  FloorVana
//
//  Created by Navdeep    on 12/02/25.

import FirebaseFirestore
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func fetchImages(completion: @escaping ([String]) -> Void) {
        db.collection("HomePage").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching images: \(error)")
                completion([])
                return
            }

            let rawUrls = snapshot?.documents.compactMap { $0["imageUrl"] as? String } ?? []
            let dispatchGroup = DispatchGroup()
            var convertedUrls: [String] = []

            for rawUrl in rawUrls {
                if rawUrl.starts(with: "gs://") {
                    dispatchGroup.enter()
                    self.convertGStoHTTP(gsUrl: rawUrl) { httpUrl in
                        if let httpUrl = httpUrl {
                            convertedUrls.append(httpUrl)
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    convertedUrls.append(rawUrl)
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(convertedUrls)
            }
        }
    }

     func convertGStoHTTP(gsUrl: String, completion: @escaping (String?) -> Void) {
        let components = gsUrl.replacingOccurrences(of: "gs://", with: "").split(separator: "/")
        guard components.count > 1 else { completion(nil); return }

        let storageRef = storage.reference(forURL: "gs://\(components[0])").child(components.dropFirst().joined(separator: "/"))
        storageRef.downloadURL { url, error in
            completion(url?.absoluteString)
        }
    }
}
