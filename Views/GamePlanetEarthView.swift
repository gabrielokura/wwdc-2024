//
//  SwiftUIView.swift
//
//
//  Created by Gabriel Motelevicz Okura on 23/02/24.
//

import SwiftUI

struct GamePlanetEarthView: View {
    @EnvironmentObject var manager: Manager
    @State var isTraining = false
    
    @State var interactions = 0
    
    var dialogues: [String] = [
        "Esse é o centro de treinamento dos Rubertianos. Sua missão é fazê-los aprenderem a não sair da área de terra, pois as naves não são preparadas para voarem por fora.",
        "Na mesa de controle você pode editar algumas características antes de iniciar o treinamento. Fique a vontade para testá-las.\n\n Quando estiver pronto, aperte o play.",
        "Depois de testar todos os controles, selecione voltar para o menu para ir ao seu próximo treino.",
    ]
    
    @State var currentDialogue: String = ""
    @State var dialogueIndex = 0
    @State var canShowControlPanel = false
    
    var body: some View {
        ZStack {
            GamePlanetEarthViewRepresentable()
                .ignoresSafeArea()
            
            if manager.isLoadingMap {
                ProgressView()
            }
            
            VStack {
                HStack {
                    Image("level_instructions_alien")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                    
                    dialogueCard
                }
                
                HStack {
                    if interactions > 0 {
                        Button {
                            manager.finishGame()
                            manager.backToMenuFromEarth()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Go back to menu")
                            }
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 16.0)
                                    .fill(Color("gamePurple"))
                            }
                        }
                        
                    }
                    
                    Spacer()
                }
                
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            if canShowControlPanel {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        returnCameraPositionButton
                    }
                    ControlPanel(
                        isTraining: $isTraining,
                        hasStartedGeneration: manager.hasStarted,
                        currentGeneration: manager.currentGeneration,
                        isCameraFixed: manager.isCameraFixed,
                        onPressStartGame: { (populationSize, decisionsPerSecond, alienSpeed) in
                            manager.startGame(population: populationSize, decisions: decisionsPerSecond, speed: alienSpeed)
                            
                            withAnimation {
                                interactions += 1
                            }
                        }, onPressResetGeneration: {
                            manager.resetCurrentGeneration()
                        }, onPressStopTraining: {
                            manager.finishGame()
                        }
                    )
                    .background {
                        Rectangle()
                            .foregroundStyle(.bar)
                    }
                }
            }
            
        }
        .onAppear {
            startDialogues()
        }
    }
    
    private func startDialogues() {
        dialogueIndex = 0
        currentDialogue = dialogues[dialogueIndex]
    }
    
    private func nextDialogue() {
        if dialogueIndex == (dialogues.count - 1) {
            return
        }
        
        dialogueIndex += 1
        currentDialogue = dialogues[dialogueIndex]
        withAnimation {
            canShowControlPanel = true
        }
    }
    
    private func previusDialogue() {
        if dialogueIndex == 0 {
            return
        }
        
        dialogueIndex -= 1
        currentDialogue = dialogues[dialogueIndex]
    }
    
    var returnCameraPositionButton: some View {
        Button {
            manager.returnCameraToInitialPosition()
        } label: {
            HStack {
                Group {
                    Text("center camera")
                    
                    Image(systemName: "camera.viewfinder")
                }
                .font(.system(size: 20))
                .fontWeight(.regular)
                .foregroundColor(.white)
                
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 14.0)
                    .foregroundStyle(Color("verdeFloresta"))
            }
        }
    }
    
    var dialogueCard: some View {
        VStack {
            Text(currentDialogue)
                .font(.system(size: 20))
                .fontWeight(.regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button {
                    previusDialogue()
                } label: {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 14.0)
                            .fill(dialogueIndex > 0 ? Color("gamePurple") : Color(.gray))
                    }
                }
                
                Button {
                    nextDialogue()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Next")
                    }
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 14.0)
                            .fill(dialogueIndex < 2 ? Color("gamePurple") : Color(.gray))
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 14.0)
                .foregroundStyle(Color("brancoGeleira"))
                .padding(5)
                .background {
                    RoundedRectangle(cornerRadius: 14.0)
                        .foregroundStyle(Color("azulNave"))
                }
        }
        .frame(width: 600, height: 200)
    }
}

#Preview {
    ZStack {
        GamePlanetEarthView()
    }
    .environmentObject(Manager.instance)
}
