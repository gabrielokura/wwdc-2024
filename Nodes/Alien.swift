//
//  Alien.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 26/07/23.
//

import SceneKit

class Alien: SCNNode, Identifiable {
    private var lifeNode: SCNNode!
    
    var type: AlienType
    var direction: MovementDirection
    let movementSpeed: Float
    
    private var path: [SCNVector3] = []
    
    private var fullHealth: Int!
    private var health: Int!
    
    var isDead = false
    var canMove = false
    
    var fitnessLevel: Double = 0
    static let inputCount: Int = 5
    static let outputCount: Int = 4
    
    let walls: Matrix<Bool>
    let target: SCNNode

    let id: Int
    
    private var checkpoints: [Int] = []
    private var sensors: [SCNNode] = []
    
    private let radius: Float = 0.3
    private var firstDistance: Double = 0
    
    var directions: [Double]
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    init?(_ type: AlienType, walls: Matrix<Bool>, target: SCNNode, id: Int, speed: Float) {
        guard let alienScene = SCNScene(named: "enemy_ufoPurple.scn") else {
            return nil
        }
        guard let alienNode = alienScene.rootNode.childNodes.first else {
            return nil
        }
    
        self.target = target
        self.walls = walls
        self.id = id
        self.type = type
        self.direction = .bottom
        self.movementSpeed = speed
        self.directions = [0, 0, 0, 0]
        
        super.init()
        
        self.geometry = alienNode.geometry
        
        let textNode = alienNode.childNode(withName: "text", recursively: false)
        
        if let textGeometry = textNode?.geometry as? SCNText {
            textGeometry.string = "\(self.id)"
        }
        
        for node in alienNode.childNodes {
            self.addChildNode(node)
        }
        
        self.sensors = setupSensorsNodes()
        
        self.setupPhysicsBody()
        self.setupLifeNode()
        
        self.fullHealth = type.health
        self.health = type.health
        
        self.position = type.initialPosition
        self.name = "alien"
        
        self.firstDistance = getDistanceFromTarget()
        self.scheduleMovement(seconds: Double(id) * 0.05)
    }
    
    private func setupSensorsNodes() -> [SCNNode]{
        let sensors = self.childNodes { (node, stop) -> Bool in
            return node.name?.contains("sensor_") ?? false
        }
        
        return sensors
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
        self.physicsBody?.contactTestBitMask = CollisionCategory.tower.rawValue | CollisionCategory.bullet.rawValue | CollisionCategory.terrain.rawValue | CollisionCategory.checkpoint.rawValue
        self.physicsBody?.collisionBitMask = CollisionCategory.bullet.rawValue | CollisionCategory.terrain.rawValue
    }
    
    private func takeDamage(_ damage: Int) {
        health = max(health - damage, 0)
        
        if health == 0 {
            die()
            return
        }
        
        lifeNode.isHidden = false
        let healthScale = Float(health)/Float(fullHealth)
        lifeNode.scale.x = healthScale
    }
    
    func hitCheckpoint(points: Double, checkpointId: Int) {
        if checkpoints.contains(where: { current in
            return current == checkpointId
        }) {
            return
        }
        
        checkpoints.append(checkpointId)
        addFitness(points)
        
    }
    
    func die() {
        self.physicsBody = nil
        self.physicsBody?.clearAllForces()
        self.opacity = 0.2
        self.isDead = true
        
        //TODO ANIMAR QUEDA DA NAVE
    }
    
    func updateDirections() {
        self.directions = getDirectionInput()
    }
    
    // Directions must have 4 values
    func move(directions: [Double]) {
        if isDead || !canMove{
            return
        }
        
        var top = directions[0];
        var right = directions[1];
        var bottom = directions[2];
        var left = directions[3];
        
        switch self.direction {
        case .top:
            bottom = 0
        case .right:
            left = 0
        case .bottom:
            top = 0
        case .left:
            right = 0
        }
        
        // Pega a direção com o maior valor
        if top > right && top > bottom && top > left {
            self.direction = .top
        } else if right > top && right > bottom && right > left {
            self.direction = .right
        } else if left > top && left > bottom && left > right {
            self.direction = .left
        } else {
            self.direction = .bottom
        }
        
        self.physicsBody?.clearAllForces()
        let direction = self.direction.directionWithMagnitude(magnitude: movementSpeed);
        self.physicsBody?.applyForce(direction, asImpulse: true)
    }
    
    private func addFitness(_ fitness: Double) {
        self.fitnessLevel += fitness
    }
    
