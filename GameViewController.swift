//
//  GameViewController.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 25/07/23.
//

import UIKit
import SceneKit
import Combine
import SwiftUI

struct GameLevelViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return GameSceneController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}


class GameSceneController: UIViewController {
    var sceneView: SCNView!
    
    private var initialCameraPosition: SCNVector3!
    private var initialCameraRotation: SCNVector4!
    
    var cameraNode: SCNNode!
    var scene: SCNScene!
    
    var manager: Manager = Manager.instance
    var cancellableBag = Set<AnyCancellable>()
    
    var neuralNetworkManager: NeuralNetworkManager?
    
    var terrain: Terrain!
    
    var isPlaying = false
    
    override func loadView() {
        super.loadView()
        
        let view = SCNView()
        self.view = view
        
        self.sceneView = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let scene = SCNScene(named: "GameLevel.scn") else {
            print("Não achou GameLevel.scn")
            return
        }
        
        self.sceneView.scene = scene
        self.scene = scene
        
        self.sceneView.showsStatistics = true
        self.sceneView.debugOptions = [.showConstraints, .showSkeletons, .showPhysicsShapes]
        
        self.setupCamera()
        self.setupBackground()
        self.subscribeToFixedCameraEvents()
        self.subscribeToActions()
        self.setupTerrain()
        self.setupAliensPopulation()
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.sceneView.addGestureRecognizer(tapGesture)
        self.scene.physicsWorld.contactDelegate = self
        self.sceneView.delegate = self
    }
    
    private func subscribeToFixedCameraEvents() {
        manager.$isCameraFixed.sink { value in
            self.sceneView.allowsCameraControl = !value
        }.store(in: &cancellableBag)
    }
    
    private func subscribeToActions() {
        manager.actionStream.sink { action in
            switch action {
            case .returnCamera:
                self.returnCameraToInitialPosition()
            case .startEditing:
                self.terrain.startEditing()
            case .finishEditing:
                self.terrain.finishEditing()
            case .start:
                self.isPlaying = true
            }
        }.store(in: &cancellableBag)
    }
    
    private func setupCamera() {
        cameraNode = self.scene.rootNode.childNode(withName: "camera", recursively: false)
        
        initialCameraPosition = cameraNode!.position
        initialCameraRotation = cameraNode!.rotation
    }
    
    private func setupBackground() {
        let skyboxImages = [UIImage(named: "space_rt"),
                            UIImage(named: "space_lf"),
                            UIImage(named: "space_up"),
                            UIImage(named: "space_dn"),
                            UIImage(named: "space_ft"),
                            UIImage(named: "space_bk")]
        
        self.scene.background.contents = skyboxImages
    }
    
    func returnCameraToInitialPosition() {
        cameraNode.position = initialCameraPosition
        cameraNode.rotation = initialCameraRotation
        self.sceneView.pointOfView = cameraNode
    }
    
    func setupTerrain() {
        terrain = Terrain(in: self.scene.rootNode)
    }
    
    func setupAliensPopulation() {
        let alien = Alien(.purple, in: self.scene.rootNode, walls: terrain.walls)!
        sceneView.scene?.rootNode.addChildNode(alien)
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { // remove/replace ship after half a second to visualize collision
//            self.setupAliens()
//        })
        
        self.neuralNetworkManager = NeuralNetworkManager(population: 1)
        self.neuralNetworkManager?.setupAliens([alien])
    }
    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // check what nodes are tapped
        let p = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: SCNHitTestResult = hitResults[0]
            let name = result.node.parent?.name
            
            if (name != nil && name!.contains("editable")) {
                terrain.tapOnTerrain(node: result.node)
                return
            }
        }
    }
}

extension GameSceneController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        let alien = contact.nodeA is Alien ? contact.nodeA as! Alien : contact.nodeB as! Alien
        
        if contact.nodeA is Bullet || contact.nodeB is Bullet {
            let bullet = contact.nodeA is Bullet ? contact.nodeA as! Bullet : contact.nodeB as! Bullet
            bullet.removeFromParentNode()
            alien.onCollision(withBullet: true, contactPoint: contact.contactPoint)
            return
        }
        
        if contact.nodeA is Tower || contact.nodeB is Tower {
            let tower = contact.nodeA is Tower ? contact.nodeA as! Tower : contact.nodeB as! Tower
            tower.lockCannon(on: alien)
            return
        }
        
        alien.onCollision(withBullet: false, contactPoint: contact.contactPoint)
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        let alien = contact.nodeA is Alien ? contact.nodeA as! Alien : contact.nodeB as! Alien
        
        if contact.nodeA is Tower || contact.nodeB is Tower {
            let tower = contact.nodeA is Tower ? contact.nodeA as! Tower : contact.nodeB as! Tower
            tower.unlockCannon()
            return
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        if contact.nodeA is Tower || contact.nodeB is Tower {
            let tower = contact.nodeA is Tower ? contact.nodeA as! Tower : contact.nodeB as! Tower
            tower.aimCannon()
            tower.startFire()
        }
    }
}

extension GameSceneController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if !isPlaying {
            return
        }
        
        if self.neuralNetworkManager == nil {
            print("Neural network nil")
            return
        }
        
        self.neuralNetworkManager?.train()
    }
}
