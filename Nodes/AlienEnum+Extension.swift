//
//  File.swift
//  
//
//  Created by Gabriel Motelevicz Okura on 16/02/24.
//

import Foundation
import SceneKit

enum AlienType {
    case purple
    
    var health: Int {
        switch self {
        case .purple:
            return 100
        }
    }
    
    var initialPosition: SCNVector3 {
        switch self {
        case .purple:
            return SCNVector3(5, 0.5, -10)
        }
    }
    
    var pathNodeName: String {
        switch self {
        case .purple:
            return "purple_path"
        }
    }
}

enum MovementDirection {
    case top, right, bottom, left
    
    func nextMove(position: SCNVector3) -> SCNVector3 {
        var x = position.x
        var z = position.z
        
        switch self {
        case .top:
            z -= 1
        case .right:
            x += 1
        case .bottom:
            z += 1
        case .left:
            x -= 1
        }
        
        return SCNVector3(x, position.y, z)
    }
    
    func directionWithMagnitude(magnitude: Float) -> SCNVector3 {
        var x: Float = 0
        let y: Float = 0
        var z: Float = 0
        
        switch self {
        case .top:
            z -= 1
        case .right:
            x += 1
        case .bottom:
            z += 1
        case .left:
            x -= 1
        }
        
        return SCNVector3(x*magnitude, y, z*magnitude)
    }
    
    func isOpposite(of direction: MovementDirection) -> Bool {
        let currentDirection = self
        
        if currentDirection == .top && direction == .bottom {
            return true
        }
        
        if currentDirection == .bottom && direction == .top {
            return true
        }
        
        if currentDirection == .left && direction == .right {
            return true
        }
        
        if currentDirection == .right && direction == .left {
            return true
        }
        
        return false
    }
    
    func getOpposite() -> MovementDirection {
        
        if self == .bottom {
            return .top
        }
        
        if self == .top {
            return .bottom
        }
        
        if self == .left {
            return .right
        }
        
        if self == .right {
            return .left
        }
        
        return .top
    }
}

extension Int {
    func xToGameMatrix() -> Int {
        return self + GameSceneController.xBaseSum
    }
    
    func zToGameMatrix() -> Int {
        return self + GameSceneController.zBaseSum
    }
}
