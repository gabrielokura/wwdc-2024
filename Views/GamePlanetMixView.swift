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
    @State var isTraining = false
    
    var body: some View {
        ZStack {
            GamePlanetMixViewRepresentable()
                .ignoresSafeArea()
            
            if manager.isLoadingMap {
                ProgressView()
            }
            
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
}

struct GamePlanetMixView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            GamePlanetMixView()
        }
        .environmentObject(Manager.instance)
    }
}
