//
//  GameLevelView.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 25/07/23.
//

import SwiftUI
import SceneKit

struct GamePlanetMixView: View {
    @EnvironmentObject var manager: Manager
    @State var interactions = 0
    
    @State var currentDialogue: String = ""
    
    @State var showGoToMenu = false
    
    var body: some View {
        ZStack {
            GamePlanetMixViewRepresentable()
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
                
                if showGoToMenu {
                    HStack {
                        Button {
                            manager.finishGame()
                            manager.backToMenuFromMix()
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
                        
                        Spacer()
                        
                        Text("Thanks for trying Smart Aliens :)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding()
                        
                        Spacer()
                    }
                }
                
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        // colocar o king no cenário
                        manager.startGame(population: 1, decisions: 4, speed: 1.0)
                        showGoToMenu = true
                    } label: {
                        Text("Play")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .padding(.horizontal, 50)
                    .background {
                        RoundedRectangle(cornerRadius: 14.0)
                            .foregroundStyle(Color("gamePurple"))
                    }
                    
                    Spacer()
                    returnCameraPositionButton
                }
            }
        }
        .onAppear {
            let checkpoints = manager.checkpointsCounter
            let dialogue = "The ideal training could take hundreds of generations, we don't have the time... I hope that our best alien will be enough to complete this challenge.\n\n After all, he managed to collect \(checkpoints) yellow balls.\n\n Press 'play'"
            currentDialogue = dialogue
        }
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
                    .stroke(Color(.white))
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

struct GamePlanetMixView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            GamePlanetMixView()
        }
        .environmentObject(Manager.instance)
    }
}
