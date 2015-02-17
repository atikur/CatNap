//
//  GameScene.swift
//  CatNap
//
//  Created by Atikur Rahman on 2/17/15.
//  Copyright (c) 2015 Atikur Rahman. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    struct PhysicsCategory {
        static let None: UInt32 = 0
        static let Cat: UInt32 = 0b1        // 1
        static let Block: UInt32 = 0b10     // 2
        static let Bed: UInt32 = 0b100      // 4
    }
    
    var bedNode: SKSpriteNode!
    var catNode: SKSpriteNode!
    
    override func didMoveToView(view: SKView) {
        // Calculate playable margin
        let maxAspectRatio: CGFloat = 16.0/9.0 // iPhone 5
        let maxAspectRatioHeight = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight)/2
        let playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin*2)
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
        
        bedNode = childNodeWithName("bed") as SKSpriteNode
        catNode = childNodeWithName("cat") as SKSpriteNode
        
        // create physics body for bed node
        let bedBodySize = CGSize(width: 40, height: 30)
        bedNode.physicsBody = SKPhysicsBody(rectangleOfSize: bedBodySize)
        bedNode.physicsBody!.dynamic = false
        
        // create physics body for cat
        let catBodyTexture = SKTexture(imageNamed: "cat_body")
        catNode.physicsBody = SKPhysicsBody(texture: catBodyTexture, size: catNode.size)
        
        SKTAudio.sharedInstance().playBackgroundMusic("backgroundMusic.mp3")
        
        // set category bitmask and collision bitmask for bed node
        bedNode.physicsBody!.categoryBitMask = PhysicsCategory.Bed
        bedNode.physicsBody!.collisionBitMask = PhysicsCategory.None
        
        // set category bitmask and collision bitmask for cat node
        catNode.physicsBody!.categoryBitMask = PhysicsCategory.Cat
        catNode.physicsBody!.collisionBitMask = PhysicsCategory.Block
    }
    
    func sceneTouched(location: CGPoint) {
        let targetNode = self.nodeAtPoint(location)
        
        if targetNode.physicsBody == nil {
            return
        }
        
        if targetNode.physicsBody!.categoryBitMask == PhysicsCategory.Block {
            targetNode.removeFromParent()
            runAction(SKAction.playSoundFileNamed("pop.mp3", waitForCompletion: false))
            return
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch: UITouch = touches.anyObject() as UITouch
        sceneTouched(touch.locationInNode(self))
    }
}
