//
//  DatabaseManager.swift
//  Messenger
//
//  Created by 김정원 on 2021/04/18.
//

import Foundation
import FirebaseDatabase
import MessageKit
import AVFoundation

//final을 붙이면, subclass형성은 불가한 클래스 생성
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    private var requestedConversation:Conversation = Conversation(id: "", name: "", otherUserEmail: "", latestMessage: LatestMessage(date: "", text: "", isRead: false))
    
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

extension DatabaseManager {
    public func getDataFor(path:String, completion: @escaping (Result<Any,Error>)->Void){
        database.child(path).observe(.value) {  snapshot in
            guard let value = snapshot.value as? [String:Any] else {
                print("Error(DatabaseManager.swift)!: Failed to fetch \(DatabaseError.failedToFetch)\n")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

// MARK:- Account Management

extension DatabaseManager{
    
    public func userExists(with email:String, completion:@escaping ((Bool)->Void)){    //이미 아이디 데이터 베이스에존재한지 확인
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        //true: 아이디가 중복임
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? [String:Any] != nil else{
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
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "userFullName") as? String else {
            print("Error(DatabaseManager.swift)!: Failed to get currentEmail or current Nameduring createNewConversation.")
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        
        //print("Debug: \(ref)")
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
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
            
            let recipient_newConversationData:[String:Any] = [    // database에 userNode --> "conversations"에 넣을 것
                "id":firstMessage.messageId,
                "other_user_email":safeEmail,
                "name":currentName,
                "last_message":[
                    "date":dateString,  // database에 Date type은 못넣으니까 --> date formatter로 형변환(String) 필요.
//                    "type":"message", // 만약에 type도 기록하고 싶은 경우에
                    "message":message,
                    "is_read":false
                ]
            ]
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]]{
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else { // create new node
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
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
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)   // safeEmail로 변환
        
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
//            "sender_email":currentUserEmail,
            "sender_email":safeEmail,
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
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else{
                print("************************DEBUG AREA*************************")
                print("Returned with no conversations")
                print("************************DEBUG AREA*************************")
                
                let conversations:[Conversation] = []
                
//                completion(.failure(DatabaseError.failedToFetch))
                completion(.success(conversations))
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
                          print("**********************DEBUG TRAP*********************")
                          
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
            completion(.success(conversations))
            
        }
    }
    
    /// ID를 받았을 때, 그 사람과의 모든 대화를 return?
    public func getAllMessagesForConversations(with id:String, completion: @escaping (Result<[Message], Error>)->Void){
        // ID is MessageID not a user ID
        database.child("\(id)/messages").observe(.value) { [weak self]snapshot in
            guard let strongSelf = self else{
                return
            }
            
            guard let value = snapshot.value as? [[String:Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages:[Message] = value.compactMap { (dictionary) in // compactMap은 dictionary 반복하면서 return하는 형태로 array를 뽑아준다.
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    print("Error(DatabaseManager)!: Getting data from dictionary failed!\n")
                    return nil
                }
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                /// Future ToDo: 현재는 텍스트밖에 안되지만, 추후에 사진이나 동영상 등은 kind를 바꿔서 Message를 return해야 한다.
                var finalKind:MessageKind?
                if (type == "text") {  // type이 단순 텍스트이면?
                    finalKind = .text(content)
                } else if (type == "photo") {
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                              return nil
                          }
                    let screenBounds = UIScreen.main.bounds

                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: screenBounds.width/2, height: screenBounds.width/2))
                    finalKind = .photo(media)
                }else if (type == "video") {
                    guard let videoUrl = URL(string: content),
                          let placeholder = strongSelf.getThumbnailImage(forUrl: videoUrl) else {   //Thumbnail 이미지 생성
                              print("Error(DatabaseManager-getAllMessages...)!:Failed to get videoUrl and placeholder!")
                              return nil
                          }
                    // Thumbnail 이미지를 다운로드
                    let screenBounds = UIScreen.main.bounds

                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: screenBounds.width/2, height: screenBounds.width/2))
                    finalKind = .video(media)
                } else{
                    finalKind = .text(content)  // 아무런 kind도 아니면? --> 그냥 단순 text로 보낸다.
                }

                guard let finalKind = finalKind else {
                    return nil
                }
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind)
            }
            completion(.success(messages))
        }
    }
    
    private func getThumbnailImage(forUrl url:URL) -> UIImage?{
        let asset: AVAsset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)

            do {
                let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
                return UIImage(cgImage: thumbnailImage)
            } catch let error {
                print(error)
            }
            return nil
    }
    
    /// 목표 대화방에 메시지를 발신
    public func sendMessage(to conversation:String, otherUserEmail:String, name:String, newMessage:Message, completion:@escaping (Bool)->Void){
        ///parameter conversation: ConversationID
        ///parameter otherUserEmail: Other user's safe email type of String
        ///parameter name: Other user's name
        ///parameter newMessage: A Message that current user want to send.
        
        //--> Add new message to message
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self]snapshot in
            guard let strongSelf = self else{
                return
            }
            guard var currentMessages=snapshot.value as? [[String:Any]] else{
                print("Error(DatabaseManager)!: Failed to observe the conversation ID")
                completion(false)
                return
            }
            
            guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                print("Error(DatabaseManager-sendMessage)!: Failed to get email from UserDefaults.")
                completion(false)
                return
            }
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)   // safeEmail로 변환
            
            var message:String = ""
            switch newMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetURLString = mediaItem.url?.absoluteString{
                    message = targetURLString
                }
                break
            case .video(let mediaItem):
                if let targetURLString = mediaItem.url?.absoluteString{
                    message = targetURLString
                }
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
            
            let dateString:String = ChatViewController.dateFormatter.string(from: newMessage.sentDate)
            let newMessageEntry:[String:Any] = [
                "id":newMessage.messageId,
                "type":newMessage.kind.messageKindString,
                "content":message,
                "date":dateString,
    //            "sender_email":currentUserEmail,
                "sender_email":safeEmail,
                "is_read":false,
                "name":name
            ]
            
            currentMessages.append(newMessageEntry) // snapshot값에 추가
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, reference in
                guard error==nil else {
                    print("Error(DatabaseManager-sendMessage)!: Failed to setValue to database with \(String(describing: error))\n")
                    completion(false)
                    return
                }
                // -->update sender latest message
                strongSelf.database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    
