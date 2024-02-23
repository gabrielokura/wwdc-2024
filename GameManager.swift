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
    
    
    //MARK: Menu functions and variables
    
    var dialogues: [String] = [
        "Olá terráqueo, meu nome é Rubert. Sou um Rubertiano do planeta Ruberten.",
        "Eu e meus companheiros estamos procurando um novo planeta para morar e precisamos da ajuda de um especialista em Neural Network para essa missão.",
        "Por isso contratamos você para ser nosso treinador. Sua missão é ensinar os Rubertianos a explorar novos planetas através de reinforcement learning (Eles só aprendem assim :/).",
        "Selecione o primeiro planeta para que eu possa te mostrar como meus companheiros funcionam."
    ]
    
    @Published var currentDialogue: String = ""
    @Published var currentDialogueIndex: Int = 0
    @Published var showBackButton: Bool = false
    @Published var showNextButton: Bool = true
    
    @Published var isFirstPlanetFilled = false
    @Published var isFirstPlanetHidden = true
    
    @Published var isSecondPlanetHidden = true
    
    @Published var isThirdPlanetHidden = true
    
    func onPressNext() {
        if currentDialogueIndex >= (dialogues.count - 1) {
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
    
    func onPressFirstPlanet() {
        if isFirstPlanetHidden {
            return
        }
        
        gameScene = .planetEarth
    }
}
