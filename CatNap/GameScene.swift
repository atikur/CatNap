//
//  GameScene.swift
//  CatNap
//
//  Created by Atikur Rahman on 2/17/15.
//  Copyright (c) 2015 Atikur Rahman. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    struct PhysicsCategory {
        static let None: UInt32 = 0
        static let Cat: UInt32 = 0b1        // 1
        static let Block: UInt32 = 0b10     // 2
        static let Bed: UInt32 = 0b100      // 4
        static let Edge: UInt32 = 0b1000    // 8
        static let Label: UInt32 = 0b10000  // 16
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
        physicsBody!.categoryBitMask = PhysicsCategory.Edge
        
        // set contact delegate of physics world
        physicsWorld.contactDelegate = self
        
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
        catNode.physicsBody!.collisionBitMask = PhysicsCategory.Block | PhysicsCategory.Edge
        
        // set contact bitmask for cat
        catNode.physicsBody!.contactTestBitMask = PhysicsCategory.Bed | PhysicsCategory.Edge
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.Cat | PhysicsCategory.Bed {
            println("SUCCESS")
        } else if collision == PhysicsCategory.Cat | PhysicsCategory.Edge {
            lose()
        }
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
    
    func inGameMessage(text: String) {
        let label: SKLabelNode = SKLabelNode(fontNamed: "AvenirNext-Regular")
        label.text = text
        label.fontSize = 128.0
        label.color = SKColor.whiteColor()
        
        label.position = CGPoint(x: frame.size.width/2,
                                 y: frame.size.height/2)
        
        label.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        label.physicsBody!.collisionBitMask = PhysicsCategory.Edge
        label.physicsBody!.categoryBitMask = PhysicsCategory.Label
        label.physicsBody!.contactTestBitMask = PhysicsCategory.Edge
        label.physicsBody!.restitution = 0.7
        
        addChild(label)
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(3),
            SKAction.removeFromParent()
            ]))
    }
    
    func newGame() {
        let scene = GameScene(fileNamed: "GameScene")
        scene.scaleMode = .AspectFill
        view!.presentScene(scene)
    }
    
    func lose() {
        catNode.physicsBody!.contactTestBitMask = PhysicsCategory.None
        catNode.texture = SKTexture(imageNamed: "cat_awake")
        
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        runAction(SKAction.playSoundFileNamed("lose.mp3", waitForCompletion: false))
        inGameMessage("Try again...")
        runAction(SKAction.sequence([
            SKAction.waitForDuration(5),
            SKAction.runBlock(newGame)
            ]))
    }
}
