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
    var lifeNode: SCNNode!
    var textNode: SCNNode!
    
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
    
    let speedNormalizer: Float = 0.8
    
    let walls: Matrix<Bool>
    let target: SCNNode
    
    var firstPosition: SCNVector3
    var moves: Int = 0
    let id: Int
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    init?(_ type: AlienType, in sceneNode: SCNNode!, walls: Matrix<Bool>, target: SCNNode, id: Int) {
        guard let alienScene = SCNScene(named: "enemy_ufoPurple.scn") else {
            return nil
        }
        guard let alienNode = alienScene.rootNode.childNodes.first else {
            return nil
        }
    
        self.target = target
        self.walls = walls
        self.firstPosition = alienNode.worldPosition
        self.id = id
        
        super.init()
        
        self.geometry = alienNode.geometry
        
        for node in alienNode.childNodes {
            self.addChildNode(node)
        }
        
        self.setupPhysicsBody()
        self.setupLifeNode()
        self.setupTextNode()
        
        self.type = type
        
        self.sceneNode = sceneNode
        
        self.fullHealth = type.health
        self.health = type.health
        
        self.position = type.initialPosition
        self.name = "alien"
    }
    
    private func setupTextNode() {
        self.textNode = self.childNode(withName: "text", recursively: false)!
        
        if let textGeometry = textNode.geometry as? SCNText {
            textGeometry.string = "ID: \(id)"
        }
    }
    
    private func setupLifeNode() {
        self.lifeNode = self.childNode(withName: "life", recursively: false)!
        self.lifeNode.pivot = SCNMatrix4MakeTranslation(-0.5, 0, 0)
        self.lifeNode.position = SCNVector3(-0.5, 0, 0)
        self.lifeNode.isHidden = true
    }
    
    private func setupPhysicsBody() {
        self.scale = SCNVector3(0.25, 0.25, 0.25)
        
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

            updateFitnessLevelWith(getTravelDistance())
            
            self.isDead = true
//            self.opacity = 0.05
//            self.physicsBody?.clearAllForces()
        }
        
        lifeNode.isHidden = false
        let healthScale = Float(health)/Float(fullHealth)
        lifeNode.scale.x = healthScale
    }
    
    func move(x: Double, z: Double, breakValue: Double) {
        let horizontalDirection = x > 0.5 ? 0.5 : -0.5
        let verticalDirection = z > 0.5 ? 0.5 : -0.5
        let willBreak = breakValue > 0.95
        
        let newVector = SCNVector3(x: Float(horizontalDirection)/speedNormalizer, y: 0, z: Float(verticalDirection)/speedNormalizer)
        
        if (willBreak) {
            self.physicsBody?.clearAllForces()
            return
        }
        
        self.physicsBody?.applyForce(newVector, asImpulse: false)
        updateFitnessLevelWith(0.01)
    }
    
    private func updateFitnessLevelWith(_ fitness: Double) {
        self.fitnessLevel += fitness
    }
    
    func generateInputDataForNeuralNetwork() -> [Double]{
        let direction = getDirectionInput()
        let distanceFromTarget = getDistanceFromTarget()
        let velocity = getCurrentVelocityXAndZ()
        
        var result: [Double] = []
        result.append(contentsOf: direction)
        result.append(distanceFromTarget)
//        result.append(contentsOf: velocity)
        
        print("Result \(result)")
        
        return result
    }
    
    func onCollision(withBullet: Bool) {
        takeDamage(health)
    }
    
    func reset() {
        if isDead {
            return
        }
        
        self.removeFromParentNode()
        self.isDead = true
//
//        let position = self.presentation.worldPosition;
//        let distance = position.distanceModule(to: firstPosition)
    }
}

//MARK:  Neural Network inputs
extension Alien {
    func getDirectionInput() -> [Double] {
        let xBaseSum = 5
        let zBaseSum = 11
        
        let xAlien = Int(self.presentation.position.x)
        let zAlien = Int(self.presentation.position.z)
        
        let distanceX = abs(Double(self.presentation.position.x.truncatingRemainder(dividingBy: 1)))
        let distanceZ = abs(Double(self.presentation.position.z.truncatingRemainder(dividingBy: 1)))
        
        let up = (walls[xAlien + xBaseSum, zAlien + zBaseSum - 1])
        let down = (walls[xAlien + xBaseSum, zAlien + zBaseSum + 1])
        let right = (walls[xAlien + xBaseSum + 1, zAlien + zBaseSum])
        let left = (walls[xAlien + xBaseSum - 1, zAlien + zBaseSum])
        
        print("Up \(up) down \(down) right \(right) left \(left)")
        
        return [up ?  distanceZ : 0, down ? (1 - distanceZ) : 0, right ? distanceX : 0, left ? (1 - distanceX) : 0]
    }
    
    func getDistanceFromTarget() -> Double {
        let alienPosition = self.presentation.position
        let targetPosition = self.target.presentation.position
        
        let distance = alienPosition.distanceModule(to: targetPosition)
        return Double(distance)
    }
    
    func getTravelDistance() -> Double {
        let alienPosition = self.presentation.position
        
        let distance = alienPosition.distanceModule(to: firstPosition)
        return Double(distance)
    }
    
    func getCurrentVelocityXAndZ() -> [Double] {
        let position = self.presentation.position
        
        return [Double(position.x), Double(position.z)]
    }
}

extension Alien {
    func boxShapeWithNodeSize() -> SCNGeometry {
        let min = self.boundingBox.min
        let max = self.boundingBox.max
        let w = CGFloat(max.x - min.x)/4
        let h = CGFloat(max.y - min.y)/4
        let l = CGFloat(max.z - min.z)/4
        
        return SCNBox (width: w , height: h , length: l, chamferRadius: 0.0)
    }
}

extension SCNVector3 {
    func distance(to vector: SCNVector3) -> SCNVector3 {
        let result = SCNVector3(self.x - vector.x, self.y - vector.y, self.z - vector.z)
        return result
    }
    
    func distanceModule(to vector: SCNVector3) -> Float {
        let x = pow(self.x - vector.x, 2)
        let y = pow((self.z - vector.z), 2)
        
        let distance = sqrt(x + y)
        return distance
    }
}
