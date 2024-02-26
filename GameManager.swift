//
//  GameManager.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 26/07/23.
//

import Foundation
import Combine
import SwiftUI
import Neat

enum GameActions {
    case start(Int, Int, Float), returnCamera, finishGame, resetGeneration
}

enum GameScene {
    case menu, planetEarth, planetIce, planetMix
}

class Manager: ObservableObject {
    static var instance = Manager()
    
    @Published var gameScene: GameScene = .menu
    
    @Published var isCameraFixed: Bool = false
    @Published var hasStarted: Bool = false
    @Published var isLoadingMap: Bool = true
    
    @Published var currentGeneration: Int = 0
    
    @Published var hasStartedGame = false
    
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
    
    
    //MARK: Menu functions and variables
    
    var dialogues: [String] = [
        "Hi. My name is Leo. My friends and I are looking for a new planet to live on and I need a coach to help us. \n\nPrecisely, a coach focused on neural network.",
        "That's why we've hired you.\n\nYour mission is to teach us how to explore new planets through reinforcement learning.",
        "Select the first planet so I can show you how my companions work.",
    ]
    
    var iceDialogues: [String] = [
        "Cool, right?\n\n Now select the second planet to start the real training."
    ]
    
    @Published var currentDialogue: String = ""
    @Published var currentDialogueIndex: Int = 0
    @Published var showBackButton: Bool = false
    @Published var showNextButton: Bool = true
    
    @Published var isFirstPlanetFilled = false
    @Published var isFirstPlanetHidden = true
    
    @Published var isSecondPlanetFilled = false
    @Published var isSecondPlanetHidden = true
    
    @Published var isThirdPlanetFilled = false
    @Published var isThirdPlanetHidden = true
    
    var hasFinishedEarth = false
    var hasFinishedIce = false
    var hasFinishedMix = false
    
    var king: NGenome? = nil
    @Published var checkpointsCounter: Int = 0
    
    var canShowNextDialogue: Bool {
        get {
            if !hasFinishedEarth && currentDialogueIndex == 3 {
                return false
            }
            
            if !hasFinishedIce && currentDialogueIndex == 4 {
                return false
            }
            
            return true
        }
    }
    
    func onPressNext() {
        if !showNextButton {
            return
        }
        
        if currentDialogueIndex >= (dialogues.count - 1) {
            return
        }
        
        if !canShowNextDialogue {
            return
        }
        
        currentDialogueIndex += 1
        currentDialogue = dialogues[currentDialogueIndex]
        showBackButton = true
        
        if currentDialogueIndex == (dialogues.count - 1) {
            showNextButton = false
        }
        
        checkGameEvents()
    }
    
    func onPressBack() {
        if !showBackButton {
            return
        }
        
        if currentDialogueIndex == 0 {
            return
        }
        
        currentDialogueIndex -= 1
        currentDialogue = dialogues[currentDialogueIndex]
        
        showNextButton = true
        if currentDialogueIndex == 0 {
            showBackButton = false
        }
    }
    
    func startDialogues() {
        if currentDialogueIndex != 0 {
            return
        }
        
        if hasFinishedIce && hasFinishedMix && hasFinishedEarth {
            self.currentDialogue = "It's been a good journey, huh?  I'll take it from here. \n\n Thanks for playing Smart Aliens. \n\nYou can explore all the planets, if you want."
        } else {
            currentDialogue = dialogues.first!
        }
        
    }
    
    private func checkGameEvents() {
        if currentDialogueIndex == 2 {
            // Evento: mostrar primeiro mapa selecionável
            withAnimation {
                isFirstPlanetFilled = true
                isFirstPlanetHidden = false
            }
        }
    }
    
    
}

// MARK: Planet Earth FUNCTIONS

extension Manager {
    func onPressFirstPlanet() {
        if isFirstPlanetHidden {
            return
        }
        
        gameScene = .planetEarth
    }
    
    func backToMenuFromEarth() {
        self.isFirstPlanetFilled = false
        self.isSecondPlanetHidden = false
        self.isSecondPlanetFilled = true
        
        self.hasFinishedEarth = true
        self.dialogues = iceDialogues
        self.currentDialogueIndex = 0
        self.currentDialogue = iceDialogues.first!
        self.currentGeneration = 0
        
        showBackButton = false
        showNextButton = false
        
        self.gameScene = .menu
    }
}

// MARK: Planet Ice FUNCTIONS

extension Manager {
    func onPressSecondPlanet() {
        if isSecondPlanetHidden {
            return
        }
        
        gameScene = .planetIce
    }
    
    func backToMenuFromIce() {
        self.isFirstPlanetFilled = false
        self.isSecondPlanetHidden = false
        self.isSecondPlanetFilled = true
        
        self.currentGeneration = 0
        
        self.gameScene = .planetMix
    }
    
    func setKing(newKing: NGenome, checkpointsCounter: Int) {
        let kingFitness = self.king?.fitness ?? 0
        
        if newKing.fitness > kingFitness {
            self.king = newKing
            self.checkpointsCounter = checkpointsCounter
            
            print("New king with \(checkpointsCounter)")
        }
       
    }
}


// MARK: Planet Mix FUNCTIONS

extension Manager {
    func onPressThirdPlanet() {
        if isThirdPlanetHidden {
            return
        }
        
        gameScene = .planetMix
    }
    
    func backToMenuFromMix() {
        self.isSecondPlanetFilled = false
        self.isThirdPlanetHidden = false
        
        self.hasFinishedEarth = true
        self.hasFinishedIce = true
        self.hasFinishedMix = true
        
        self.dialogues = []
        self.currentDialogueIndex = 0
        self.currentDialogue = "Thanks for playing Smart Aliens"
        self.currentGeneration = 0
        
        showBackButton = false
        showNextButton = false
        
        self.gameScene = .menu
    }
}
