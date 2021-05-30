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
    
    ///Returns profile picture url
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        print("Passed URL path is : \(path)")
        let reference = storage.child(path) //추신: storage는 클래스 내에서 정의한 reference이다.
        reference.downloadURL(completion: {url, error in
            print("Downloading url is : \(url)")
            guard let url=url, error==nil else{
                // url을 다운로드 실패했을 때, downloadURL 함수의 escaping으로 .failure(Error) 던진다
                completion(.failure(StorageErrors.failedToDownloadURL))
                return
            }
            // url을 다운로드 성공하면, downloadURL 함수의 escaping으로 .success(URL) 던진다
            completion(.success(url))
        })
    }
}
