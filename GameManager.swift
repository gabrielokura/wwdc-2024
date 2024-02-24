//
//  GameManager.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 26/07/23.
//

import Foundation
import Combine
import SwiftUI

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
        "Vamos ensinar os Rubertianos a chegarem na bolinha roxa. ",
        "Eu e meus companheiros estamos procurando um novo planeta para morar e precisamos da ajuda de um especialista em Neural Network para essa missão.",
        "Por isso contratamos você para ser nosso treinador. Sua missão é ensinar os Rubertianos a explorar novos planetas através de reinforcement learning (Eles só aprendem assim :/).",
        "Selecione o primeiro planeta para que eu possa te mostrar como meus companheiros funcionam.",
        "Selecione o segundo planeta para começar o treinamento dos rubertianos."
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
        
        currentDialogue = dialogues.first!
    }
    
    private func checkGameEvents() {
        if currentDialogueIndex == 3 {
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
        self.currentDialogueIndex += 1
        self.currentDialogue = dialogues[self.currentDialogueIndex]
        
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
        
        self.gameScene = .menu
    }
}
