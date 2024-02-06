//
//  Cannon.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 29/07/23.
//

import SceneKit

class Cannon: SCNNode {
    var fireSpot: SCNNode!
    var weaponCannon: SCNNode!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override init() {
        super.init()
        
        guard let scene = SCNScene(named: "weapon_cannon.scn") else {
            print("Não achou weapon_cannon.scn")
            return
        }
        guard let newNode = scene.rootNode.childNodes.first else {
            print("Root node não tem children")
            return
        }

        self.geometry = newNode.geometry
        
        for node in newNode.childNodes {
            self.addChildNode(node)
        }
        
        guard let fireSpot = self.childNode(withName: "fire_spot", recursively: false) else {
            print("Não achou fire_spot")
            return
        }
        
        guard let weapon = self.childNode(withName: "weapon_cannon", recursively: false) else {
            print("Não achou weapon_cannon")
            return
        }
        
        self.weaponCannon = weapon
        self.fireSpot = fireSpot
    }
    
    func fire() {
        print("cannon firing")
        let bulletsNode = Bullet()
        
        let (direction, position) = getCannonVector()
        bulletsNode.position = position
        
        let force: Float = 10
        
        let bulletDirection = SCNVector3(x: direction.x * force, y: direction.y * force, z: direction.z * force)
        bulletsNode.physicsBody?.applyForce(bulletDirection, asImpulse: true)
        self.fireSpot.addChildNode(bulletsNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { // remove/replace ship after half a second to visualize collision
            self.removeNodeWithAnimation(bulletsNode, explosion: false)
        })
    }
    
    func lockAim(in node: SCNNode) {
        self.look(at: node.position)
        self.rotation.z = 0
        self.rotation.x = 0
        
        self.fireSpot.look(at: node.position)
        self.weaponCannon.look(at: node.position)
    }
    
    private func removeNodeWithAnimation(_ node: SCNNode, explosion: Bool) {
        // remove node
        node.physicsBody = nil
        node.removeFromParentNode()
        
        print("removing bullet")
    }
    
    private func getCannonVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        let dir = SCNVector3(fireSpot.worldFront.x, fireSpot.worldFront.y, fireSpot.worldFront.z) // orientation of cannon in world space
        let pos = SCNVector3(0,0,0)
        
        return (dir, pos)
    }
}
