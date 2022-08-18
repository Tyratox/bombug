//
//  GameViewController.swift
//  BomBug
//
//  Created by Nico Hauser on 06.08.15.
//  Copyright (c) 2015 tyratox.ch. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {

    @IBOutlet weak var btnStartGame: UIButton!;
    @IBOutlet weak var btnCredits: UIButton!;
    @IBOutlet weak var creditsText: UITextView!;
    
    var skView                  = SKView();
    let screenSize              = UIScreen.main.bounds.size;
    var sceneSize               = CGSize(width: 0, height: 0);
    let whiteScreen             = WhiteScreen(fileNamed:"WhiteScreen");
    var backgroundMusicPlayer   : AVAudioPlayer!;
    let appDelegate             = UIApplication.shared.delegate as! AppDelegate;
    
    var scaleFactor             = CGFloat(2);
    
    @IBAction func creditsClicked(_ sender: UIButton) {
    }
    
    @IBAction func startGame(_ sender: UIButton) {
        btnStartGame.removeFromSuperview();
        btnCredits.removeFromSuperview();
        creditsText.removeFromSuperview();
        _startGame();
    }
    override func viewDidLoad() {
        super.viewDidLoad();
        
        let compareSize = round(screenSize.height * screenSize.width / 10E3);
        
        if(compareSize <= 20){
            scaleFactor = CGFloat(2);
        }else if(compareSize <= 40){
            scaleFactor = CGFloat(1.75);
        }else if(compareSize <= 60){
            scaleFactor = CGFloat(1.5);
        }else if(compareSize <= 80){
            scaleFactor = CGFloat(1.25);
        }else{
            scaleFactor = CGFloat(1);
        }
        
        sceneSize = CGSize(width: screenSize.width * scaleFactor, height: screenSize.height * scaleFactor);
        
        whiteScreen!.size = sceneSize;
        whiteScreen!.isPaused = true;
        
        skView = self.view as! SKView;
        skView.showsFPS = false;
        skView.showsNodeCount = false;
        
        skView.presentScene(whiteScreen);
        
        creditsText.scrollRangeToVisible(NSMakeRange(0, 0));
        
        playBackgroundMusic("Ouroboros.mp3");
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if(!appDelegate.saveScore){
            
            let alertController = UIAlertController(title: "Jailbreak Detected!", message: "In order to prevent boring game center highscores, your score won't be saved as long as your device is jailbroken!", preferredStyle: UIAlertControllerStyle.alert);
            
            alertController.addAction(UIAlertAction(title: "OK :(", style: UIAlertActionStyle.default,handler: nil));
            
            self.present(alertController, animated: true, completion: nil);
            
        }
        
    }
    
    func _startGame(){
        if let scene = GameScene(fileNamed:"GameScene") {
            
            scene.size = sceneSize;
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = SKSceneScaleMode.aspectFit;
            
            skView.presentScene(scene)
        }
    }
    
    func playBackgroundMusic(_ filename: String) {
        let url = Bundle.main.url(forResource: filename, withExtension: nil);
        do{
            try backgroundMusicPlayer = AVAudioPlayer(contentsOf: url!);
        }catch(_){}
        
        backgroundMusicPlayer.numberOfLoops = -1;
        backgroundMusicPlayer.prepareToPlay();
        backgroundMusicPlayer.volume = 0.75;
        backgroundMusicPlayer.play();
    }
    
    func pauseGame(){
        let skView = self.view as! SKView;
        let gameScene = skView.scene as? GameScene;
        if(gameScene != nil){
            gameScene?.pause(true);
        }
    }

    override var shouldAutorotate : Bool {
        return false;
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
}
