//
//  StorageManager.swift
//  Messenger
//
//  Created by 김정원 on 2021/05/09.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     이미지 저장 경로 규칙:
     /images/<e-mail>_profile_picture.png/
     */
    
    typealias UploadPictureCompletion = (Result<String,Error>) -> Void
    
    ///Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data:Data, fileName:String, completion: @escaping UploadPictureCompletion) {
        
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {metadata, error in
            guard error==nil else{//failed
                print("failed to upload data to firebase storage for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url=url else{
                    print("failed to Download URL")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                print("Download URL returned:\(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors:Error{//storage errors들을 정의
        case failedToUpload
        case failedToDownloadURL
    }
}
