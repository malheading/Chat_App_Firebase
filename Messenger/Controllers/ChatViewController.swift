//
//  ChatViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/05/07.
// 채팅방에 들어 갔을 때의 Controller

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

struct Message:MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Media:MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage   // This is not optional ==> 무조건 입력해줘야 하는 변수
    var size: CGSize    // This is not optional ==> 무조건 입력해줘야 하는 변수
}

// MessageKind 아래에 String을 하나 만들어준다.
extension MessageKind {
    var messageKindString:String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}


struct Sender:SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {//Dependencies중에 하나인 MessageKit의 MessagesViewController를 사용한다.

    //DateFormatter : Expensive object이기 때문에 static으로 만들어서 계속 사용한다?? 아니면 클래스 내부에 public object로 만든다??
    public static var dateFormatter:DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
        return formatter
    }
    
    public var otherUserEmail:String
    public var isNewConversation = false
    private var conversationId:String?
    
    init(with email:String, id:String?) {   // id는 nil일 수도 있다.
        let otherUserSafeEmail = DatabaseManager.safeEmail(emailAddress: email)
        otherUserEmail = otherUserSafeEmail
        conversationId = id
        super.init(nibName: nil, bundle: nil)   // MessagesViewController를 return하는 init
        
        if let conversationId = conversationId {    // 만약에 conversationId가 nil이 아니면
            listenForMessage(id:conversationId)  // database에 있는 이 사람과의 대화 불러오자
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var messages = [Message]()  // 현재 채팅방 사람의 메시지 Array
    
    private var selfSender:Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String,
              let photoURL = UserDefaults.standard.value(forKey: "profile_picture_url") as? String,
              let name = UserDefaults.standard.value(forKey: "userFullName") as? String else{
            print("Error(ChatViewController.swift)!: email or photoURL or userFullName in UserDefaults is nil.")
            print("\(UserDefaults.standard.value(forKey: "email"))")
            print("\(UserDefaults.standard.value(forKey: "profile_picture_url"))")
            print("\(UserDefaults.standard.value(forKey: "userFullName"))")
            return Sender(photoURL: "", senderId: "DUMMY_SENDER", displayName: "DUMMY_SENDER")
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let selfSender = Sender(photoURL: "",   // selfSender와 Message의 Sender 일치해야하는 문제
                                senderId: safeEmail,
//                                displayName: "Me")
                                displayName: name)
        return selfSender
    }
    
// // 초창기에 사용하던 코드
//    private let selfSender = Sender(photoURL: UserDefaults.standard.value(forKey: "profile_picture_url") as? String ?? "",
//                                    senderId: "1",
//                                    displayName: UserDefaults.standard.value(forKey: "name") as? String ?? "Me")    //추후에 Firebase에서 가져올 예정
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        messages.append(Message(sender: selfSender,
//                                messageId: "1",
//                                sentDate: Date(),
//                                kind: .text("Hello World Message")))
//        messages.append(Message(sender: selfSender,
//                                messageId: "1",
//                                sentDate: Date(),
//                                kind: .text("Hello World Message.Hello World Message.Hello World Message.Hello World Message.")))
        
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        self.setupInputButton()
        
        messagesCollectionView.scrollToLastItem()
    }
    
    private func setupInputButton(){
        let button = InputBarButtonItem()   // messageInputBar에 넣는 버튼 이름은 InputBarButtonItem
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self]inputBarButton in
            self?.presentInputActionSheet()
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)  // 36은 left stack view 한개의 width
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "Choose the type of media",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self]action in
//            사진을 찍거나 첨부하여 보내도록
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self]action in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self]action in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Take a new photo?\nSelect a photo?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self]action in
//            새로운 사진을 찍고 첨부를 하고자 할 때
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { [weak self]action in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil)) // cancle할 때는 아무런 동작을 안하게
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Take a new video?\nSelect a video?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self]action in
//            새로운 사진을 찍고 첨부를 하고자 할 때
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { [weak self]action in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil)) // cancle할 때는 아무런 동작을 안하게
        
        present(actionSheet, animated: true)
    }
    
    private func listenForMessage(id:String){    // database에서 메시지들을 가져오고 갱신한다.
        DatabaseManager.shared.getAllMessagesForConversations(with: id) { [weak self]result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    print("Error(ChatViewController)!: messages is empty. check : \(messages)\n")
                    return
                }
//                print("messages[0].sender is : \(messages[0].sender)")
//                print("selfSender is : \(self?.selfSender)")
                self?.messages = messages   // messages array는 [Message]
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()  // messages 데이터 리로드
                }
                
            case .failure(let error):
                print("Error(ChatViewController.swift)!: Failed to getAllMessagesForConversations - \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 이미지든 동영상이든 컨트롤러에서 선태이 끝났을 때?
        picker.dismiss(animated: true, completion: nil)
        
        guard let messageID = createMessageID(),
              let conversationId = self.conversationId,
              let name = self.title,
              let messageIdOfChat = self.conversationId,
              let selfSender = self.selfSender else {
                  print ("Error(ChatViewController-imagePickerController)!: Failed to create messageID \n")
                  return
              }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let imageData = image.pngData() {
            // Image message를 보낼때?
            let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".png"
            //Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: {[weak self] result in
                guard let strongSelf = self,
                      
                      let placeholder = UIImage(systemName: "plus") else {
                          print("Error(ChatViewController-uploadMessagePhoto)!: Failed to unwrap some variables \n")
                          return
                      }
                
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    let media = Media(url: URL(string: urlString),
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message:Message = Message(sender: selfSender,
                                                  messageId: messageIdOfChat,
                                                  sentDate: Date(),
                                                  kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {success in
                        if success{
                            print("Succeeded photo message sending.\n ")
                        } else {
                            print("Failed photo message sending.\n ")
                        }
                    })
                case .failure(let error):
                    print("Error(ChatViewController-uploadMessagePhoto)!: Failed to upload message photo : \(error)")
                }
            })
            //Send message
        } else {    // Video를 고르는 경우에는??
            guard let videoUrl = info[.mediaURL] as? URL else{ // video local url?
                return
            }
            let fileName = "video_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".mov"
            //TODO: Upload Video url to the storageManager <--- currently creating function "uploadMessageVideo"
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: {[weak self] result in
                guard let strongSelf = self,
                      
                      let placeholder = UIImage(systemName: "plus") else {
                          print("Error(ChatViewController-uploadMessageVideo)!: Failed to unwrap some variables \n")
                          return
                      }
                
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    let media = Media(url: URL(string: urlString),
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message:Message = Message(sender: selfSender,
                                                  messageId: messageIdOfChat,
                                                  sentDate: Date(),
                                                  kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {success in
                        if success{
                            print("Succeeded video message sending.\n ")
                        } else {
                            print("Failed video message sending.\n ")
                        }
                    })
                case .failure(let error):
                    print("Error(ChatViewController-uploadMessageVideo)!: Failed to upload message video : \(error)")
                }
            })
            
        }   // End of if~else
    }
}

