//
//  ViewController.swift
//  Wally
//
//  Created by John Marr on 1/14/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cameraButtonVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var colorControls: UIStackView!
    @IBOutlet weak var colorControlsVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var hueSlider: GradientSlider!
    @IBOutlet weak var brightnessSlider: GradientSlider!
    @IBOutlet weak var saturationSlider: GradientSlider!

    var wallyGrids = [WallyGrid]()
    var seekingWalls = true
    var wallyNode: SCNNode?
    var wallyTexture = UIImage(named: "wallyTexture")
    var sounds = Sounds()
    var currentBrightness = CGFloat(1.0)
    var currentHue = CGFloat(0.5)
    var currrentSaturation = CGFloat(1.0)
    
    //MARK:- View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self

        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
        
        // Set the tap gesture recognizer for detecting wallyGrid taps
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)

        // Set up the hue color slider
        hueSlider.setGradientVaryingHue(saturation: 1.0, brightness: 1.0)
        hueSlider.thickness = 7
        hueSlider.actionBlock = { slider,newValue,finished in
            self.currentHue = newValue
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            let brightestColor = UIColor(hue: newValue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            self.hueSlider.thumbColor = brightestColor
            self.saturationSlider.maxColor = brightestColor
            let finalColor = UIColor(hue: newValue, saturation: self.currrentSaturation, brightness: self.currentBrightness, alpha: 1.0)
            self.wallyNode?.geometry?.materials.first?.diffuse.contents = finalColor
            self.wallyNode?.geometry?.materials.first?.normal.contents = self.wallyTexture
            self.wallyNode?.geometry?.materials.first?.lightingModel = .physicallyBased
            CATransaction.commit()
        }
        
        // Set up the brightness color slider
        brightnessSlider.maxColor = UIColor.white
        brightnessSlider.thickness = 7
        brightnessSlider.minColor = UIColor.black
        brightnessSlider.thumbIcon = UIImage(named: "sun")
        brightnessSlider.actionBlock = { slider, newValue, finished in
            self.currentBrightness = newValue
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            self.saturationSlider.minColor = UIColor(hue: self.currentHue, saturation: 0, brightness: self.currentBrightness, alpha: 1.0)
            let finalColor = UIColor(hue: self.currentHue, saturation: self.currrentSaturation, brightness: newValue, alpha: 1.0)
            self.wallyNode?.geometry?.materials.first?.diffuse.contents = finalColor
            self.wallyNode?.geometry?.materials.first?.normal.contents = self.wallyTexture
            self.wallyNode?.geometry?.materials.first?.lightingModel = .physicallyBased
            CATransaction.commit()
        }
        
        // Set up the saturation color slider
        saturationSlider.minColor = UIColor.darkGray
        saturationSlider.thickness = 7
        saturationSlider.thumbIcon = UIImage(named: "drop")
        saturationSlider.actionBlock = { slider, newValue, finished in
            self.currrentSaturation = newValue
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            let finalColor = UIColor(hue: self.currentHue, saturation: newValue, brightness: self.currentBrightness, alpha: 1.0)
            self.wallyNode?.geometry?.materials.first?.diffuse.contents = finalColor
            self.wallyNode?.geometry?.materials.first?.normal.contents = self.wallyTexture
            self.wallyNode?.geometry?.materials.first?.lightingModel = .physicallyBased
            CATransaction.commit()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
        
        // Preset color control sliders
        hueSlider.setValue(0.5, animated: true)
        saturationSlider.setValue(1.0, animated: true)
        brightnessSlider.setValue(1.0, animated: true)
        self.hueSlider.thumbColor = UIColor(hue: 0.5, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func startSession() {
        // Create and run a world tracking session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)
    }
    
    //MARK:- WallyNode Handling
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        
        guard seekingWalls else { return }
        
        // Get 2D position of touch event on screen
        let touchPosition = gesture.location(in: sceneView)
        
        // Translate those 2D points to 3D points using hitTest (existing plane)
        let hitTestResults = sceneView.hitTest(touchPosition, types: .existingPlaneUsingExtent)
        
        // Get hitTest results and ensure that the hitTest corresponds to a WallyGrid that has been placed on a wall
        guard let hitTest = hitTestResults.first,
              let anchor = hitTest.anchor as? ARPlaneAnchor,
              let wallyGridIndex = wallyGrids.firstIndex(where: { $0.anchor == anchor }) else {
            return
        }
        addWallyNode(hitTest, wallyGrids[wallyGridIndex])
        seekingWalls = false
    }
    
    func addWallyNode(_ hitResult: ARHitTestResult, _ WallyGrid: WallyGrid) {
        
        // Play success sound
        sounds.playSound(file: .success)
        
        // Set WallyNode size and add it to the root node.
        let planeGeometry = SCNPlane(width: 0.75, height: 0.75)
        wallyNode = SCNNode(geometry: planeGeometry)
        guard let wally = wallyNode else { return }
        wally.transform = SCNMatrix4(hitResult.anchor!.transform)
        wally.eulerAngles = SCNVector3(wally.eulerAngles.x + (-Float.pi / 2), wally.eulerAngles.y, wally.eulerAngles.z)
        wally.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(wally)
        
        // Set WallyNode default colors, lighting, and texture
        let color = UIColor(hue: self.currentHue, saturation: self.currrentSaturation, brightness: self.currentBrightness, alpha: 1.0)
        self.wallyNode?.geometry?.materials.first?.diffuse.contents = color
        self.wallyNode?.geometry?.materials.first?.normal.contents = self.wallyTexture
        self.wallyNode?.geometry?.materials.first?.lightingModel = .physicallyBased
        
        // Reemove all grids. The focus is on this WallyNode now.
        for wallyGrid in wallyGrids {
            wallyGrid.removeFromParentNode()
        }
        
        // Animate in the color controls.
        UIView.animate(withDuration: 1, delay: 0.5, options: .curveEaseInOut) {
            self.colorControls.alpha = 1
        }
    }
    
    //MARK:- IBActions
    
    @IBAction func cameraPressed() {
        // Create a UIImage from the ARSCNView
        let image = sceneView.snapshot()
        
        // Play the camera sound
        sounds.playSound(file: .shutter)
        
        // Save the imaage to the camera roll.
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Inform user that the photo was saved.
        let alert = UIAlertController(title: "Sucess!", message: "Your screen was saved to your photos.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func wallyLogoPressed() {
        // Present option to reset the experience.
        let alert = UIAlertController(title: "Reset?", message: "Would you like to start over?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
            self.reset()
        }))
        self.present(alert, animated: true)
    }
    
    func reset() {
        sounds.playSound(file: .reset)
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
            self.colorControls.alpha = 0
        }, completion: { (finished: Bool) in
            self.sceneView.session.pause()
            self.brightnessSlider.setValue(1.0, animated: true)
            self.hueSlider.setValue(0.5, animated: true)
            self.saturationSlider.setValue(1.0, animated: true)
            self.wallyNode?.removeFromParentNode()
            self.seekingWalls = true
            self.startSession()
        })
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        let alert = UIAlertController(title: "Session Error.",
                                      message: "This session has failed. Please try again.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        let alert = UIAlertController(title: "Session Interrupted.",
                                      message: "This session was interrupted. Please relaunch if the trouble persists.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        self.reset()
    }
    
    // Called when a new vertical plane is detected.
    // If we're seeking walls (not adjusting a WallyNode's color)
    // we add a new grid to the node.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard seekingWalls, let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
        let wallyGrid = WallyGrid(anchor: planeAnchor)
        self.wallyGrids.append(wallyGrid)
        node.addChildNode(wallyGrid)
    }
    
    // Called when detected nodes are updated,
    // allowing grids to adjust in size and location
    // as new scanning data becomes available.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard seekingWalls, let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
        let wallyGrid = self.wallyGrids.filter { wallyGrid in
            return wallyGrid.anchor.identifier == planeAnchor.identifier
            }.first
        
        guard let foundWallyGrid = wallyGrid else {
            return
        }
        
        foundWallyGrid.update(anchor: planeAnchor)
    }
}
