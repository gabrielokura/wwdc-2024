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
        
        for node in alienNode.childNodes {
            self.addChildNode(node)
        }
        
        self.setupPhysicsBody()
        self.setupLifeNode()
        
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
            addFitness(-1)
            self.isDead = true
        }
        
        lifeNode.isHidden = false
        let healthScale = Float(health)/Float(fullHealth)
        lifeNode.scale.x = healthScale
    }
    
    // Directions must have 4 values
    func move(directions: [Double]) {
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
        let interval: TimeInterval = GameSceneController.gameInterval
        let nextPosition = self.direction.nextMove(position: self.presentation.position)
        let movement = SCNAction.move(to: nextPosition, duration: interval)
        
        self.runAction(movement)
        
        // Adding fitness
        if previusDirection.isOpposite(of: self.direction) {
            addFitness(-0.03)
        } else {
            addFitness(0.01)
        }
    }
    
    private func addFitness(_ fitness: Double) {
        self.fitnessLevel += fitness
    }
    
    func generateInputDataForNeuralNetwork() -> [Double]{
        let direction = getDirectionInput()
        
        //TODO: Change to angle to target
        let distanceFromTarget = getDistanceFromTarget()
        
        var result: [Double] = []
        result.append(contentsOf: direction)
        result.append(distanceFromTarget)
        
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
        
    }
}

//MARK:  Neural Network inputs
extension Alien {
    func getDirectionInput() -> [Double] {
        let xBaseSum = 5
        let zBaseSum = 11
        
        let xAlien = Int(self.presentation.position.x)
        let zAlien = Int(self.presentation.position.z)
        
        let up: Double = (walls[xAlien + xBaseSum, zAlien + zBaseSum - 1]) ? 1 : 0
        let down: Double = (walls[xAlien + xBaseSum, zAlien + zBaseSum + 1]) ? 1 : 0
        let right: Double = (walls[xAlien + xBaseSum + 1, zAlien + zBaseSum]) ? 1 : 0
        let left: Double = (walls[xAlien + xBaseSum - 1, zAlien + zBaseSum]) ? 1 : 0
        
        return [up, right, down, left]
    }
    
    func getDistanceFromTarget() -> Double {
        let alienPosition = self.presentation.position
        let targetPosition = self.target.presentation.position
        
        let distance = alienPosition.distanceModule(to: targetPosition)
        return Double(distance)
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
        let x = pow(self.x - vector.x, 2)
        let y = pow((self.z - vector.z), 2)
        
        let distance = sqrt(x + y)
        return distance
    }
}
