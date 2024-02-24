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
                Button {
                    // colocar o king no cenário
                    manager.startGame(population: 1, decisions: 4, speed: 1.0)
                } label: {
                    Text("Play")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.white)
                }
                .padding()
                .padding(.horizontal)
                .background {
                    RoundedRectangle(cornerRadius: 14.0)
                        .foregroundStyle(Color("gamePurple"))
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