extension ChatViewController:InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // 채팅방에서 Send Button을 눌렀을 때
        // 비어있는 채팅은 보내지지 않도록
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageID = createMessageID() else{
            return // 비어있는 채팅이다.
        }
        
        let mmesage:Message = Message(sender: selfSender,
                                      messageId: messageID,
                                      sentDate: Date(),
                                      kind: .text(text))
        
        if isNewConversation{   // 만약 대화가 처음이라면?
            // Database에 새로운 대화를 생성
            //20210523 : Message 만들어야 함.
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,
                                                         name:self.title! /*현재 title이 대화 상대의 이름이다.*/ ,
                                                         firstMessage: mmesage,
                                                         completion: {[weak self]success in
                // 내가 직접 만든 createNewConversation 에서 completion(true)를 하면 --> success = true
                if success{
                    print("message success")
                    self?.isNewConversation = false
                } else{
                    print("message failed")
                }
            })
            
        }else{  // 만약 대화가 처음이 아니라면?
            // 기존 Database에 추가(append)
            guard let conversationId = self.conversationId else {
                return
            }
            guard let title=self.title else{
                print("Error(ChatViewController-inputBar)!: Failed to get title as String")
                return
            }
            print("selfSender is : \(self.selfSender?.displayName)")
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail:otherUserEmail, name:title, newMessage: mmesage) { success in
                if success{
                    print("Sending message success : ChatViewController -> sendMessage")
                }else{
                    print("Failed to send message : ChatViewController -> sendMessage")
                }
            }
        }
        
    }
    
    private func createMessageID() -> String? {
        /// Create messageID using senderEmail + datetime + otherEmail + randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            print("Error(ChatViewController.swift)!: Failed to get currentUserEmail from UserDefaults.")
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("newIdentifier is: \(newIdentifier)")
        return newIdentifier
    }
    
}

extension ChatViewController:MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{   // Message가 어떻게 보일지 결정하는 Delegates
    func currentSender() -> SenderType {
        guard let sender = selfSender else{
            fatalError("FatalError(ChatViewController.wift):! selfSender is nil.")
            return Sender(photoURL: "", senderId: "DUMMY", displayName: "DUMMY")
        }
        return sender
//        return Sender(photoURL: "", senderId: "DUMMY_SENDER_2", displayName: "DUMMY_SENDER_2")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]  //MessageKit에서는 section을 단위로 사용하기 때문에
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let myErrorPlacer = "configureMediaMessageImageView"
        guard let message = message as? Message else {
            print("Error(ChatViewController-\(myErrorPlacer)!: Failed to get message as? Message \n")
            return
        }
        
        switch message.kind{
        case .photo(let media):
            guard let media = media as? Media,
                  let imageUrl = media.url else {
                      print("Error(ChatViewController-\(myErrorPlacer)!: Failed to get media as? Media \n")
                      return
                  }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }   // end of configureMediaMessageImageView
}   //end of extension

extension ChatViewController:MessageCellDelegate{
    func didTapImage(in cell: MessageCollectionViewCell) {
        /// You can get a reference to the `MessageType` for the cell by using `UICollectionView`'s
        /// `indexPath(for: cell)` method. Then using the returned `IndexPath` with the `MessagesDataSource`
        /// method `messageForItem(at:indexPath:messagesCollectionView)`.
        let myErrorPlacer = "didTapImage"
        guard let indexPath = messagesCollectionView.indexPath(for: cell) as? IndexPath,
        let message = self.messageForItem(at: indexPath, in: messagesCollectionView) as? Message else {
            return
        }
        switch message.kind{
        case .photo(let media):
            guard let media = media as? Media,
                  let imageUrl = media.url else {
                      print("Error(ChatViewController-\(myErrorPlacer)!: Failed to get media as? Media \n")
                      return
                  }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let media = media as? Media,
                  let videoUrl = media.url else{
                print("Error(ChatViewController-\(myErrorPlacer)!: Failed to get media as? Media(Video) \n")
                return
            }
            let vc = AVPlayerViewController()
            let player = AVPlayer(url: videoUrl)
            vc.player = player
            self.present(vc,animated: true)
            player.play()
        default:
            break
        }
        
    }
}
