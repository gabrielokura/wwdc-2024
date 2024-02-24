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

struct GamePlanetMixViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return GamePlanetMixController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}


class GamePlanetMixController: UIViewController {
    static let gameInterval: TimeInterval = 0.25
    var alienSpeed: Float = 1.0
    var decisionsPerSecond: Int = 4
    static let xBaseSum = 6
    static let zBaseSum = 11
    static let timeBetweenCheckpoints: TimeInterval = 4
    
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
    var deadAliens: [Alien] = []
    var reachedCheckpoints: [Checkpoint] = []
    var population: Int = 0
    
    var network: NNetwork!
    var king: NGenome? = nil
    
    var map:Matrix<Bool> = Matrix(rows: 20, columns: 20, defaultValue:false)
    
    let queue = DispatchQueue(label: "com.okura.smartAliens",attributes: .concurrent)
    var gameLoopTimer: Timer?
    
    override func loadView() {
        super.loadView()
        
        let view = SCNView()
        self.view = view
        
        self.sceneView = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let scene = SCNScene(named: "PlanetMixLevel.scn") else {
            print("Não achou PlanetMixLevel.scn")
            return
        }
        
        self.sceneView.scene = scene
        self.scene = scene
        
        self.sceneView.showsStatistics = true
//        self.sceneView.debugOptions = [.showConstraints, .showSkeletons, .showPhysicsShapes]
        self.sceneView.rendersContinuously = true
        self.sceneView.preferredFramesPerSecond = 60
        
        self.setupGame()
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
            case .finishGame:
                self.finishGenerationTraining(startNewGame: false)
            case .returnCamera:
                self.returnCameraToInitialPosition()
            case .start(let population, let decisions, let speed):
                self.setupAliensPopulation(aliensPopulation: population, speed: speed, decisionsPerSecond: decisions)
            case .resetGeneration:
                self.finishGenerationTraining(startNewGame: true)
            }
        }.store(in: &cancellableBag)
    }
    
    func returnCameraToInitialPosition() {
        cameraNode.position = initialCameraPosition
        cameraNode.rotation = initialCameraRotation
        self.sceneView.pointOfView = cameraNode
    }
    
    func finishGenerationTraining(startNewGame: Bool) {
        self.isPlaying = false
        gameLoopTimer?.invalidate()
        gameLoopTimer = nil
    }
    
    func alienDied(_ alien: Alien) {
        if deadAliens.contains(alien) {
            return
        }
        
        deadAliens.append(alien)
        
        if deadAliens.count == aliens.count {
            print("Everybody is dead! Restart population")
            deadAliens = []
            resetCheckpoints()
            finishGenerationTraining(startNewGame: true)
        }
    }
    
    func resetCheckpoints() {
        for checkpoint in reachedCheckpoints {
            checkpoint.opacity = 1.0
        }
        reachedCheckpoints = []
    }
    
    func alienReachCheckpoint(_ checkpoint: Checkpoint) {
        if reachedCheckpoints.contains(checkpoint) {
            return
        }
        
        self.reachedCheckpoints.append(checkpoint)
        checkpoint.opacity = 0.3
    }
}

//MARK: Setup functions
extension GamePlanetMixController {
    func setupCheckpoints() -> [Checkpoint] {
        let positions = Checkpoint.mixCheckpoints
        var checkpoints: [Checkpoint] = []
        
        for i in 1...positions.count {
            let position = positions[i-1]
            let newCheckpoint = Checkpoint(id: i, position: position, points: Double(10))
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
    
    func setupAliensPopulation(aliensPopulation: Int, speed: Float, decisionsPerSecond: Int) {
        guard let trophy = self.scene.rootNode.childNode(withName: "trophy", recursively: false) else {
            print("Cannot find trophy")
            return
        }
        
        let moveAction = SCNAction.rotate(by: 0.4, around: cameraNode.position, duration: 1)
        trophy.runAction(SCNAction.repeatForever(moveAction))
        
        aliens = []
        deadAliens = []
        self.population = aliensPopulation
        self.alienSpeed = speed
        self.decisionsPerSecond = decisionsPerSecond
        manager.newGeneration()
        resetCheckpoints()
        
        SCNTransaction.begin()
        for i in 1...population{
            let alien = Alien(.mix, walls: self.map, target: trophy, id: i, speed: speed)!
            sceneView.scene?.rootNode.addChildNode(alien)
            aliens.append(alien)
        }
        SCNTransaction.commit()
        
        self.network = NNetwork(genome: self.manager.king!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isPlaying = true
            self.gameLoop()
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
        
        self.manager.finishLoadingMap()
    }
}

//MARK: Physics delegate
extension GamePlanetMixController: SCNPhysicsContactDelegate {
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
            let points = Double(checkpoint.points)
            alien.hitCheckpoint(points: points, checkpointId: checkpoint.id)
            alienReachCheckpoint(checkpoint)
            return
        }
        
        
        alien.onCollision(withBullet: false)
        alienDied(alien)
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
extension GamePlanetMixController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    }
    
    private func gameInterval() -> TimeInterval {
        let interval = 1.0/Double(self.decisionsPerSecond)
        return interval
    }
    
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
                let inputData: [Double] = alien.generateInputDataForNeuralNetwork()
                let output = self.network.run(inputsIn: inputData, networkType: .SnapShot)
                alien.move(directions: output)
            }
        }
        
        // Set a timer for the next game loop
        gameLoopTimer = Timer.scheduledTimer(withTimeInterval: gameInterval(), repeats: false) { timer in
            self.gameLoop()
        }
    }
}
