//
//  GameScene.swift
//  CatNap
//
//  Created by Atikur Rahman on 2/17/15.
//  Copyright (c) 2015 Atikur Rahman. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
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
    }
}
