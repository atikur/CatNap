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
        static let Cat: UInt32 = 0b1            // 1
        static let Block: UInt32 = 0b10         // 2
        static let Bed: UInt32 = 0b100          // 4
        static let Edge: UInt32 = 0b1000        // 8
        static let Label: UInt32 = 0b10000      // 16
        static let Spring: UInt32 = 0b100000    // 32
        static let Hook: UInt32 = 0b1000000     // 64
    }
    
    var bedNode: SKSpriteNode!
    var catNode: SKSpriteNode!
    var currentLevel: Int = 0
    
    var hookBaseNode: SKSpriteNode!
    var hookNode: SKSpriteNode!
    var hookJoint: SKPhysicsJoint!
    var ropeNode: SKSpriteNode!
    
    class func level(levelNum: Int) -> GameScene? {
        let scene = GameScene(fileNamed: "Level\(levelNum)")
        scene.currentLevel = levelNum
        scene.scaleMode = .AspectFill
        return scene
    }
    
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
        catNode.physicsBody!.collisionBitMask = PhysicsCategory.Block | PhysicsCategory.Edge | PhysicsCategory.Spring
        
        // set contact bitmask for cat
        catNode.physicsBody!.contactTestBitMask = PhysicsCategory.Bed | PhysicsCategory.Edge
        
        addHook()
        
        makeCompundNode()
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.Cat | PhysicsCategory.Bed {
            win()
        } else if collision == PhysicsCategory.Cat | PhysicsCategory.Edge {
            lose()
        } else if collision == PhysicsCategory.Edge | PhysicsCategory.Label {
            var labelNode: SKNode
            if contact.bodyA.categoryBitMask == PhysicsCategory.Label {
                labelNode = contact.bodyA.node!
            } else {
                labelNode = contact.bodyB.node!
            }
            
            if labelNode.userData == nil {
                labelNode.userData = NSMutableDictionary(object: 1 as Int, forKey: "bounceCount")
            } else {
                let bounceCount = labelNode.userData!.valueForKey("bounceCount") as Int + 1
                if bounceCount == 4 {
                    labelNode.runAction(SKAction.removeFromParent())
                }
                labelNode.userData?.setValue(bounceCount, forKey: "bounceCount")
            }
        }
        
        if collision == PhysicsCategory.Cat | PhysicsCategory.Hook {
            catNode.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
            catNode.physicsBody!.angularVelocity = 0
            
            let pinPoint = CGPoint(
                x: hookNode.position.x,
                y: hookNode.position.y + hookNode.size.height/2)
            
            hookJoint = SKPhysicsJointFixed.jointWithBodyA(contact.bodyA, bodyB: contact.bodyB, anchor: pinPoint)
            physicsWorld.addJoint(hookJoint)
        }
    }
    
    func sceneTouched(location: CGPoint) {
        let targetNode = self.nodeAtPoint(location)
        
        if targetNode.parent?.name == "compoundNode" {
            targetNode.parent!.removeFromParent()
        }
        
        if targetNode.physicsBody == nil {
            return
        }
        
        if targetNode.physicsBody!.categoryBitMask == PhysicsCategory.Block {
            targetNode.removeFromParent()
            runAction(SKAction.playSoundFileNamed("pop.mp3", waitForCompletion: false))
            return
        }
        
        if targetNode.physicsBody!.categoryBitMask == PhysicsCategory.Spring {
            let spring = targetNode as SKSpriteNode
            spring.physicsBody!.applyImpulse(
                CGVector(dx: 0, dy: 160),
                atPoint: CGPoint(x: spring.size.width/2, y: spring.size.height))
            
            targetNode.runAction(SKAction.sequence([
                SKAction.waitForDuration(1),
                SKAction.removeFromParent()
                ]))
            return
        }
        
        // release cat from hook
        if targetNode.physicsBody?.categoryBitMask == PhysicsCategory.Cat && hookJoint != nil {
            releaseHook()
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
    }
    
    func newGame() {
        view!.presentScene(GameScene.level(currentLevel))
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
    
    func win() {
        catNode.physicsBody = nil
        
        let curlY = bedNode.position.y + catNode.size.height/3
        let curlPoint = CGPoint(x: bedNode.position.x, y: curlY)
        
        catNode.runAction(SKAction.group([
            SKAction.moveTo(curlPoint, duration: 0.66),
            SKAction.rotateToAngle(0, duration: 0.5)
            ]))
        
        inGameMessage("Nice job!")
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(5),
            SKAction.runBlock(newGame)
            ]))
        
        catNode.runAction(SKAction.animateWithTextures([
            SKTexture(imageNamed: "cat_curlup1"),
            SKTexture(imageNamed: "cat_curlup2"),
            SKTexture(imageNamed: "cat_curlup3")
            ], timePerFrame: 0.25))
        
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        runAction(SKAction.playSoundFileNamed("win.mp3", waitForCompletion: false))
    }
    
    override func didSimulatePhysics() {
        if let body = catNode.physicsBody {
            if body.contactTestBitMask != PhysicsCategory.None && fabs(catNode.zRotation) > CGFloat(45).degreesToRadians() {
                if hookJoint == nil {
                    lose()
                }
            }
        }
    }
    
    func addHook() {
        hookBaseNode = childNodeWithName("hookBase") as? SKSpriteNode
        
        if hookBaseNode == nil {
            return
        }
        
        let ceilingFix = SKPhysicsJointFixed.jointWithBodyA(hookBaseNode.physicsBody, bodyB: physicsBody, anchor: CGPointZero)
        physicsWorld.addJoint(ceilingFix)
        
        // add rope
        ropeNode = SKSpriteNode(imageNamed: "rope")
        ropeNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        ropeNode.zRotation = CGFloat(270).degreesToRadians()
        ropeNode.position = hookBaseNode.position
        addChild(ropeNode)
        
        // add hook
        hookNode = SKSpriteNode(imageNamed: "hook")
        hookNode.position = CGPoint(x: hookBaseNode.position.x, y: hookBaseNode.position.y - ropeNode.size.width)
        
        hookNode.physicsBody = SKPhysicsBody(circleOfRadius: hookNode.size.width/2)
        hookNode.physicsBody!.categoryBitMask = PhysicsCategory.Hook
        hookNode.physicsBody!.contactTestBitMask = PhysicsCategory.Cat
        hookNode.physicsBody!.collisionBitMask = PhysicsCategory.None
        
        addChild(hookNode)
        
        let ropeJoint = SKPhysicsJointSpring.jointWithBodyA(hookBaseNode.physicsBody, bodyB: hookNode.physicsBody, anchorA: hookBaseNode.position, anchorB: CGPoint(x: hookNode.position.x, y: hookNode.position.y + hookNode.size.height/2))
        
        physicsWorld.addJoint(ropeJoint)
        
        // constraint to orient rope toward hook
        let range = SKRange(lowerLimit: 0.0, upperLimit: 0.0)
        let orientConstraint = SKConstraint.orientToNode(hookNode, offset: range)
        ropeNode.constraints = [orientConstraint]
        
        hookNode.physicsBody!.applyImpulse(CGVector(dx: 50, dy: 0))
    }
    
    func releaseHook() {
        catNode.zRotation = 0
        hookNode.physicsBody!.contactTestBitMask = PhysicsCategory.None
        physicsWorld.removeJoint(hookJoint)
        hookJoint = nil
    }
    
    func makeCompundNode() {
        let compundNode = SKNode()
        compundNode.zPosition = -1
        compundNode.name = "compoundNode"
        
        var bodies: [SKPhysicsBody] = [SKPhysicsBody]()
        
        enumerateChildNodesWithName("stone", usingBlock: {
            node, _ in
            node.removeFromParent()
            compundNode.addChild(node)
            
            let body = SKPhysicsBody(rectangleOfSize: node.frame.size, center: node.position)
            bodies.append(body)
        })
        
        compundNode.physicsBody = SKPhysicsBody(bodies: bodies)
        
        compundNode.physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Cat | PhysicsCategory.Block
        addChild(compundNode)
    }
}
