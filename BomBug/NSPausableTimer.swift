//
//  NSPausableTimer.swift
//  BomBug
//
//  Created by Nico Hauser on 11.08.15.
//  Copyright © 2015 tyratox.ch. All rights reserved.
//

import UIKit

class NSPausableTimer {
    
    var pauseStart          = Date();
    var previousFireDate    = Date();
    
    var timer               = Timer();
    
    func pause(){
        self.pauseStart = Date();
        self.previousFireDate = timer.fireDate;
        
        timer.fireDate = Date.distantFuture;
    }
    
    func resume(){
        
        let pauseTime = pauseStart.timeIntervalSinceNow * -1;
        timer.fireDate = previousFireDate.addingTimeInterval(pauseTime);
        
    }
    
    func reset(_ timer:Timer){
        self.timer.invalidate();
        self.timer = timer;
    }
    
    init(timer:Timer){
        
        self.timer = timer;
        
    }

}
