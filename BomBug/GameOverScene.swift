//
//  GameOverScene.swift
//  BomBug
//
//  Created by Nico Hauser on 07.08.15.
//  Copyright © 2015 tyratox.ch. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene {
    
    var gameOverLabel = SKLabelNode(fontNamed:"Gill Sans");
    
    var score : Int = -1 {
        // 1.
        didSet {
            gameOverLabel.text = String(score) + " " + (score == 1 ? "Point" : "Points");
        }
    }
    
    override func didMove(to view: SKView) {
        
        gameOverLabel.fontColor = SKColor(red: 0, green: 0, blue: 0, alpha: 1);
        gameOverLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center;
        gameOverLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center;
        gameOverLabel.fontSize = 72;
        gameOverLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY);
        
        self.addChild(gameOverLabel);
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let view = view {
            let gameScene = GameScene(fileNamed:"GameScene");
            gameScene!.size = self.scene!.size;
            view.presentScene(gameScene);
        }
    }
    
}
