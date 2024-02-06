//
//  Tower.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 28/07/23.
//

import SceneKit

enum TowerLevel {
case idle, wood1, wood2, base, bottom, middle, top, full
    
    var sceneName: String {
        switch self {
        case .wood1:
            return "woodStructure.scn"
        case .wood2:
            return "woodStructure_high.scn"
        case .base:
            return "towerA_1.scn"
        case .bottom:
            return "towerA_2.scn"
        case .middle:
            return "towerA_3.scn"
        case .top:
            return "towerA_4.scn"
        case .full:
            return "towerA_5.scn"
        case .idle:
            return ""
        }
    }
}

class Tower: SCNNode {
    var sceneNode: SCNNode!
    var target: Alien?
    
    var level: TowerLevel = .idle
    
    var cannon: Cannon!
    var isFiring = false
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    init(in sceneNode: SCNNode!) {
        super.init()
        
        self.name = "tower_base"
        self.position = SCNVector3(self.position.x, self.position.y + 0.2, self.position.z)
        
        self.sceneNode = sceneNode
        self.setupPhysicsBody()
        self.setupGrowingAnimation()
    }
    
    func setupPhysicsBody() {
        let square = SCNBox(width: 3.5, height: 3, length: 3.5, chamferRadius: 0)
        let shape = SCNPhysicsShape(geometry: square, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody?.isAffectedByGravity = false
        
        self.physicsBody?.categoryBitMask = CollisionCategory.tower.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.alien.rawValue
        self.physicsBody?.collisionBitMask = 0
    }
    
    func setupGrowingAnimation() {
        sceneNode.addChildNode(self)
        
        let firstWait = SCNAction.wait(duration: 0.05)
        let finalWait = SCNAction.wait(duration: 0.5)
        let timeBetweenAnimations = SCNAction.wait(duration: 0.1)
        
        let grow = SCNAction.run { node in
            node.childNodes.first?.removeFromParentNode()
            
            switch self.level {
            case .idle:
                self.level = .wood1
            case .wood1:
                self.level = .wood2
            case .wood2:
                self.level = .base
            case .base:
                self.level = .bottom
            case .bottom:
                self.level = .middle
            case .middle:
                self.level = .top
            case .top:
                self.level = .full
            case .full:
                self.level = .full
            }
            
            guard let scene = SCNScene(named: self.level.sceneName) else {
                print("Não achou level scene name \(self.level.sceneName)")
                return
            }
            guard let newNode = scene.rootNode.childNodes.first else {
                print("Root node não tem filhos")
                return
            }
            node.addChildNode(newNode)
        }
        
        let addCannon = SCNAction.run { node in
            let cannon = Cannon()
            self.cannon = cannon
            
            cannon.position = SCNVector3(cannon.position.x, cannon.position.y + 1.3, cannon.position.z)
            print("cannon position \(cannon.position)")
            node.addChildNode(cannon)
        }
        
        let sequence = SCNAction.sequence([firstWait, grow, timeBetweenAnimations, grow, timeBetweenAnimations, grow, timeBetweenAnimations, grow, timeBetweenAnimations, grow, timeBetweenAnimations, grow, finalWait, grow, addCannon])
        self.runAction(sequence)
    }
    
    func lockCannon(on alien: Alien) {
        target = alien
    }
    
    func unlockCannon() {
        target = nil
    }
    
    func aimCannon() {
        if target == nil {
            return
        }
        
        if target!.isDead {
            print("target is dead -> Unlock")
            unlockCannon()
            return
        }
        
        cannon.lockAim(in: target!)
    }
    
    func startFire() {
        if isFiring {
            return
        }
        
        isFiring = true
        cannon.fire()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: { // remove/replace ship after half a second to visualize collision
            self.isFiring = false
        })
    }
}
