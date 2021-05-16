//
//  DatabaseManager.swift
//  Messenger
//
//  Created by 김정원 on 2021/04/18.
//

import Foundation
import FirebaseDatabase

//final을 붙이면, subclass형성은 불가한 클래스 생성
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress:String)->String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
//    public func test(){
//        //json같은 dictionary가 생성
//        database.child("foo").setValue(["something":true])
//    }
}

// MARK:- Account Management

extension DatabaseManager{
    
    public func userExists(with email:String, completion:@escaping ((Bool)->Void)){    //이미 아이디 데이터 베이스에존재한지 확인
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        //true: 아이디가 중복임
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
        } )
    }
    
    /// Inserts new user to databse
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){ //ChatAppUser은 구조체
        //함수에 completion을 넣는 방법 -->참고할 것
        //database에 넣는다 <-- database.child().setvalue()
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ],withCompletionBlock: {error, reference in
            guard error == nil else{
                print("failed to write user information to database")
                completion(false)   //insertUser함수의 completion
                return
            }
            completion(true)    //completion에다가 true를 넣고 반환해줘라
        })
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail:String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName:String{
        //ss010510-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
