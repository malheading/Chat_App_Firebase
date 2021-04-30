//
//  Extensions.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/13.
//

import Foundation
import UIKit

extension UIView{
    //여기 있는 변수(var)들은 view.*로 불러올 수 있다.
    //view.width or view.height
    public var width:CGFloat{   //is this closure??
        return self.frame.size.width
    }
    
    public var height:CGFloat{
        return self.frame.size.height
    }
    
    public var top:CGFloat{
        return self.frame.origin.y
    }
    
    public var bottom:CGFloat{
        return self.frame.size.height + self.frame.origin.y
    }
    
    public var left:CGFloat{
        return self.frame.origin.x
    }
    
    public var right:CGFloat{
        return self.frame.size.width + self.frame.origin.x
    }
}

extension Notification.Name{
    static let didLogInNotification = Notification.Name("didLogInNotification")
}
