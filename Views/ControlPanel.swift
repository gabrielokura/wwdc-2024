//
//  SwiftUIView.swift
//  
//
//  Created by Gabriel Motelevicz Okura on 22/02/24.
//

import SwiftUI

struct ControlPanel: View {
    @Binding var isTraining: Bool
    @State private var populationSize: Int = 40
    @State private var decisionsPerSecond: Int = 4
    private let decisionsRange = 1...10
    
    @State private var alienSpeed: Float = 1
    private let alienSpeedRange: ClosedRange<Float> = 0.5...1.5
    
    var hasStartedGeneration: Bool
    var currentGeneration: Int
    var isCameraFixed: Bool
    
    let onPressStartGame: (Int, Int, Float) -> Void
    let onPressResetGeneration: () -> Void
    let onPressCamere: () -> Void
    let onPressStopTraining: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                VStack(spacing: 16) {
                    Text("Generation: \(currentGeneration)")
                    
                    HStack {
                        if !hasStartedGeneration {
                            startButton
                        }
                        
                        if hasStartedGeneration {
                            killAllAliensButton
                        }
                        
                        if isTraining {
                            stopTrainingButton
                        }
                        
                        returnCameraPositionButton
                    }

                }
                
                Spacer()
                
                VStack {
                    HStack {
                        Spacer()
                        populationStepper
                    }
                    
                    HStack {
                        Spacer()
                        decisionsPerSecondStepper
                    }
                    
                    HStack {
                        Spacer()
                        alienSpeedSlider
                    }
                }
                .opacity(isTraining ? 0.75 : 1)
            }
        }
        .padding()
        
    }
    
    var returnCameraPositionButton: some View {
        Button {
            onPressCamere()
        } label: {
            Image(systemName: "camera.circle")
                .font(.largeTitle)
                .foregroundColor(.black)
        }
    }
    
    var startButton: some View {
        Button {
            onPressStartGame(populationSize, decisionsPerSecond, alienSpeed)
            withAnimation {
                isTraining = true
            }
            
        } label: {
            Image(systemName: "play.circle")
                .font(.largeTitle)
                .foregroundColor(.red)
        }
    }
    
    var killAllAliensButton: some View {
        Button {
            onPressResetGeneration()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
        }
    }
    
    var stopTrainingButton: some View {
        Button {
            onPressStopTraining()
            withAnimation {
                isTraining = false
            }
        } label: {
            Image(systemName: "stop.circle")
                .font(.largeTitle)
                .foregroundColor(.red)
        }
    }
    
    var populationStepper: some View {
        HStack {
            Text("Population: \(populationSize)")
            
            if !isTraining {
                Stepper {
                    Text("Population: \(populationSize)")
                } onIncrement: {
                    if populationSize >= 100 {
                        return
                    }
                    
                    populationSize += 10
                } onDecrement: {
                    if populationSize <= 10 {
                        return
                    }
                    
                    populationSize -= 10
                }
                .labelsHidden()
            }
        }
    }
    
    var decisionsPerSecondStepper: some View {
        HStack {
            Text("Decisions per second: \(decisionsPerSecond)")
            
            if !isTraining {
                Stepper("", value: $decisionsPerSecond, in: decisionsRange)
                    .labelsHidden()
            }
        }
    }
    
    var alienSpeedSlider: some View {
        HStack {
            Text(String(format: "Aliens speed: %.2f", alienSpeed))
            
            if !isTraining {
                Slider(value: $alienSpeed, in: alienSpeedRange)
                    .frame(width: 100)
            }
        }
    }
}

#Preview {
    ControlPanel(isTraining: .constant(false) , hasStartedGeneration: false, currentGeneration: 1, isCameraFixed: false, onPressStartGame: {(_, __, ___) in }, onPressResetGeneration: {}, onPressCamere: {}, onPressStopTraining: {})
}
