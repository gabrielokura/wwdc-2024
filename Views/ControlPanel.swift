//
//  SwiftUIView.swift
//
//
//  Created by Gabriel Motelevicz Okura on 22/02/24.
//

import SwiftUI

struct ControlPanel: View {
    @Binding var isTraining: Bool
    @State private var populationSize: Int = 10
    @State private var decisionsPerSecond: Int = 4
    private let decisionsRange = 1...10
    
    @State private var alienSpeed: Float = 1
    private let alienSpeedRange: ClosedRange<Float> = 0.5...1.5
    
    var hasStartedGeneration: Bool
    var currentGeneration: Int
    var isCameraFixed: Bool
    
    let onPressStartGame: (Int, Int, Float) -> Void
    let onPressResetGeneration: () -> Void
    let onPressStopTraining: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack {
                
                if isTraining {
                    Text("Generation: \(currentGeneration)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                if isTraining {
                    HStack {
                        stopTrainingButton
                        
                        killAllAliensButton
                    }
                }
                
                
                if !isTraining {
                    startButton
                }
            }
            
            Spacer()
            
            Group {
                populationStepper
                
                decisionsPerSecondStepper
                
                alienSpeedSlider
            }
            .opacity(isTraining ? 0.75 : 1)
            
        }
        .padding()
        
    }
    
    var startButton: some View {
        Button {
            onPressStartGame(populationSize, decisionsPerSecond, alienSpeed)
            withAnimation {
                isTraining = true
            }
        } label: {
            HStack {
                Group {
                    Text("start training")
                    
                    Image(systemName: "play")
                }
                .font(.system(size: 20))
                .fontWeight(.regular)
                .foregroundColor(.white)
                
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 14.0)
                    .foregroundStyle(Color("gamePurple"))
            }
        }
    }
    
    var killAllAliensButton: some View {
        Button {
            onPressResetGeneration()
        } label: {
            HStack {
                Group {
                    Text("kill  aliens")
                    
                    Image(systemName: "xmark")
                }
                .font(.system(size: 20))
                .fontWeight(.regular)
                .foregroundColor(.white)
                
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 14.0)
                //                    .stroke(.black, lineWidth: 1)
                    .foregroundStyle(Color("gamePurple"))
            }
        }
    }
    
    var stopTrainingButton: some View {
        Button {
            onPressStopTraining()
            withAnimation {
                isTraining = false
            }
        } label: {
            HStack {
                Group {
                    Text("stop training")
                    
                    Image(systemName: "stop")
                }
                .font(.system(size: 20))
                .fontWeight(.regular)
                .foregroundColor(.white)
                
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 14.0)
                    .foregroundStyle(Color(.red))
            }
        }
    }
    
    var populationStepper: some View {
        VStack (){
            Text("Population\n")
            Text("\(populationSize)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if !isTraining {
                Stepper {
                    Text("population")
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
        VStack() {
            Text("Decisions per second\n")
            Text("\(decisionsPerSecond)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if !isTraining {
                Stepper("", value: $decisionsPerSecond, in: decisionsRange)
                    .labelsHidden()
            }
        }
    }
    
    var alienSpeedSlider: some View {
        VStack {
            Text("Aliens speed\n")
            Text(String(format: "%.2f", alienSpeed))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if !isTraining {
                Slider(value: $alienSpeed, in: alienSpeedRange)
                    .frame(width: 100)
            }
        }
    }
}

#Preview {
    ControlPanel(isTraining: .constant(false) , hasStartedGeneration: false, currentGeneration: 1, isCameraFixed: false, onPressStartGame: {(_, __, ___) in }, onPressResetGeneration: {}, onPressStopTraining: {})
}
