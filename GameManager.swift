//
//  GameManager.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 26/07/23.
//

import Foundation
import Combine

enum GameActions {
    case start(Int, Int, Float), returnCamera, finishGame, resetGeneration
}

class Manager: ObservableObject {
    static var instance = Manager()
    
    @Published var isCameraFixed: Bool = false
    @Published var isEditingTerrain: Bool = false
    @Published var hasStarted: Bool = false
    @Published var isLoadingMap: Bool = true
    
    @Published var currentGeneration: Int = 0
    
    var actionStream = PassthroughSubject<GameActions, Never>()
    
    func returnCameraToInitialPosition() {
        actionStream.send(.returnCamera)
    }
    
    func startGame(population: Int, decisions: Int, speed: Float) {
        hasStarted = true
        actionStream.send(.start(population, decisions, speed))
    }
    
    func finishGame() {
        DispatchQueue.main.async {
            self.hasStarted = false
            self.currentGeneration = 0
        }
        
        actionStream.send(.finishGame)
    }
    
    func resetCurrentGeneration() {
        actionStream.send(.resetGeneration)
    }
    
    func finishLoadingMap() {
        DispatchQueue.main.async {
            self.isLoadingMap = false
        }
    }
    
    func newGeneration() {
        DispatchQueue.main.async {
            self.currentGeneration += 1
        }
    }
    
}
