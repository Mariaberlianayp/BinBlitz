//
//  ViewController.swift
//  BinBlitz
//
//  Created by Maria Berliana on 22/05/23.
//

import UIKit
import SceneKit
import ARKit
import SwiftUI


struct GameOverView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var redirectToHome = false
    var bestScore: Int = UserDefaults.standard.integer(forKey: "bestScore")
    
    var onGameOverButtonClicked: (() -> ())?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 42/255, green: 35/255, blue: 78/255)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Image("gameover")
                    Text("BEST SCORE: \(bestScore)")
                        .fontWeight(.black)
                        .foregroundColor(Color("tosca"))
                        .modifier(LetterSpacingModifier(letterSpacing: 5.0))
                    NavigationLink(destination: homeView(), isActive: $redirectToHome) {
                        EmptyView()
                    }
                    Button(action: {
                        if let onGameOverButtonClicked{
                            onGameOverButtonClicked()
                        }
                        redirectToHome = true
                    }) {
                        Text("BACK TO HOME")
                            .fontWeight(.black)
                            .foregroundColor(Color("DarkBlue"))
                            .padding()
                            .background(Color("tosca"))
                            .cornerRadius(30)
                    }
                    .padding()
                    .offset(y: 100)
                    .opacity(redirectToHome ? 0 : 1)
                    .onAppear {
                        redirectToHome = false // Reset the state when the view appears
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarHidden(true)
        }
        .onChange(of: redirectToHome) { newValue in
            if newValue {
//                presentationMode.wrappedValue.dismiss()
                var homeView = homeView()
                let hostingController = UIHostingController(rootView: homeView)
                hostingController.modalPresentationStyle = .overFullScreen
                hostingController.modalTransitionStyle = .crossDissolve
                
            }
        }
    }
}



struct LetterSpacingModifier: ViewModifier {
    var letterSpacing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .tracking(letterSpacing)
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var trackerNode: SCNNode!
    var mainContainer: SCNNode!
    var gameHasStarted = false
    var foundSurface = false
    var gamePos = SCNVector3Make(0.0, 0.0, 0.0)
    var scoreLbl: UILabel!
    var bestScoreLbl: UILabel!
    var timerLbl: UILabel!
    var score = 0 {
        didSet{
            scoreLbl.text="\(score)"
        }
    }
    private var timer: Timer?
    private var elapsedTime: TimeInterval = 0
    @State var bestScore: Int = UserDefaults.standard.integer(forKey: "bestScore") ?? 3
    
    //timerLbl
    var elapsedTime2 = 0 // Waktu dalam detik
    var totalSeconds = 75 // Total waktu dalam detik (1 menit 15 detik)
    
    var stackView: UIStackView!
    var backgroundView: UIView!

    override func viewDidLoad() {
            super.viewDidLoad()

            // Create a new ARSCNView and set it as the view of the view controller
            sceneView = ARSCNView()
            view = sceneView
            
            // Set the view's delegate
            sceneView.delegate = self
            
            // Show statistics such as fps and timing information
            sceneView.showsStatistics = true
            
            // Create a new scene
            let scene = SCNScene(named: "art.scnassets/ship.scn")!
            
            // Set the scene to the view
            sceneView.scene = scene
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            // Create a session configuration
            let configuration = ARWorldTrackingConfiguration()

            // Run the view's session
            sceneView.session.run(configuration)
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            // Pause the view's session
            sceneView.session.pause()
        }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !gameHasStarted else {return}
        guard let hitTest = sceneView.hitTest(CGPoint(x : view.frame.midX, y: view.frame.midY), types: [.existingPlane, .featurePoint]).last else {return}
        let trans = SCNMatrix4(hitTest.worldTransform)
        gamePos = SCNVector3Make(trans.m41, trans.m42, trans.m43)
        
