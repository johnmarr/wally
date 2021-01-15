//
//  WallyGrid.swift
//  Wally
//
//  Created by John Marr on 1/14/21.
//

import Foundation
import SceneKit
import ARKit


extension ARPlaneAnchor {
    // Convert meters to inches
    var width: Float { return self.extent.x * 39.3701}
    var length: Float { return self.extent.z * 39.3701}
}

class WallyGrid : SCNNode {
    
    var anchor: ARPlaneAnchor
    var planeGeometry: SCNPlane!
    
    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        // Set up grid plane and material
        planeGeometry = SCNPlane(width: CGFloat(anchor.width), height: CGFloat(anchor.length))
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "grid.png")
        planeGeometry.materials = [material]
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        planeNode.physicsBody?.categoryBitMask = 2
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
        planeNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0);
        addChildNode(planeNode)
    }
    
    func update(anchor: ARPlaneAnchor) {
        // Adjust plane dimensions as more data comes in
        planeGeometry.width = CGFloat(anchor.extent.x);
        planeGeometry.height = CGFloat(anchor.extent.z);
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
        let planeNode = self.childNodes.first!
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
    }
}
