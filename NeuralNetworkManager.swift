//
//  NeuralNetworkManager.swift
//  SmartAliens
//
//  Created by Gabriel Motelevicz Okura on 06/02/24.
//

import Neat
import GameplayKit

class NeuralNetworkManager {
    let network: Neat
    var king: NGenome? = nil
    
    var currentGeneration: Int
    
    var aliens: [Alien] = []
    
    let inputCount: Int
    let outputCount: Int
    
    let frameRate = 1
    var currentFrame = 5
    
    init(population: Int) {
        self.king = nil
        self.currentGeneration = 1
        self.inputCount = Alien.inputCount
        self.outputCount = Alien.outputCount
        
        self.network = Neat(inputs: self.inputCount, outputs: self.outputCount, population: population, confFile: nil, multithread: false)
    }
    
    func train(aliens: [Alien]) {
        currentFrame += 1
        
        if currentFrame % frameRate != 0 {
            return
        }
        
        currentFrame = 0
        
        let queue = DispatchQueue(label: "com.okura.smartAliens",attributes: .concurrent)
        
        queue.async(flags: .barrier) {
            print("Training")
            for i in 0..<self.aliens.count {
                let alien = self.aliens[i]
                
                let inputData: [Double] = alien.generateInputDataForNeuralNetwork()
                
                let output = self.network.run(inputs: inputData, inputCount: self.inputCount, outputCount: self.outputCount)
                self.network.nextGenomeStepOne(alien.fitnessLevel)
                
                alien.move(x: output[0], z: output[1], breakValue: output[2])
            }
        }
    }
    
    func newGeneration() {
        // Assign genomes a fitness score from the tests.
        network.nextGenomeStepTwo()
        
        // Do NEAT here.
        network.epoch()
        
        king = network.getKing()
    }
}
