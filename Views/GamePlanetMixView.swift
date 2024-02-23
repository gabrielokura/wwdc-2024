//
//  GameLevelView.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 25/07/23.
//

import SwiftUI
import SceneKit

struct GameLevelView: View {
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
                ControlPanel(
                    isTraining: $isTraining,
                    hasStartedGeneration: manager.hasStarted,
                    currentGeneration: manager.currentGeneration,
                    isCameraFixed: manager.isCameraFixed,
                    onPressStartGame: { (populationSize, decisionsPerSecond, alienSpeed) in
                        manager.startGame(population: populationSize, decisions: decisionsPerSecond, speed: alienSpeed)
                    }, onPressResetGeneration: {
                        manager.resetCurrentGeneration()
                    }, onPressCamere: {
                        manager.returnCameraToInitialPosition()
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
}

struct GameLevelView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            GameLevelView()
        }
        .environmentObject(Manager.instance)
    }
}
