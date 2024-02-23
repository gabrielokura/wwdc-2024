//
//  ContentView.swift
//  TowerDefense
//
//  Created by Gabriel Motelevicz Okura on 25/07/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var manager = Manager.instance
    
    var body: some View {
        ZStack {
            switch manager.gameScene {
            case .menu:
                MenuView()
            case .planetEarth:
                GamePlanetEarthView()
            case .planetIce:
                GameLevelView()
            case .planetMix:
                GameLevelView()
            }
        }
        .environmentObject(manager)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