    func scheduleMovement(seconds: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.canMove = true
        }
    }
    
    func generateInputDataForNeuralNetwork() -> [Double]{
//        let direction = getDirectionInput()
        let normalizedDistance = getDistanceFromTarget()/firstDistance
//        let angle = Double(getAngleFromTarget(target: self.target.presentation.position))
        
        var result: [Double] = []
        result.append(contentsOf: directions)
//        result.append(angle)
        result.append(normalizedDistance)
        
        return result
    }
    
    func onCollision(withBullet: Bool) {
        if withBullet {
            takeDamage(health)
            return
        }
        
        die()
    }
    
    func reset() {
        self.removeFromParentNode()
    }
    
    func highlight() {
        self.opacity = 1
        self.geometry?.firstMaterial?.diffuse.contents = UIColor.red
    }
}

//MARK:  Neural Network inputs
extension Alien {
    func getDirectionInput() -> [Double] {
        let position = self.presentation.position
        
        let up: Double = Double(getDistanceFromTopWall(x: position.x, z: position.z))
                          
        let down: Double = Double(getDistanceFromBotWall(x: position.x, z: position.z))
        
        let right: Double = Double(getDistanceFromRightWall(x: position.x, z: position.z))
        
        let left: Double = Double(getDistanceFromLeftWall(x: position.x, z: position.z))
        
        let result = [up, right, down, left]
        
        for i in 0..<result.count {
            self.sensors[i].opacity = result[i] == 0 ? 0 : 1 - result[i]
        }
        
        return result
    }
    
    func getDistanceFromRightWall(x: Float, z: Float) -> Float {
        let roundedX = Int(x.rounded())
        let roundedZ = Int(z.rounded())
        
        let hasWall = walls[(roundedX + 1).xToGameMatrix(), roundedZ.zToGameMatrix()]
        
        if hasWall {
            let right = Float(roundedX + 1)
            print("Right \(abs(right)) - \(abs(x)))\(abs(right - x) - self.radius)")
            return abs(right - x) - self.radius
        }

        return 0
    }
    
    func getDistanceFromLeftWall(x: Float, z: Float) -> Float {
        let roundedX = Int(x.rounded())
        let roundedZ = Int(z.rounded())
        
        let hasWall = walls[(roundedX - 1).xToGameMatrix(), roundedZ.zToGameMatrix()]
        
        if hasWall {
            let left = Float(roundedX - 1)
            print("Left \(abs(left)) - \(abs(x)))\(abs(left - x) - self.radius)")
            return abs(left - x) - self.radius
        }
        
        return 0
    }
    
    func getDistanceFromTopWall(x: Float, z: Float) -> Float {
        let roundedX = Int(x.rounded())
        let roundedZ = Int(z.rounded())
        
        let hasWall = walls[(roundedX).xToGameMatrix(), (roundedZ - 1).zToGameMatrix()]
        
        if hasWall {
            let top = Float(roundedZ - 1)
            print("Top \(abs(top)) - \(abs(z)))\(abs(top - z) - self.radius)")
            return abs(top - z) - self.radius
        }
        
        return 0
    }
    
    func getDistanceFromBotWall(x: Float, z: Float) -> Float {
        let roundedX = Int(x.rounded())
        let roundedZ = Int(z.rounded())
        
        let hasWall = walls[(roundedX).xToGameMatrix(), (roundedZ + 1).zToGameMatrix()]
        
        if hasWall {
            let bot = Float(roundedZ + 1)
            print("Bot \(abs(bot)) - \(abs(z)))\(abs(bot - z) - self.radius)")
            return abs(bot - z) - self.radius
        }
        
        return 0
    }
    
    func getDistanceFromTarget() -> Double {
        let alienPosition = self.presentation.position
        let targetPosition = self.target.presentation.position
        
        let distance = alienPosition.distanceModule(to: targetPosition)
        return Double(distance)
    }
    
    func getAngleFromTarget(target: SCNVector3) -> Float {
        let position = self.presentation.position
        
        if target.x > position.x {
            let tan: Float = Float(target.z-position.z)/Float(target.x-position.x)
            return -(atan(tan)+(Float.pi/2))
            
        } else  if target.x < position.x {
            let tan: Float = Float(target.z-position.z)/Float(position.x-target.x)
            return (atan(tan)+(Float.pi/2))
        }
        
        if target.z > position.z {
            return Float.pi
            
        } else {
            return 0.0
        }
    }
}

//MARK: Physics body shape size
extension Alien {
    func boxShapeWithNodeSize() -> SCNGeometry {
        let min = self.boundingBox.min
        let max = self.boundingBox.max
        let w = CGFloat(max.x - min.x)/6
        let h = CGFloat(max.y - min.y)/6
        let l = CGFloat(max.z - min.z)/6
        
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
