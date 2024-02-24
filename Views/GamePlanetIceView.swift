//
//  SwiftUIView.swift
//  
//
//  Created by Gabriel Motelevicz Okura on 24/02/24.
//

import SwiftUI

struct GamePlanetIceView: View {
    @EnvironmentObject var manager: Manager
    @State var isTraining = false
    
    @State var interactions = 0
    
    var dialogues: [String] = [
        "Agora vamos ensinar os Rubertianos a chegarem no objetivo final, a bolinha roxa.",
        "Perceba que o comportamento da primeira geração é completamente aleatório. A neural network é responsável por aprimorar seus movimentos a cada nova geração.",
        "Ou seja, vamos utilizar o DNA do Rubertiano que mais coletar bolas amarelas para aprimorar as próximas gerações. Beleza?",
        "Aperte play para começar o treinamento. O Rubertiano com melhor desempenho será o nosso representante no desafio final.",
    ]
    
    @State var currentDialogue: String = ""
    @State var dialogueIndex = 0
    @State var canShowControlPanel = false
    
    var body: some View {
        ZStack {
            GamePlanetIceViewRepresentable()
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
                    Spacer()
                    
                    if manager.king != nil {
                        Button {
                            manager.finishGame()
                            manager.backToMenuFromIce()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right")
                                Text("Go to final challenge")
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
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
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
                    RoundedRectangle(cornerRadius: 14.0)
                        .foregroundStyle(.bar)
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
                            .fill(dialogueIndex < 3 ? Color("gamePurple") : Color(.gray))
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
        GamePlanetIceView()
    }
    .environmentObject(Manager.instance)
}
