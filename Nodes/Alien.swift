//
//  Alien.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 26/07/23.
//

import SceneKit

class Alien: SCNNode, Identifiable {
    var lifeNode: SCNNode!
    
    var type: AlienType
    var direction: MovementDirection
    
    var path: [SCNVector3] = []
    var sceneNode: SCNNode!
    var contactNode: SCNNode!
    
    var fullHealth: Int!
    var health: Int!
    
    var isDead = false
    
    var fitnessLevel: Double = 0
    static let inputCount: Int = 5
    static let outputCount: Int = 4
    
    let walls: Matrix<Bool>
    let target: SCNNode

    var moves: Int = 0
    let id: Int
    
    var checkpoints: [Int] = []
    var sensors: [SCNNode] = []
    
    let radius: Float = 0.6
    var firstDistance: Double = 0
    
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
        self.id = id
        self.type = type
        self.direction = .bottom
        
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
        
        self.sceneNode = sceneNode
        
        self.fullHealth = type.health
        self.health = type.health
        
        self.position = type.initialPosition
        self.name = "alien"
        
        self.firstDistance = getDistanceFromTarget()
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
//        self.removeFromParentNode()
        self.physicsBody = nil
        self.physicsBody?.clearAllForces()
        self.opacity = 0.2
        self.isDead = true
        addFitness((1/(getDistanceFromTarget())) * 10)
//        addFitness(1/Double(moves))
    }
    
    // Directions must have 4 values
    func move(directions: [Double]) {
        if isDead {
            return
        }
        
        let top = directions[0];
        let right = directions[1];
        let bottom = directions[2];
        let left = directions[3];
        
        let previusDirection = self.direction
        
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
        
        //TODO: Get from Game Interval
//        let interval: TimeInterval = GameSceneController.gameInterval
//        let nextPosition = self.direction.nextMove(position: self.presentation.position)
//        let movement = SCNAction.move(to: nextPosition, duration: interval)
        
//        self.runAction(movement, forKey: "movement")
        self.physicsBody?.clearAllForces()
        let direction = self.direction.directionWithMagnitude(magnitude: 1);
        self.physicsBody?.applyForce(direction, asImpulse: true)
        
        // Adding fitness
        if previusDirection.isOpposite(of: self.direction) {
            addFitness(-0.1)
        }
//        } else {
//            addFitness(0.03)
//        }
        
        moves += 1
    }
    
    private func addFitness(_ fitness: Double) {
        self.fitnessLevel += fitness
    }
    
    func generateInputDataForNeuralNetwork() -> [Double]{
        let direction = getDirectionInput()
        let normalizedDistance = getDistanceFromTarget()/firstDistance
//        let angle = Double(getAngleFromTarget(target: self.target.presentation.position))
        
        var result: [Double] = []
        result.append(contentsOf: direction)
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
        
        let result = [up*2, right*2, down*2, left*2]
        
        print("result \(result)")
        
        for i in 0..<result.count {
            self.sensors[i].opacity = result[i] == 0 ? 0 : 1 - result[i]
//            print("Opacity \(i) \(result[i]*2)")
        }
        
        return result
    }
    
    func getDistanceFromRightWall(x: Float, z: Float) -> Float {
        let roundedX = Int(x.rounded())
        let roundedZ = Int(z.rounded())
        
        let hasWall = walls[(roundedX + 1).xToGameMatrix(), roundedZ.zToGameMatrix()]
        
        if hasWall {
            let right = Float(roundedX + 1)
//            print("Right \(abs(right - x) - self.radius)")
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
//            print("Left \(abs(left - x) - self.radius)")
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
//            print("Top \(abs(top - z) - self.radius)")
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
//            print("Bot \(abs(bot - z) - self.radius)")
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
        
        /// If the snake is to the left of the food return a negative
        if target.x > position.x {
            let tan: Float = Float(target.z-position.z)/Float(target.x-position.x)
            return -(atan(tan)+(Float.pi/2))
            
            /// If the snake is to the left of the food return a positive
        } else  if target.x < position.x {
            let tan: Float = Float(target.z-position.z)/Float(position.x-target.x)
            return (atan(tan)+(Float.pi/2))
        }
        
        /// If the snake is directly below the food return pi
        if target.z > position.z {
            return Float.pi
            
        /// If the snake is drectly above the food return 0
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
