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
    
    var body: some View {
        ZStack {
            GamePlanetEarthViewRepresentable()
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

#Preview {
    ZStack {
        GamePlanetEarthView()
    }
    .environmentObject(Manager.instance)
}
