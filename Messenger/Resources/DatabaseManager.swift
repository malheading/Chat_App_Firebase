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
    

    
//    public func test(){
//        //json같은 dictionary가 생성
//        database.child("foo").setValue(["something":true])
//    }
}

// MARK:- Account Management

extension DatabaseManager{
    
    public func userExists(with email:String, completion:@escaping ((Bool)->Void)){    //이미 아이디 데이터 베이스에존재한지 확인
        //true: 아이디가 중복임
        database.child(email).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
        } )
    }
    
    /// Inserts new user to databse
    public func insertUser(with user: ChatAppUser){ //ChatAppUser은 구조체
        //database에 넣는다
        database.child(user.emailAddress).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    //let profilePictureUrl: String //일단은 comment out
}
