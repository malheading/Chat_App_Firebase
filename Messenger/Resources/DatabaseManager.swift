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

// Mark - Sending messages / conversations
extension DatabaseManager {
    // 사용되는 Message라는 데이터타입은 User Defined Struct 이다. Definition 참고
    
    /* database schema : 데이터베이스에 저장될 형식
     
     "ss010510@gmail.com"=>[
        conversations=>[
            ["conversation_id": String,
            "other_user_email" : String,
            "last_message" =>[
                "date" : String of Date(),
                "message" : String or "message",
                "is_read" : Bool]
            ]
        ]
     ]
     
     conversation_id =>[
        "messages":[
            "id":String,    // message_id
            "type": text or photo or video ...,
            "contect" : String (text) or photo or video ...,
            "date" : Date(),
            "sender_email":String,
            "is_read":Bool
        ]
     ]
     
     
     */
    
    /// Create a new conversation with target user and email and first message sent
    public func createNewConversation(with otherUserEmail:String, name:String, firstMessage:Message, completion: @escaping (Bool)->Void){
        ///parameters: otherUserEmail: 상대방의 이메일, firstMessage: 대화방을 처음 만들 때 보낼 메시지
        // 현재 캐쉬된 Email을 먼저 확인한다.   --> 캐쉬된 Email은 safe-email이 아니다.
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Error(DatabaseManager.swift)!: Failed to get currentEmail during createNewConversation.")
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        
        //print("Debug: \(ref)")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? [String:Any] else { // check whethere userNode is exist
                completion(false)   // createNewConversation에 대한 block completion
                print("Error(DatabaseManager.swift)!: Failed to get userNode.")
                return
            }
            
            let dateString = ChatViewController.dateFormatter.string(from: firstMessage.sentDate)
            var message:String = ""
            switch firstMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let newConversationData:[String:Any] = [    // database에 userNode --> "conversations"에 넣을 것
                "id":firstMessage.messageId,
                "other_user_email":otherUserEmail,
                "name":name,
                "last_message":[
                    "date":dateString,  // database에 Date type은 못넣으니까 --> date formatter로 형변환(String) 필요.
//                    "type":"message", // 만약에 type도 기록하고 싶은 경우에
                    "message":message,
                    "is_read":false
                ]
            ]
            if var conversations = userNode["conversations"] as? [[String:Any]]{
                // userNode --> "conversations" node exists == 전에 메시지를 보내면서 데이터베이스에 생성이 되었었었다.
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self](error, databaseReference) in
                    guard error==nil else{
                        completion(false)
                        print("Error(DatabaseManager.swift)!: Failed to set userNode to database!")
                        return
                    }
                    // completion 블락을 바로 대입시킬 수 있다.
                    self?.finishCreatingConversation(with: name, messageID:firstMessage.messageId, firstMessage: firstMessage, completion: completion)
                    //completion(true)
                }
                
            } else{ // userNode --> "conversations"를 만들어줘야 한다.
                userNode["conversations"] = [newConversationData] // userNode는 database에서 snapshot을 찍어온 local value이므로, setValue로 database에 보내줘야한다.
                ref.setValue(userNode) {[weak self] (error, databaseReference) in
                    guard error==nil else{
                        completion(false)
                        print("Error(DatabaseManager.swift)!: Failed to set userNode to database!")
                        return
                    }
                    
                    // completion 블락을 바로 대입시킬 수 있다.
                    self?.finishCreatingConversation(with:name, messageID:firstMessage.messageId, firstMessage: firstMessage, completion: completion)
                    // completion(true)
                }
            }
        }
        
    }
    
    /// 이 함수는 createNewConversation의 내부에서 작동하고, database에 노드를 만들기 위해서 생성한다.
    private func finishCreatingConversation(with name:String, messageID:String, firstMessage:Message, completion:@escaping (Bool)->Void){
        // database에 conversation 노드를 만들어주는 함수.
        // TODO: conversations 노드를 추가할 것
//        conversation_id =>[
//                "messages":[
//                    "id":String,    // message_id
//                    "type": text or photo or video ...,
//                    "content" : String (text) or photo or video ...,
//                    "date" : Date(),
//                    "sender_email":String,
//                    "is_read":Bool
//                ]
//             ]
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Error(DatabaseManager.swift)!: Failed to get email from UserDefaults.")
            completion(false)
            return
        }
        
        var message:String = ""
        switch firstMessage.kind{
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let collectionMessage:[String:Any] = [
            "id":firstMessage.messageId,
            "type":firstMessage.kind.messageKindString,
            "content":message,
            "date":ChatViewController.dateFormatter.string(from: firstMessage.sentDate),
            "sender_email":currentUserEmail,
            "is_read":false,
            "name":name
        ]
//        print("*****convo is : \(collectionMessage)******")
        
        let value:[String:Any] = [
            "messages":[
                collectionMessage
            ]
            
        ]
        
        database.child("\(messageID)").setValue(value) { (error, databaseReference) in
            guard error==nil else{
                print("Error(DatabaseManager.swift)!: Failed in func finishCreatingConversation : \(error)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// email을 받았을 때, 그 사람과의 모든 대화를 return
    /// parameter email: database에서 검색하고자 하는 이메일
    /// parameter completion: 함수의 수행이 끝나고 수행하는 동작??
    public func getAllConversations(for email:String, completion: @escaping (Result<[Conversation],Error>)->Void){
        database.child("\(email)/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String:Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations:[Conversation] = value.compactMap { (dictionary) in
                guard let conversationsID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["last_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let message = latestMessage["message"] as? String else{
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationsID,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            }
            
        }
    }
    
    /// ID를 받았을 때, 그 사람과의 모든 대화를 return?
    public func getAllMessagesForConversations(with id:String, completion: @escaping (Result<String, Error>)->Void){
        
    }
    
    /// 목표 대화방에 메시지를 발신
    public func sendMessage(to conversation:String, message:Message, completion:@escaping (Bool)->Void){
        
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