        if !foundSurface{
            let trackerPlane = SCNPlane(width: 0.3, height: 0.3)
            trackerPlane.firstMaterial?.diffuse.contents = UIImage(named: "tracker")
            
            trackerNode = SCNNode(geometry: trackerPlane)
            trackerNode.eulerAngles.x = .pi * -0.5
            
            sceneView.scene.rootNode.addChildNode(trackerNode)
        }
        trackerNode.position = gamePos
        foundSurface = true
        
    }
    
    func randomPosition() -> SCNVector3 {
        let randX = Float.random(in: -5.0...5.0)
        let randY = -10.0
        let randZ = mainContainer.position.z + 5.0
        
        return SCNVector3(randX, Float(randY), randZ)
    }


    func addPlane() {
        let planeNode = createPlaneNode()
        mainContainer.addChildNode(planeNode)
        
        // Set initial position in front of the mainContainer
        let initialX = Float.random(in: -5.0...5.0)
        let initialY = Float.random(in: -10.0...10.0)
        let initialZ = mainContainer.position.z + 5.0
        let initialPosition = SCNVector3(initialX, initialY, initialZ)
        planeNode.position = initialPosition
        
        let targetPosition = SCNVector3(mainContainer.position.x, mainContainer.position.y, mainContainer.position.z - 20.0)
        let moveAction = SCNAction.move(to: targetPosition, duration: 5.0)
        
        let fadeOutAction = SCNAction.fadeOut(duration: 2.0)
        let fadeOutAndRemoveAction = SCNAction.sequence([
            SCNAction.wait(duration: 3.0), // Menunggu beberapa saat sebelum memulai fading out
            fadeOutAction,
            SCNAction.removeFromParentNode()
        ])
        
        let actionGroup = SCNAction.group([moveAction, fadeOutAndRemoveAction])
        planeNode.runAction(actionGroup)
    }



    func createPlaneNode() -> SCNNode {
        guard let planeScene = SCNScene(named: "art.scnassets/ship.scn"),
              let planeNode = planeScene.rootNode.childNode(withName: "paper", recursively: false) else {
            fatalError("Failed to load plane scene or find plane node")
        }

        planeNode.name = "paper"
        planeNode.isHidden = false
        planeNode.position = randomPosition()

        return planeNode
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if gameHasStarted {
                // Tambahkan logika saat game sudah dimulai
                if let touch = touches.first {
                    let location = touch.location(in: sceneView)
                    let hitResults = sceneView.hitTest(location, options: nil)
                    
                    if let planeNode = hitResults.first?.node, planeNode.name == "Object_0" {
                        score += 1
                        updateScoreLabel()
                        let fallAction = SCNAction.moveBy(x: 0, y: CGFloat(-4.0), z: CGFloat(2.0), duration: 0.5)
                        let removeAction = SCNAction.removeFromParentNode()
                        let sequenceAction = SCNAction.sequence([fallAction, removeAction])
                        planeNode.runAction(sequenceAction)
                    }
                }
            } else {
                guard foundSurface else { return }
                trackerNode.removeFromParentNode()
                gameHasStarted = true
                
                
                // Create the timer label
                timerLbl = UILabel()
                timerLbl.textAlignment = .center
                let fontSize: CGFloat = 25.0
                let font = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.black)
                timerLbl.font = font
                timerLbl.textColor = UIColor(red: 42/255, green: 35/255, blue: 78/255, alpha: 1.0)

                timerLbl.text = timeString(from: totalSeconds)
                view.addSubview(timerLbl)

                // Create the score label
                scoreLbl = UILabel()
                scoreLbl.textAlignment = .center
                scoreLbl.font = UIFont(name: "Arial", size: 15)
                scoreLbl.textColor = UIColor(red: 42/255, green: 35/255, blue: 78/255, alpha: 1.0)

                updateScoreLabel()
                view.addSubview(scoreLbl)
                
                // Create the best score label
                bestScoreLbl = UILabel()
                bestScoreLbl.textAlignment = .center
                bestScoreLbl.font = UIFont(name: "Arial", size: 15)
                bestScoreLbl.textColor = UIColor(red: 42/255, green: 35/255, blue: 78/255, alpha: 1.0)
   
                bestScoreLbl.text = "BEST: \(bestScore)"
                view.addSubview(bestScoreLbl)
                
                setupStackView()
                createBackgroundView()
                
                mainContainer = sceneView.scene.rootNode.childNode(withName: "mainContainer", recursively: false)!
                mainContainer.isHidden = false
                mainContainer.position = gamePos
                
                let planeNode = SCNNode()
                planeNode.name = "paper"
                sceneView.scene.rootNode.addChildNode(planeNode)
                
                // Mulai timer
                startTimer()
                startTimer2()
                
                let ambientLight = SCNLight()
                ambientLight.type = .ambient
                ambientLight.color = UIColor.white
                ambientLight.intensity = 1000
                
                let ambientLightNode = SCNNode()
                ambientLightNode.light = ambientLight
                ambientLightNode.position.y = 3.0
                
                mainContainer.addChildNode(ambientLightNode)
                
                let omniLight = SCNLight()
                omniLight.type = .omni
                omniLight.color = UIColor.white
                omniLight.intensity = 500
                
                let omniLightNode = SCNNode()
                omniLightNode.light = omniLight
                omniLightNode.position.y = 3.0
                
                mainContainer.addChildNode(omniLightNode)
            }
        }
    func createBackgroundView() {
            let labels = [timerLbl, scoreLbl, bestScoreLbl]
            var maxWidth: CGFloat = 0
            var totalHeight: CGFloat = 0

            for label in labels {
                if let unwrappedLabel = label {
                    unwrappedLabel.sizeToFit()
                    let labelWidth = unwrappedLabel.frame.width
                    let labelHeight = unwrappedLabel.frame.height
                    maxWidth = max(maxWidth, labelWidth)
                    totalHeight += labelHeight
                }
            }

            let padding: CGFloat = 10.0
            let backgroundWidth = view.frame.width / 3
            let backgroundHeight = totalHeight + (padding * CGFloat(labels.count - 1))

            backgroundView = UIView()
            backgroundView.backgroundColor = UIColor(red: 61/255, green: 195/255, blue: 182/255, alpha: 0.7) // Latar belakang tosca dan transparan
        backgroundView.layer.cornerRadius = 20
            backgroundView.translatesAutoresizingMaskIntoConstraints = false

            view.insertSubview(backgroundView, at: 0)

            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -padding),
                backgroundView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
                backgroundView.widthAnchor.constraint(equalToConstant: backgroundWidth),
                backgroundView.heightAnchor.constraint(equalToConstant: backgroundHeight)
            ])
        }
    func setupStackView() {
            stackView = UIStackView(arrangedSubviews: [timerLbl, scoreLbl, bestScoreLbl])
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = 2.0
            stackView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0),
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
    
    func updateScoreLabel() {
            scoreLbl.text = "SCORE: \(score)"
    }

    func startTimer2() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    @objc func updateTimer() {
           if elapsedTime2 < totalSeconds {
               elapsedTime2 += 1
               timerLbl.text = timeString(from: totalSeconds - elapsedTime2)
           } else {
               stopTimer()
               // Countdown selesai, lakukan tindakan yang diperlukan di sini
           }
       }

       func stopTimer() {
           timer?.invalidate()
           timer = nil
       }

       func timeString(from seconds: Int) -> String {
           let minutes = seconds / 60
           let seconds = seconds % 60
           return String(format: "%02d:%02d", minutes, seconds)
       }
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            self?.elapsedTime += 1
            self?.timerLbl.text = "\(self?.elapsedTime ?? 0)"
            self?.addPlane()
            if self?.elapsedTime == 75 { // Setelah 1 menit (60 detik)
                self?.saveBestScore()
                self?.timer?.invalidate()
                self?.timer = nil
                self?.showGameOverView()
                
            }
        })
    }
        
    private func showGameOverView() {
        var gameOverView = GameOverView()
        gameOverView.onGameOverButtonClicked = {
            let hostingController = UIHostingController(rootView: homeView())
            // Assign this hostincontroller to the mainWindow
        }
        let hostingController = UIHostingController(rootView: gameOverView)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        self.present(hostingController, animated: true, completion: nil)
    }
    
    private func saveBestScore(){
        let currentBestScore = UserDefaults.standard.integer(forKey: "bestScore")
        print(score)
        if currentBestScore < score{
            UserDefaults.standard.setValue(score, forKey: "bestScore")
        }
        
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
}
