//
//  GameScene.swift
//  BomBug
//
//  Created by Nico Hauser on 06.08.15.
//  Copyright (c) 2015 tyratox.ch. All rights reserved.
//

import SpriteKit
import Darwin
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let PlayerName              = "player";
    let PlayerBitMask           : UInt32 = 0x1 << 0; // 00000000000000000000000000000001
    
    let EnemyName               = "enemy";
    let EnemyBitMask            : UInt32 = 0x1 << 1; // 00000000000000000000000000000010
    let EnemyNodeName           = "enemyNode";
    
    let CoinName                = "coin";
    let CoinBitMask             : UInt32 = 0x1 << 2; // 00000000000000000000000000000100
    let CoinNodeName            = "coinNode";
    
    let ExplosionName           = "explosion";
    let StrikeName              = "strikeCounter";
    
    let MOVEMENT_NONE           = CGFloat(-1);
    let MOVEMENT_TOP            = CGFloat( 0);
    let MOVEMENT_LEFT           = CGFloat( 1);
    let MOVEMENT_BOTTOM         = CGFloat( 2);
    let MOVEMENT_RIGHT          = CGFloat( 3);
    
    var touching                = false;
    
    var PAUSED                  = false;
    var pauseOverlay            = SKSpriteNode();
    var pauseLabel              = SKLabelNode(fontNamed:"Gill Sans");
    
    var playerSpeed             = CGFloat(10); //pixels moved per frame
    var playerMoveDirection     = CGFloat(-1);
    var playerSafeZone          = CGFloat(105);
    
    var coinStrike              = 1;
    var strikeTimer             = Timer();
    
    let scoreboard              = SKLabelNode(fontNamed:"Gill Sans");
    var score                   = 0;
    var player                  = SKSpriteNode();
    var coin                    = SKSpriteNode();
    var enemy                   = SKSpriteNode();
    
    var nodeCounter             = 0;
    let nodeLimit               = 15;
    var spawnTimer              = NSPausableTimer(timer: Timer());
    var spawnInterval           = 2.5;
    
    let coinSound               = SKAction.playSoundFileNamed("coin.caf", waitForCompletion: false);
    let explosionSound          = SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false);
    
    var despawnTimers           = Array<NSPausableTimer>();
    
    override func didMove(to view: SKView) {
        
        /* World*/
        
        physicsWorld.contactDelegate = self;
        
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame);
        borderBody.friction = 0;
        self.physicsBody = borderBody;
        
        /* Pause */
        pauseOverlay.position.x = (self.size.width/2);
        pauseOverlay.position.y = (self.size.height/2);
        pauseOverlay.zPosition = 100;
        pauseOverlay.size.width = self.size.width;
        pauseOverlay.size.height = self.size.height;
        pauseOverlay.color = SKColor(red: 0, green: 0, blue: 0, alpha: 0.8);
        
        pauseLabel.text = "Pause";
        pauseLabel.fontSize = 72;
        pauseLabel.zPosition = 101;
        pauseLabel.fontColor = SKColor(red: 1, green: 1, blue: 1, alpha: 1);
        pauseLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY);
        pauseLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center;
        pauseLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center;
        
        /* Controls */
        
        let swipeRight:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipedRight(_:)));
        swipeRight.direction = .right;
        view.addGestureRecognizer(swipeRight);
        
        
        let swipeLeft:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipedLeft(_:)));
        swipeLeft.direction = .left;
        view.addGestureRecognizer(swipeLeft);
        
        
        let swipeUp:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipedUp(_:)));
        swipeUp.direction = .up;
        view.addGestureRecognizer(swipeUp);
        
        
        let swipeDown:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipedDown(_:)));
        swipeDown.direction = .down;
        view.addGestureRecognizer(swipeDown);
        
        let doubleTap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(GameScene.doubleTap(_:)));
        doubleTap.numberOfTapsRequired = 2;
        view.addGestureRecognizer(doubleTap);
        
        /* Scoreboard */
        
        let c = childNode(withName: CoinName) as! SKSpriteNode;
        updateUI(c, coinStrike: coinStrike);
        
        scoreboard.fontSize = 72;
        scoreboard.fontColor = SKColor(red: 0, green: 0, blue: 0, alpha: 1);
        scoreboard.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top;
        scoreboard.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left;
        scoreboard.position = CGPoint(x:(5), y:(size.height - 5));
        self.addChild(scoreboard);
        
        /* set player */
        player = childNode(withName: PlayerName) as! SKSpriteNode;
        player.physicsBody!.categoryBitMask = PlayerBitMask;
        player.physicsBody!.contactTestBitMask = CoinBitMask | EnemyBitMask;
        player.position = CGPoint(x:self.frame.midX, y:self.frame.midY);
        
        /* configure entities */
        coin = childNode(withName: CoinName) as! SKSpriteNode;
        enemy = childNode(withName: EnemyName) as! SKSpriteNode;
        
        changeMovementRandom();
        
        /* Start spawning */
        spawn();
        
        spawnTimer = NSPausableTimer(timer:Timer.scheduledTimer(timeInterval: spawnInterval, target: self, selector: Selector("spawn"), userInfo: nil, repeats: true));
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // 1. Create local variables for two physics bodies
        var firstBody: SKPhysicsBody;
        var secondBody: SKPhysicsBody;
        
        // 2. Assign the two physics bodies so that the one with the lower category is always stored in firstBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA;
            secondBody = contact.bodyB;
        } else {
            firstBody = contact.bodyB;
            secondBody = contact.bodyA;
        }
        
        // 3. react to the contact between ball and coin
        if (firstBody.categoryBitMask == PlayerBitMask && secondBody.categoryBitMask == CoinBitMask){
            secondBody.node!.removeFromParent();
            nodeCounter -= 1;
            let coin = secondBody.node as! SKSpriteNode;
            levelUp(coin);
        }
        if (firstBody.categoryBitMask == PlayerBitMask && secondBody.categoryBitMask == EnemyBitMask){
            
            let addExplosion = SKAction.run({
                
                let tmp = self.childNode(withName: self.ExplosionName) as! SKSpriteNode;
                let explosion = tmp.copy() as! SKSpriteNode;
                
                explosion.position = secondBody.node!.position;
                
                self.addChild(explosion);
                
            });
            
            let gameOver = SKAction.run({
                
                if let view_ = self.view {
                    let gameOverScene = GameOverScene(fileNamed:"GameOverScene");
                    gameOverScene!.size = self.scene!.size;
                    gameOverScene!.run(self.explosionSound);
                    gameOverScene!.score = self.score;
                    view_.presentScene(gameOverScene);
                }
                
            });
            
            let sequence = SKAction.sequence([addExplosion, SKAction.wait(forDuration: 0.05), gameOver]);
            run(sequence);
        }
    }
    
    func levelUp(_ coin:SKSpriteNode){
        
        run(coinSound);
        
        score+=coinStrike;
        updateUI(coin, coinStrike: coinStrike);
        
        coinStrike = min(coinStrike+1, 10);
        
        strikeTimer.invalidate();
        strikeTimer = Timer.scheduledTimer(timeInterval: 1.25, target: self, selector: #selector(GameScene.resetStrike), userInfo: nil, repeats: false);
        
        if(score%8 == 0){
            max(playerSpeed+1, 30);
        }
        if(score%15 == 0){
            spawnInterval = min(spawnInterval-0.2, 1);
            
            spawnTimer.reset(Timer.scheduledTimer(timeInterval: spawnInterval, target: self, selector: Selector("spawn"), userInfo: nil, repeats: true));
        }
    }
    
    func resetStrike(){
        coinStrike = 1;
    }
    
    func spawn(){
        
        if(nodeCounter+1 < nodeLimit){
            
            nodeCounter += 1;
            
            var spawnedObject = SKSpriteNode(), tmp = SKSpriteNode();
            
            var time = 0.0;
            
            if(arc4random_uniform(4) == 0){
                //enemy
                tmp = childNode(withName: EnemyName) as! SKSpriteNode;
                spawnedObject = tmp.copy() as! SKSpriteNode;
                spawnedObject.name = EnemyNodeName;
                spawnedObject.physicsBody!.categoryBitMask = EnemyBitMask;
                time = 8;
            }else{
                //coin
                tmp = childNode(withName: CoinName) as! SKSpriteNode;
                spawnedObject = tmp.copy() as! SKSpriteNode;
                spawnedObject.name = CoinNodeName;
                spawnedObject.physicsBody!.categoryBitMask = CoinBitMask;
                time = 5.5;
            }
            
            var randomX = arc4random_uniform(UInt32(size.width - spawnedObject.size.width)) + UInt32(spawnedObject.size.width / 2);
            var randomY = arc4random_uniform(UInt32(size.height - spawnedObject.size.height)) + UInt32(spawnedObject.size.height / 2);
            
            while(canSpawn(CGFloat(randomX), y: CGFloat(randomY)) == false){
                randomX = arc4random_uniform(UInt32(size.width - spawnedObject.size.width)) + UInt32(spawnedObject.size.width / 2);
                randomY = arc4random_uniform(UInt32(size.height - spawnedObject.size.height)) + UInt32(spawnedObject.size.height / 2);
            }
            
            spawnedObject.position.x = CGFloat(randomX);
            spawnedObject.position.y = CGFloat(randomY);
            
            
            let despawnTimer = NSPausableTimer(timer: Timer.scheduledTimer(timeInterval: time, target: self, selector: "despawn:", userInfo: NSPair(first:spawnedObject, second:despawnTimers.count as AnyObject), repeats: false));
            
            despawnTimers.append(despawnTimer);
            
            self.addChild(spawnedObject);
        }
    }
    
    func despawn(_ timer:Timer!){
        let pair = timer.userInfo as! NSPair;
        let objectToDespawn = pair.first as! SKNode;
        let index = pair.second as! Int;
        
        objectToDespawn.removeFromParent();
        
        if(objectToDespawn.name != StrikeName){
            nodeCounter = max(nodeCounter - 1, 0);
        }
        
        if(index != -1 && index < despawnTimers.count){
            despawnTimers.remove(at: index);
        }
        
    }
    
    func canSpawn(_ x:CGFloat, y:CGFloat) -> Bool{
        
        var pointBotomLeft  = CGPoint(x: 0, y: 0);
        var pointTopRight   = CGPoint(x: 0, y: 0);
        
        switch(playerMoveDirection){
        case MOVEMENT_TOP:
            
            pointBotomLeft.x    = player.position.x - playerSafeZone;
            pointBotomLeft.y    = player.position.y - playerSafeZone;
            
            pointTopRight.x     = player.position.x + playerSafeZone;
            pointTopRight.y     = player.position.y + (35 * playerSpeed);
            
            break;
        case MOVEMENT_LEFT:
            
            pointBotomLeft.x    = player.position.x - (35 * playerSpeed);
            pointBotomLeft.y    = player.position.y - playerSafeZone;
            
            pointTopRight.x     = player.position.x + playerSafeZone;
            pointTopRight.y     = player.position.y + playerSafeZone;
            
            break;
        case MOVEMENT_BOTTOM:
            
            pointBotomLeft.x    = player.position.x - playerSafeZone;
            pointBotomLeft.y    = player.position.y - (35 * playerSpeed);
            
            pointTopRight.x     = player.position.x + playerSafeZone;
            pointTopRight.y     = player.position.y + playerSafeZone;
            
            break;
        case MOVEMENT_RIGHT:
            
            pointBotomLeft.x    = player.position.x - playerSafeZone;
            pointBotomLeft.y    = player.position.y - playerSafeZone;
            
            pointTopRight.x     = player.position.x + (35 * playerSpeed);
            pointTopRight.y     = player.position.y + playerSafeZone;
            
            break;
        default:
            break;
        }
        
        //check if spawn point is insed the rect
        
        if(x >= pointBotomLeft.x && x <= pointTopRight.x && y >= pointBotomLeft.y && y <= pointTopRight.y){
            return false;
        }
        
        
        return true;
    }
    
    func pause(_ pause:Bool){
        
        if(pause == false && scene!.view!.isPaused == true){
            
            pauseOverlay.removeFromParent();
            pauseLabel.removeFromParent();
            
            //replay them
            
            spawnTimer.resume();
            
            for(i in 0 ..< despawnTimers.count){
                despawnTimers[i].resume();
            }
            
            PAUSED = false;
            scene!.view!.isPaused = false;
            
        }else if(pause == true){
            
            let me = self;
            
            spawnTimer.pause();
            
            for(timer) in despawnTimers{
                timer.pause();
            }
            
            let addPauseElements = SKAction.run({
                me.addChild(me.pauseOverlay);
                me.addChild(me.pauseLabel);
            });
            
            let pauseScene = SKAction.run({
                me.PAUSED = true;
                me.scene!.view!.isPaused = true;
            });
            
            let sequence = SKAction.sequence([addPauseElements, pauseScene]);
            
            run(sequence);
            
        }
        
    }
    
    func updateUI(_ coin:SKSpriteNode, coinStrike:Int){
        let strikeCount                     = SKLabelNode(fontNamed: "Gill Sans");
        strikeCount.text                    = "+" + String(coinStrike);
        strikeCount.fontSize                = 55;
        strikeCount.name                    = StrikeName;
        
        if(coinStrike >= 10){
            strikeCount.fontColor           = SKColor(red: 0.906, green: 0.298, blue: 0.235, alpha: 1);
        }else if(coinStrike >= 7){
            strikeCount.fontColor           = SKColor(red: 0.827, green: 0.329, blue: 0, alpha: 1);
        }else if(coinStrike >= 5){
            strikeCount.fontColor           = SKColor(red: 0.902, green: 0.494, blue: 0.133, alpha: 1);
        }else if(coinStrike >= 3){
            strikeCount.fontColor           = SKColor(red: 0.902, green: 0.298, blue: 0.235, alpha: 1);
        }else{
            strikeCount.fontColor           = SKColor(red: 0.953, green: 0.612, blue: 0.071, alpha: 1);
        }
        
        
        strikeCount.verticalAlignmentMode   = SKLabelVerticalAlignmentMode.center;
        strikeCount.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center;
        
        strikeCount.position.y              = coin.position.y + 30;
        
        if(arc4random_uniform(2) == 0){
            
            strikeCount.zRotation           = CGFloat(M_PI_4);
            strikeCount.position.x          = coin.position.x - 30;
            
        }else{
            
            strikeCount.zRotation           = CGFloat(-M_PI_4);
            strikeCount.position.x          = coin.position.x + 30;
            
        }
        
        addChild(strikeCount);
        
        Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(GameScene.despawn(_:)), userInfo: NSPair(first:strikeCount, second:-1 as AnyObject), repeats: false);
        
        scoreboard.text = String(score);
    }
    
    func swipedRight(_ sender:UISwipeGestureRecognizer){
        changeMoveDirection(MOVEMENT_RIGHT);
    }
    
    func swipedLeft(_ sender:UISwipeGestureRecognizer){
        changeMoveDirection(MOVEMENT_LEFT);
    }
    
    func swipedUp(_ sender:UISwipeGestureRecognizer){
        changeMoveDirection(MOVEMENT_TOP);
    }
    
    func swipedDown(_ sender:UISwipeGestureRecognizer){
        changeMoveDirection(MOVEMENT_BOTTOM);
    }
    
    func doubleTap(_ sender:UITapGestureRecognizer){
        if(!PAUSED){
            pause(true);
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if(PAUSED){
            
            pause(false);
            
        }else{
        
            /*let touch = touches.first;
            let touchLocation = touch!.locationInNode(self);*/
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){
        touching = false;
    }
    
    func changeMoveDirection(_ dir: CGFloat){
        playerMoveDirection = dir;
        
        player.zRotation = CGFloat(M_PI_2) * dir;
    }
    
    func changeMovementRandom(){
        var m = CGFloat(arc4random_uniform(4));
        while(playerMoveDirection == m){
            m = CGFloat(arc4random_uniform(4));
        }
        changeMoveDirection(m);
    }
   
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        
        //move
        
        var deltaX = CGFloat(0);
        var deltaY = CGFloat(0);
        
        switch(playerMoveDirection){
            case MOVEMENT_TOP:
                deltaY += 1;
                break;
            case MOVEMENT_LEFT:
                deltaX -= 1;
                break;
            case MOVEMENT_BOTTOM:
                deltaY -= 1;
                break;
            case MOVEMENT_RIGHT:
                deltaX += 1;
                break;
            default:
                break;
        }
        
        var futureX = player.position.x + (deltaX * playerSpeed);
        var futureY = player.position.y + (deltaY * playerSpeed);
        
        let playerHalftWidth  = (player.size.width/2);
        let playerHalftHeight = (player.size.height/2);
        
        if(playerMoveDirection == MOVEMENT_RIGHT && futureX >= (size.width - playerHalftWidth)){
            
            futureX = size.width - playerHalftWidth;
            changeMoveDirection(MOVEMENT_LEFT);
            
        }else if(playerMoveDirection == MOVEMENT_LEFT && futureX <= playerHalftWidth){
            
            futureX = playerHalftWidth;
            changeMoveDirection(MOVEMENT_RIGHT);
            
        }else if(playerMoveDirection == MOVEMENT_TOP && futureY >= (size.height - playerHalftHeight)){
            
            futureY = size.height - playerHalftHeight;
            changeMoveDirection(MOVEMENT_BOTTOM);
            
        }else if(playerMoveDirection == MOVEMENT_BOTTOM && futureY <= playerHalftHeight){
            
            futureY = playerHalftHeight;
            changeMoveDirection(MOVEMENT_TOP);
            
        }
        
        player.position.x = futureX;
        player.position.y = futureY;
        
    }
    
    func deleteTimerFromArray(_ element: NSPausableTimer, list: Array<NSPausableTimer>) ->Array<NSPausableTimer> {
        return list.filter() { $0 !== element }
    }
    
}
