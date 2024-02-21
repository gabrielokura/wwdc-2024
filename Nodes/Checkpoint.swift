//
//  File.swift
//  
//
//  Created by Gabriel Motelevicz Okura on 18/02/24.
//

import SceneKit

class Checkpoint: SCNNode {
    static let positions: [SCNVector3] = [
        SCNVector3(5, 0.514, -8),
        SCNVector3(5, 0.514, -6),
        SCNVector3(4, 0.514, -6),
        SCNVector3(4, 0.514, -8),
        SCNVector3(2.5, 0.514, -8),
        SCNVector3(2.5, 0.514, -6),
        SCNVector3(2, 0.514, -3),
        SCNVector3(2, 0.514, -5),
        SCNVector3(0, 0.514, -3),
        SCNVector3(0, 0.514, 0),
    ]
    
    let id: Int
    
    init (id: Int, position: SCNVector3) {
        self.id = id
        
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
        
        self.name = "checkpoint\(id)"
        
        self.position = position
        
        // add texture
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        self.geometry?.materials  = [material]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
