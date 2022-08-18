//
//  NSPair.swift
//  BomBug
//
//  Created by Nico Hauser on 11.08.15.
//  Copyright © 2015 tyratox.ch. All rights reserved.
//

import UIKit

class NSPair: NSObject {
    
    var first:AnyObject = 0 as AnyObject;
    var second:AnyObject = 0 as AnyObject;
    
    init(first:AnyObject, second:AnyObject){
        self.first = first;
        self.second = second;
    }

}
