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
        "Now we're going to use a genetic algorithm to teach them how to reach the yellow balls.",
        "You'll notice that the behavior of the first generation is completely random. The neural network is responsible for improving its movements with each new generation.",
        "In other words, we'll use the DNA of the alien who collects the most yellow balls to improve the next generations. Okay?",
        "Increase the population size and press 'start training' to begin.",
    ]
    
    @State var currentDialogue: String = ""
    @State var dialogueIndex = 0
    @State var canShowControlPanel = false
    
    @State var canGoToFinalChallenge = false
    let finalDialogue: String = "Hmmm... I think we've had enough, let's move on to the last challenge."
    
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
                    
                    if canGoToFinalChallenge {
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
        .onChange(of: manager.currentGeneration) { newValue in
            if manager.currentGeneration > 2 && manager.checkpointsCounter > 0 {
                withAnimation {
                    canGoToFinalChallenge = true
                    currentDialogue = finalDialogue
                }
            }
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
            
            if !canGoToFinalChallenge {
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
