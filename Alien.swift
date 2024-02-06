//
//  Alien.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 26/07/23.
//

import SceneKit

enum AlienType {
    case purple
    
    var health: Int {
        switch self {
        case .purple:
            return 100
        }
    }
    
    var initialPosition: SCNVector3 {
        switch self {
        case .purple:
            return SCNVector3(5, 1, -10)
        }
    }
    
    var pathNodeName: String {
        switch self {
        case .purple:
            return "purple_path"
        }
    }
}

class Alien: SCNNode, Identifiable {
    let id = UUID()
    
    var lifeNode: SCNNode!
    var type: AlienType!
    var path: [SCNVector3] = []
    var sceneNode: SCNNode!
    
    var fullHealth: Int!
    var health: Int!
    
    var isDead = false
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    init?(_ type: AlienType, in sceneNode: SCNNode!) {
        guard let alienScene = SCNScene(named: "enemy_ufoPurple.scn") else {
            return nil
        }
        guard let alienNode = alienScene.rootNode.childNodes.first else {
            return nil
        }
        
        super.init()
        
        self.geometry = alienNode.geometry
        
        for node in alienNode.childNodes {
            self.addChildNode(node)
        }
        
        self.setupPhysicsBody()
        
        self.type = type
        self.lifeNode = self.childNode(withName: "life", recursively: false)!
        self.lifeNode.pivot = SCNMatrix4MakeTranslation(-0.5, 0, 0)
        self.lifeNode.position = SCNVector3(-0.5, 0.5, 0)
        self.lifeNode.isHidden = true
        self.sceneNode = sceneNode
        
        self.fullHealth = type.health
        self.health = type.health
        
        self.position = type.initialPosition
        self.path = self.setupPath()
        
        self.startMovement()
    }
    
    func setupPhysicsBody() {
        let square = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        let shape = SCNPhysicsShape(geometry: square, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        self.physicsBody?.isAffectedByGravity = false
        
        self.physicsBody?.categoryBitMask = CollisionCategory.alien.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.tower.rawValue | CollisionCategory.bullet.rawValue
        self.physicsBody?.collisionBitMask = CollisionCategory.bullet.rawValue
    }
    
    func setupPath() -> [SCNVector3]{
        let pathNodeName = type.pathNodeName
        var result: [SCNVector3] = []
        
        guard let pathNode = sceneNode.childNode(withName: pathNodeName, recursively: false) else {
            return []
        }
        
        for nodes in pathNode.childNodes {
            result.append(nodes.position)
        }
        
        return result
    }
    
    func startMovement() {
        print("starting movement")
        
        let moveActions = path.map { current in
            SCNAction.move(to: current, duration: 1)
        }
        
        let sequence = SCNAction.sequence(moveActions)
        
        self.runAction(sequence) {
            print("finalizou movimento -> explodir alien")
            self.takeDamage(self.health)
        }
    }
    
    func takeDamage(_ damage: Int) {
        health = max(health - damage, 0)
        
        if health == 0 {
            self.removeFromParentNode()
            isDead = true
        }
        
        lifeNode.isHidden = false
        let healthScale = Float(health)/Float(fullHealth)
        lifeNode.scale.x = healthScale
    }
}
