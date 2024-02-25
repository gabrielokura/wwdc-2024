//
//  File.swift
//  
//
//  Created by Gabriel Motelevicz Okura on 18/02/24.
//

import SceneKit

class Checkpoint: SCNNode {
    static let earthCheckpoints: [SCNVector3] = []
    
    static let iceCheckpoints: [SCNVector3] = [
        SCNVector3(0, 0.514, -8),
        SCNVector3(0, 0.514, -6),
        SCNVector3(-3, 0.514, -6),
        SCNVector3(-1.5, 0.514, -6),
        SCNVector3(1.5, 0.514, -6),
        SCNVector3(3, 0.514, -6),
        SCNVector3(-3, 0.514, -5),
        SCNVector3(3, 0.514, -5),
        SCNVector3(-3, 0.514, -4),
        SCNVector3(3, 0.514, -4),
        SCNVector3(-3, 0.514, -3),
        SCNVector3(3, 0.514, -3),
        SCNVector3(-3, 0.514, -2),
        SCNVector3(3, 0.514, -2),
        SCNVector3(-1.5, 0.514, -2),
        SCNVector3(1.5, 0.514, -2),
        SCNVector3(0, 0.514, -2)
    ]
    
    static let mixCheckpoints: [SCNVector3] = [
        SCNVector3(5, 0.514, -8),
        SCNVector3(5, 0.514, -6),
        SCNVector3(4, 0.514, -6),
        SCNVector3(4, 0.514, -8),
        SCNVector3(2.5, 0.514, -8),
        SCNVector3(2.5, 0.514, -6),
        SCNVector3(2, 0.514, -3),
        SCNVector3(-2, 0.514, -3),
        SCNVector3(-3, 0.514, -2),
        SCNVector3(2, 0.514, -5),
        SCNVector3(0, 0.514, -3),
        SCNVector3(0, 0.514, 0),
        SCNVector3(3, 0.514, -3),
        SCNVector3(-3, 0.514, 0),
        SCNVector3(0, 0.514, -1.5),
        SCNVector3(0, 0.514, 1.5)
    ]
    
    let id: Int
    let points: Double
    let isTrophy: Bool
    
    init (id: Int, position: SCNVector3, points: Double, isTrophy: Bool) {
        self.id = id
        self.points = points
        self.isTrophy = isTrophy
        
        super.init()
        
        let sphere = SCNSphere(radius: 0.1)
        self.geometry = sphere
        let contactShape = SCNSphere(radius: 0.2)
        let shape = SCNPhysicsShape(geometry: contactShape, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody?.isAffectedByGravity = false
        
        self.physicsBody?.categoryBitMask = CollisionCategory.checkpoint.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.alien.rawValue
        self.physicsBody?.collisionBitMask = CollisionCategory.checkpoint.rawValue
        
        self.name =  isTrophy ? "trophy" : "checkpoint\(id)"
        
        self.position = position
        
        // add texture
        let material = SCNMaterial()
        material.diffuse.contents = isTrophy ? UIColor.purple : UIColor.yellow
        self.geometry?.materials  = [material]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
