//
//  SwiftUIView.swift
//  
//
//  Created by Gabriel Motelevicz Okura on 23/02/24.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject var manager: Manager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("stars_background")
                    .resizable()
                    .scaledToFit()
                
                pathImage
                    .padding(.leading, 200)
                    .padding(.top, -280)
                    .opacity(0.5)
                
                VStack {
                    HStack  {
                        Spacer()
                        Button {
                            manager.onPressFirstPlanet()
                        } label: {
                            planetEarthImage
                        }
                        
                        Spacer()
                        
                        Button {
                            manager.onPressSecondPlanet()
                        } label: {
                            planetIceImage
                        }
                        Spacer()
                    }
                    
                    Button {
                        manager.onPressThirdPlanet()
                    } label: {
                        planetMixImage
                    }
                    .padding(.leading, 100)
                    
                    Spacer()
                }
                .opacity(manager.hasStartedGame ? 1 : 0.1)
                
                HStack {
                    VStack {
                        Spacer()
                        alienImage
                            .opacity(manager.hasStartedGame ? 1 : 0.1)
                    }
                    
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        if manager.hasStartedGame {
                            dialogueCard
                        } else {
                            Button {
                                withAnimation {
                                    manager.hasStartedGame = true
                                }
                                
                            } label: {
                                Text("Start game")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(26)
                                    .background {
                                        RoundedRectangle(cornerRadius: 14.0)
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
            .background {
                Rectangle()
                    .fill(Color("background"))
                    .ignoresSafeArea()
            }
            .onAppear {
                manager.startDialogues()
            }
        }
    }
    
    var dialogueCard: some View {
        VStack {
            Text(manager.currentDialogue)
                .font(.system(size: 20))
                .fontWeight(.regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            Spacer()
            
            HStack {
                Spacer()
                
                    Button {
                        manager.onPressBack()
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
                            RoundedRectangle(cornerRadius: 16.0)
                                .fill(manager.showBackButton ? Color("gamePurple") : Color(.gray))
                        }
                    }
                
                    Button {
                        manager.onPressNext()
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
                            RoundedRectangle(cornerRadius: 16.0)
                                .fill(manager.showNextButton && manager.canShowNextDialogue ? Color("gamePurple") : Color(.gray))
                        }
                    }
            }
        }
        .padding(20)
        .frame(width: 480, height: 380)
        .background {
            RoundedRectangle(cornerRadius: 25.0)
                .foregroundStyle(.bar)
        }
    }
    
    var pathImage: some View {
        Image("planets_path")
            .resizable()
            .scaledToFit()
    }
    
    var planetEarthImage: some View {
        ZStack {
            Image(manager.isFirstPlanetFilled ? "planet_earth_filled" : "planet_earth")
                .resizable()
                .scaledToFit()
                .opacity(manager.isFirstPlanetHidden ? 0.3 : 1)
            
            if manager.isFirstPlanetHidden {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
            }
        }
        .frame(width: 200, height: 220, alignment: .center)
    }
    
    var planetIceImage: some View {
        ZStack {
            Image(manager.isSecondPlanetFilled ? "planet_ice_filled" : "planet_ice")
                .resizable()
                .scaledToFit()
                .opacity(manager.isSecondPlanetHidden ? 0.3 : 1)
                                
            if manager.isSecondPlanetHidden {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .padding(.leading, 30)
            }
        }
        .frame(width: 300, height: 300, alignment: .center)
    }
    
    var planetMixImage: some View {
        ZStack {
            Image("planet_mix")
                .resizable()
                .scaledToFit()
                .opacity(manager.isThirdPlanetHidden ? 0.3 : 1)
            
            if manager.isThirdPlanetHidden {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .padding(.trailing, 20)
            }
        }
        .frame(width: 400, height: 400, alignment: .center)
    }
    
    var alienImage: some View {
        VStack {
            ZStack {
                Image("light")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 350)
                    .padding(.bottom, -500)
                
                Image("alien_1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 350)
            }
            
            Image("nimbus")
                .resizable()
                .scaledToFit()
                .frame(width: 500, height: 300)
                .padding(.bottom, -150)
        }
        .padding(.leading, -100)
    }
}

#Preview {
    ZStack {
        MenuView()
    }
    .environmentObject(Manager.instance)
}
