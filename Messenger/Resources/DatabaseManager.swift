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
            /* 데이터 베이스에 다음과 같이 넣으려고 한다.
             -users
             [-"name": "jeongwon kim"
             -"safe_email":"ss010510-gmail-com"]
             
             [-"name": "jeongwon kim"
             -"safe_email":"jsi00046-nate-com"]
             */
            self.database.child("users").observeSingleEvent(of: .value, andPreviousSiblingKeyWith: {snapshot, string in
                if var userCollection = snapshot.value as? [[String:String]]{
                    // append to user dictionary
                    let newElement:[String:String] = [
                        "name":user.firstName + " " + user.lastName,
                        "email":user.safeEmail
                    ]

                    userCollection.append(newElement)
                    self.database.child("users").setValue(userCollection, withCompletionBlock: {error,_ in
                        guard error==nil else{
                            print("Error!: E001-Failed to insert user to database.")
                            completion(false)
                            return
                        }
                        completion(true) //completion에다가 true를 넣고 반환해줘라
                    })
                }
                else{
                    // create this array
                    let newCollection:[[String:String]] = [
                        [
                            "name":user.firstName + " " + user.lastName,
                            "email":user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: {error, _ in
                        guard error==nil else{
                            print("Error!: database의 'users' 아래에 유저 생성 실패!'")
                            completion(false)
                            return
                        }
                        completion(true) //completion에다가 true를 넣고 반환해줘라
                    })
                }
            })
        })
    }
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
}

public enum DatabaseError:Error{
    case failedToFetch
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
