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
            return SCNVector3(5, 0.5, -10)
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
    var sensorNode: SCNNode!
    
    var type: AlienType!
    var path: [SCNVector3] = []
    var sceneNode: SCNNode!
    var contactNode: SCNNode!
    
    var fullHealth: Int!
    var health: Int!
    
    var isDead = false
    
    var fitnessLevel: Double = 0
    static let inputCount: Int = 5
    static let outputCount: Int = 2
    
    let speedNormalizer: Float = 1
    
    let walls: [SCNNode]
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    init?(_ type: AlienType, in sceneNode: SCNNode!, walls: [SCNNode]) {
        guard let alienScene = SCNScene(named: "enemy_ufoPurple.scn") else {
            return nil
        }
        guard let alienNode = alienScene.rootNode.childNodes.first else {
            return nil
        }
        
        self.walls = walls
        
        super.init()
        
        self.geometry = alienNode.geometry
        
        for node in alienNode.childNodes {
            self.addChildNode(node)
        }
        
        self.setupPhysicsBody()
        self.setupLifeNode()
        
        self.type = type
        
        self.sceneNode = sceneNode
        
        self.fullHealth = type.health
        self.health = type.health
        
        self.position = type.initialPosition
        self.name = "alien"
    }
    
    private func setupLifeNode() {
        self.lifeNode = self.childNode(withName: "life", recursively: false)!
        self.lifeNode.pivot = SCNMatrix4MakeTranslation(-0.5, 0, 0)
        self.lifeNode.position = SCNVector3(-0.5, 0, 0)
        self.lifeNode.isHidden = true
    }
    
    private func setupPhysicsBody() {
        self.scale = SCNVector3(0.5, 0.5, 0.5)
        
        let shape = SCNPhysicsShape(geometry: self.boxShapeWithNodeSize(), options: nil)
        
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody?.isAffectedByGravity = false
        self.physicsBody?.angularVelocityFactor = SCNVector3(0, 0, 0)
        
        self.physicsBody?.categoryBitMask = CollisionCategory.alien.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.tower.rawValue | CollisionCategory.bullet.rawValue | CollisionCategory.terrain.rawValue
        self.physicsBody?.collisionBitMask = CollisionCategory.bullet.rawValue | CollisionCategory.terrain.rawValue
    }
    
    private func takeDamage(_ damage: Int) {
        health = max(health - damage, 0)
        
        if health == 0 {
            self.removeFromParentNode()
            isDead = true
            updateFitnessLevelWith(-100)
        }
        
        lifeNode.isHidden = false
        let healthScale = Float(health)/Float(fullHealth)
        lifeNode.scale.x = healthScale
    }
    
    func move(x: Double, z: Double) {
        let newVector = SCNVector3(x: Float(x)/speedNormalizer, y: 0, z: Float(z)/speedNormalizer)
        
//        self.physicsBody?.clearAllForces()
        self.physicsBody?.applyForce(newVector, asImpulse: false)
    }
    
    private func updateFitnessLevelWith(_ fitness: Double) {
        self.fitnessLevel += fitness
    }
    
    func generateInputDataForNeuralNetwork() -> [Double]{
        return getDirectionInput()
    }
    
    func onCollision(withBullet: Bool, contactPoint: SCNVector3) {
        print("Bateu e tomou 40 de dano")
        takeDamage(40)
    }
    
    private func getClosestWall() -> SCNNode {
        var closestWall = walls.first!
        var closestDistance = self.worldPosition.distanceModule(to: closestWall.worldPosition)
        
        for wall in walls {
            let distance = self.worldPosition.distanceModule(to: wall.worldPosition)
            
            if distance < closestDistance {
                closestDistance = distance
                closestWall = wall
            }
        }
        
        return closestWall
    }
}

//MARK:  Neural Network inputs
extension Alien {
    func getDirectionInput() -> [Double] {
        let wall = self.getClosestWall()
        
        print("Closest wall position \(wall.worldPosition)")
        
        let up = wall.worldPosition.x - self.worldPosition.x
        
        let right = 0 - self.worldPosition.z
        
        let firstResult = Double(up > 0 ? up : 0)
        let secondResult = Double(right > 0 ? right : 0)
        let thirdResult = Double(up < 0 ? up : 0)
        let forthResult = Double(right < 0 ? up : 0)
        
        print("Retuning [\(firstResult), \(secondResult), \(thirdResult), \(forthResult)]")
        
        return [firstResult, secondResult, thirdResult, forthResult]
    }
}

extension Alien {
    func boxShapeWithNodeSize() -> SCNGeometry {
        let min = self.boundingBox.min
        let max = self.boundingBox.max
        let w = CGFloat(max.x - min.x)/2
        let h = CGFloat(max.y - min.y)/2
        let l = CGFloat(max.z - min.z)/2
        
        return SCNBox (width: w , height: h , length: l, chamferRadius: 0.0)
    }
}

extension SCNVector3 {
    func distance(to vector: SCNVector3) -> SCNVector3 {
        let result = SCNVector3(self.x - vector.x, self.y - vector.y, self.z - vector.z)
        return result
    }
    
    func distanceModule(to vector: SCNVector3) -> Float {
        return simd_distance(simd_float3(self), simd_float3(vector))
    }
}
