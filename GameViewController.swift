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
import Neat

struct GameLevelViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return GameSceneController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}


class GameSceneController: UIViewController {
    static let gameInterval: TimeInterval = 0.25
    let population = 100
    static let xBaseSum = 5
    static let zBaseSum = 11
    
    var sceneView: SCNView!
    
    private var initialCameraPosition: SCNVector3!
    private var initialCameraRotation: SCNVector4!
    
    var cameraNode: SCNNode!
    var scene: SCNScene!
    
    var manager: Manager = Manager.instance
    var cancellableBag = Set<AnyCancellable>()
    
    var terrain: Terrain!
    
    var isPlaying = false
    
    var aliens: [Alien] = []
    var deadAliensCount = 0
    
    var network: Neat!
    var king: NGenome? = nil
    
    var map:Matrix<Bool> = Matrix(rows: 14, columns: 13, defaultValue:false)
    
    let queue = DispatchQueue(label: "com.okura.smartAliens",attributes: .concurrent)
    
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
        self.sceneView.rendersContinuously = true
        self.sceneView.preferredFramesPerSecond = 60
        
        self.setupGame()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.sceneView.addGestureRecognizer(tapGesture)
        self.scene.physicsWorld.contactDelegate = self
        self.sceneView.delegate = self
    }
    
    private func setupGame() {
        self.setupCamera()
        self.setupBackground()
        self.subscribeToFixedCameraEvents()
        self.subscribeToActions()
        self.setupTerrain()
        _ = self.setupCheckpoints()
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
                self.setupAliensPopulation()
            case .resetGeneration:
                self.killAllAliens()
            }
        }.store(in: &cancellableBag)
    }
    
    func returnCameraToInitialPosition() {
        cameraNode.position = initialCameraPosition
        cameraNode.rotation = initialCameraRotation
        self.sceneView.pointOfView = cameraNode
    }
    
    func killAllAliens() {
        self.isPlaying = false
        
        queue.async(qos: .userInteractive, flags: .barrier) {
            self.network.nextGenomeStepTwo()
            
            // Do NEAT here.
            self.network.epoch()
            
            self.king = self.network.getKing()
            
            let id = self.king?.id ?? 0
            
            print("King id \(id)")
            print("King fitnes \(self.king?.fitness ?? -1)")
            
//            if id > 0 {
//                self.aliens[id-1].highlight()
//            }
//            
            DispatchQueue.main.async {
                for alien in self.aliens {
                    alien.reset()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.setupAliensPopulation()
                }
            }
        }
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

//MARK: Setup functions
extension GameSceneController {
    func setupCheckpoints() -> [Checkpoint] {
        let positions = Checkpoint.positions
        var checkpoints: [Checkpoint] = []
        
        for i in 1...positions.count {
            let position = positions[i-1]
            let newCheckpoint = Checkpoint(id: i, position: position)
            checkpoints.append(newCheckpoint)
            self.scene.rootNode.addChildNode(newCheckpoint)
        }
        
        return checkpoints
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
    
    func setupAliensPopulation() {
        guard let trophy = self.scene.rootNode.childNode(withName: "trophy", recursively: false) else {
            print("Cannot find trophy")
            return
        }
        
        aliens = []
        deadAliensCount = 0
        for i in 1...population{
            let alien = Alien(.purple, in: self.scene.rootNode, walls: self.map, target: trophy, id: i)!
            sceneView.scene?.rootNode.addChildNode(alien)
            aliens.append(alien)
        }
        
        self.network = Neat(inputs: Alien.inputCount, outputs: Alien.outputCount, population: aliens.count, confFile: nil, multithread: false)
        
        print("Population \(aliens.count)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isPlaying = true
            self.gameLoop()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.killAllAliens()
        }
    }
    
    func setupTerrain() {
        terrain = Terrain(in: self.scene.rootNode)
        
        // Creating wall matrix
        _ = terrain.walls.map { wall in
            let x = Int(wall.position.x).xToGameMatrix()
            let z = Int(wall.position.z).zToGameMatrix()
            
            self.map[x,z] = true
        }
        
        // Creating path matrix
        print(map[5.xToGameMatrix(), (-11).zToGameMatrix()])
        print(map[5.xToGameMatrix(), (-5).zToGameMatrix()])
        
        self.manager.finishLoadingMap()
    }
}

//MARK: Physics delegate
extension GameSceneController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        let alien = contact.nodeA is Alien ? contact.nodeA as! Alien : contact.nodeB as! Alien
        
        if contact.nodeA is Bullet || contact.nodeB is Bullet {
            let bullet = contact.nodeA is Bullet ? contact.nodeA as! Bullet : contact.nodeB as! Bullet
            bullet.removeFromParentNode()
            alien.onCollision(withBullet: true)
            return
        }
        
        if contact.nodeA is Tower || contact.nodeB is Tower {
            let tower = contact.nodeA is Tower ? contact.nodeA as! Tower : contact.nodeB as! Tower
            tower.lockCannon(on: alien)
            return
        }
        
        if contact.nodeA is Checkpoint || contact.nodeB is Checkpoint {
            let checkpoint = contact.nodeA is Checkpoint ? contact.nodeA as! Checkpoint : contact.nodeB as! Checkpoint
            let points = Double(checkpoint.id * 10)
            alien.hitCheckpoint(points: points, checkpointId: checkpoint.id)
            return
        }
        
        
        alien.onCollision(withBullet: false)
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
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

//MARK: Game Loop
extension GameSceneController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {}
    
    func gameLoop() {
        if !isPlaying {
            return
        }
        
        if self.network == nil {
            print("Neural network nil")
            return
        }
        
        queue.async(qos: .userInteractive ,flags: .barrier) {
            for alien in self.aliens {
                if alien.isDead {
                    self.network.nextGenomeStepOne(alien.fitnessLevel)
                    continue
                }
                
                let inputData: [Double] = alien.generateInputDataForNeuralNetwork()
                
                let output = self.network.run(inputs: inputData, inputCount: Alien.inputCount, outputCount: Alien.outputCount)

                alien.move(directions: output)
                
                self.network.nextGenomeStepOne(alien.fitnessLevel)
            }
        }
        
        // Set a timer for the next game loop
        _ = Timer.scheduledTimer(withTimeInterval: GameSceneController.gameInterval, repeats: false, block: { timer in
            self.gameLoop()
        })
    }
}