//                     2021.07.17 주석처리 --> 상대방에게 메시지가 있는 경우에는 여기서 return 되어버린다.
//                    guard var snapshotSender=snapshot.value as? [[String:Any]] else{
//                        // 2021.07.17 만약에 현재 나에게 "conversations"라는 child가 없다면..?
//                        completion(false)
//                        print("Error(DatabaseManager->sendMessage)!: snapshot is not a type of [[String:Any]]\n")
//                        return
//                    }
//
                    let updatedValue:[String:Any] = [
                        "date": dateString,
                        "is_read":false,
                        "message":message
                    ]
                    if var snapshotSender = snapshot.value as? [[String:Any]]{
                        // 2021.07.25 수정 : 만약에 (safeEmail)/conversations가 있으면 수행한다. 없으면 else문 참고
                        
                        var targetConversation:[String:Any]?
                        var position = 0
                        
                        // snapshot에서 타겟 ConversationID를 검색
                        for currentConversation in snapshotSender{
                            if let currentID = currentConversation["id"] as? String, currentID == conversation{
                                targetConversation = currentConversation
                                break;
                            }
                            position += 1
                        }
                        targetConversation?["last_message"] = updatedValue
                        guard let targetConversation = targetConversation else {
                            print("Error(DatabaseManager-sendMessage)!: targetConversation is nil\n")
                            completion(false)
                            return
                        }
                        
                        snapshotSender[position] = targetConversation
                        strongSelf.database.child("\(safeEmail)/conversations").setValue(snapshotSender) { error, _ in
                            guard error==nil else{
                                print("Error(DatabaseManager-sendMessage)!: Failed to setValue of snapshotSender to the current User\n")
                                completion(false)
                                return
                            }
                            //                        completion(true)
                            // -->update recipient latest message
                            strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                                guard var snapshotReceiver=snapshot.value as? [[String:Any]] else{
                                    completion(false)
                                    print("Error(DatabaseManager->sendMessage->Receiver)!: snapshot is not a type of [[String:Any]]\n")
                                    return
                                }
                                let updatedValue:[String:Any] = [
                                    "date": dateString,
                                    "is_read":false,
                                    "message":message
                                ]
                                var targetConversation:[String:Any]?
                                var position = 0
                                
                                for currentConversation in snapshotReceiver{
                                    if let currentID = currentConversation["id"] as? String, currentID == conversation{
                                        targetConversation = currentConversation
                                        break;
                                    }
                                    position += 1
                                }
                                targetConversation?["last_message"] = updatedValue
                                guard let targetConversation = targetConversation else {
                                    print("Error(DatabaseManager->sendMessage->Receiver)!: targetConversation is nil\n")
                                    completion(false)
                                    return
                                }
                                
                                snapshotReceiver[position] = targetConversation
                                strongSelf.database.child("\(otherUserEmail)/conversations").setValue(snapshotReceiver) { error, _ in
                                    guard error==nil else{
                                        print("Error(DatabaseManager->sendMessage->Receiver)!: Failed to setValue of snapshotSender to the other User\n")
                                        completion(false)
                                        return
                                    }
                                    completion(true)
                                }
                                
                            })
                        }
                    }else {
                        // 2021.07.25 만약에 (safeEmail)/conversations가 없으면, 단순 메시지를 database에 append 해준다.
                        // 2021.07.31 작동 확인 완료
                        var snapshotSender:[[String:Any]] = [["id":conversation]]
                        snapshotSender[0]["name"] = name
                        let otherUserSafeEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail)
                        snapshotSender[0]["other_user_email"] = otherUserSafeEmail
                        snapshotSender[0]["last_message"] = updatedValue
                        
                        strongSelf.database.child("\(safeEmail)/conversations").setValue(snapshotSender){ error, _ in
                            guard error==nil else{
                                print("Error(DatabaseManager-sendMessage)!: Failed to setValue of snapshotSender to the current User\n")
                                completion(false)
                                return
                            }
                            //                        completion(true)
                            // -->update recipient latest message
                            strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                                guard var snapshotReceiver=snapshot.value as? [[String:Any]] else{
                                    completion(false)
                                    print("Error(DatabaseManager->sendMessage->Receiver)!: snapshot is not a type of [[String:Any]]\n")
                                    return
                                }
                                let updatedValue:[String:Any] = [
                                    "date": dateString,
                                    "is_read":false,
                                    "message":message
                                ]
                                var targetConversation:[String:Any]?
                                var position = 0
                                
                                for currentConversation in snapshotReceiver{
                                    if let currentID = currentConversation["id"] as? String, currentID == conversation{
                                        targetConversation = currentConversation
                                        break;
                                    }
                                    position += 1
                                }
                                targetConversation?["last_message"] = updatedValue
                                guard let targetConversation = targetConversation else {
                                    print("Error(DatabaseManager->sendMessage->Receiver)!: targetConversation is nil\n")
                                    completion(false)
                                    return
                                }
                                
                                snapshotReceiver[position] = targetConversation
                                strongSelf.database.child("\(otherUserEmail)/conversations").setValue(snapshotReceiver) { error, _ in
                                    guard error==nil else{
                                        print("Error(DatabaseManager->sendMessage->Receiver)!: Failed to setValue of snapshotSender to the other User\n")
                                        completion(false)
                                        return
                                    }
                                    completion(true)
                                }
                                
                            })
                        }
                        
                    }
                    
                    
                    
                }
                
            }
            
        }
        
    }
    
    public func deleteConversation(conversationId: String, completion:@escaping (Bool)->Void){
        // Get current user's safe email
        // Get database reference from database manager
        // observe single value from database with current user email
        // iterate to find the conversation using conversationId
        // delete the target conversation and update conversations:[[String:Any]] to the database
        guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: userEmail)
        
        let reference = database.child("\(safeEmail)/conversations")
        
        reference.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String:Any]]{   // conversations를 var로 정의할 것
                var positionToRemove = 0
                for conversation in conversations {
                    if let currentId = conversation["id"] as? String,
                       currentId == conversationId{
                        print("Found current Conversation position :")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)  // Target conversation 제거
                reference.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error==nil else{
                        print("Failed to upload deleted conversations to database \n")
                        completion(false)
                        return
                    }
                    completion(true)
                })
            }
        }
    }
    public func OtherUserHasConversation(otherUserEmail:String, completion:@escaping (Result<String,Error>)->Void){
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let currentUserSafeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let otherUserSafeEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail)
        
        database.child("\(otherUserSafeEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value as? [[String:Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let targetConversation = value.first(where: {
                guard let targetSender = $0["other_user_email"] as? String else{
                    completion(.failure(DatabaseError.failedToFetch))
                    return false
                }
                return targetSender == currentUserSafeEmail
            })
            guard let id = targetConversation?["id"] as? String else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(id))
            return
        })
    }
    
    public func requestConversation(conversationId:String, otherUserName:String, otherUserEmail:String)->Conversation?{

        database.child("\(conversationId)/messages").observeSingleEvent(of: .value, with: {[weak self]snapshot in
            guard let strongSelf=self else{
                return
            }
            
            guard let shot = snapshot.value as? [[String:Any]] else{
                print("Error(DatabaseManager-requestConversation): snapshot is not type of [[String:Any]]")
                return
            }
            
            let lastMessage = shot.last!
            var isRead:Bool
            if lastMessage["is_read"] as? String == "false" {
                isRead = false
            } else {
                isRead = true
            }
            guard let dateString = lastMessage["date"] as? String,
                  let textString = lastMessage["content"] as? String else {
                      return
                  }
            let latestMessage = LatestMessage(date: dateString, text: textString, isRead: isRead)
            let requestedConversation = Conversation(id: conversationId, name: otherUserName, otherUserEmail: otherUserEmail, latestMessage: latestMessage)
            
            strongSelf.requestedConversation = requestedConversation
            
        })
        // 여기를 어떻게 해야할지 고민중...
        return requestedConversation
    }
    
    /// 현재 로그인한 유저의 데이터베이스에 conversation을 추가한다.
    public func appendConversation(with email:String, conversation:Conversation){
        
    }
    
    public func isConversationEmpty(currentUserEmail:String, completion:@escaping (Bool)->Void){
        let currentUserSafeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
//        let snapshot = database.child("\(currentUserSafeEmail)").value
//        var isEmpty:Bool = false

        database.child("\(currentUserSafeEmail)/").observeSingleEvent(of: .value, with: {snapshot in
            guard let values = snapshot.value as? [String:Any] else {
                completion(true)   // 비어있는거는 아니지만, 아에 브랜치가 없기 때문에 return false
                return
            }
//            for value in values{
//                if value.keys.first == "conversations"{
//                    completion(false)   //  비어있지 않기 때문에 false
//                    return
//                }
//            }
            for key in values.keys{
                if key == "conversations"{
                    completion(false)   //  비어있지 않기 때문에 false
                }
            }
            completion(true)    //루프 다 돌았는데도 "conversations" 못찾으면
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
