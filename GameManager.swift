//
//  GameManager.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 26/07/23.
//

import Foundation
import Combine

enum GameActions {
    case start(Int), returnCamera, startEditing, finishEditing, resetGeneration
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
        isCameraFixed = true
        actionStream.send(.returnCamera)
    }
    
    func editTerrain() {
        isEditingTerrain.toggle()
        actionStream.send(isEditingTerrain ? .startEditing : .finishEditing)
    }
    
    func startGame() {
        hasStarted = true
        actionStream.send(.start(50))
    }
    
    func finishGame() {
        DispatchQueue.main.async {
            self.hasStarted = false
        }
    }
    
    func resetCurrentGeneration() {
        actionStream.send(.resetGeneration)
        hasStarted = false
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
