//
//  FloatingPetController.swift
//  Unhooked
//
//  UIKit-based floating pet above Dynamic Island
//  Uses a separate UIWindow at statusBar level for reliable positioning
//

import UIKit
import SwiftUI

class FloatingPetController {
    
    static let shared = FloatingPetController()
    
    private var petWindow: UIWindow?
    private var petHostingController: UIHostingController<AnyView>?
    private var displayLink: CADisplayLink?
    
    private var petX: CGFloat = 0
    private var velocityX: CGFloat = 0.8  // Slower, smoother movement
    
    private var currentSpecies: Species = .cat
    private var currentStage: Int = 0
    
    private let petViewSize: CGFloat = 18  // Pet pixel art size (6 cols * 2 scale = 12, with padding)
    
    private init() {}
    
    func show(species: Species, stage: Int) {
        // Check if device has Dynamic Island
        guard DeviceInfo.hasDynamicIsland else {
            print("🐾 FloatingPetController: No Dynamic Island, skipping")
            return
        }
        
        // If already showing, just update
        if petWindow != nil {
            updatePet(species: species, stage: stage)
            return
        }
        
        currentSpecies = species
        currentStage = stage
        
        print("🐾 FloatingPetController: Showing pet - \(species) stage \(stage)")
        
        // Find the active window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            print("🐾 FloatingPetController: No active window scene found")
            return
        }
        
        // Create a passthrough window above status bar
        let window = PassthroughWindow(windowScene: windowScene)
        window.windowLevel = .statusBar + 100  // Well above status bar
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        
        // Create SwiftUI pet view
        let petView = FloatingPetView(species: species, stage: stage)
        let hostingController = UIHostingController(rootView: AnyView(petView))
        hostingController.view.backgroundColor = .clear
        
        // Size the view to fit the pet
        let viewSize: CGFloat = 20
        hostingController.view.frame = CGRect(x: 0, y: 0, width: viewSize, height: viewSize)
        
        window.addSubview(hostingController.view)
        window.makeKeyAndVisible()
        
        // Start position - center of Dynamic Island
        let screenWidth = UIScreen.main.bounds.width
        let islandWidth = DeviceInfo.dynamicIslandWidth
        let islandCenterX = screenWidth / 2
        
        petX = islandCenterX - (viewSize / 2)
        
        // Position above Dynamic Island
        let topOfIsland = DeviceInfo.dynamicIslandTopPadding
        let petY = topOfIsland - viewSize + 4  // Slightly overlapping top edge
        
        hostingController.view.frame.origin = CGPoint(x: petX, y: petY)
        
        self.petWindow = window
        self.petHostingController = hostingController
        
        print("🐾 FloatingPetController: Window created at y=\(petY)")
        
        // Start animation loop
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func hide() {
        print("🐾 FloatingPetController: Hiding pet")
        displayLink?.invalidate()
        displayLink = nil
        petWindow?.isHidden = true
        petWindow = nil
        petHostingController = nil
    }
    
    func updatePet(species: Species, stage: Int) {
        guard currentSpecies != species || currentStage != stage else { return }
        
        currentSpecies = species
        currentStage = stage
        
        // Update the view
        if let hostingController = petHostingController {
            let petView = FloatingPetView(species: species, stage: stage)
            hostingController.rootView = AnyView(petView)
            print("🐾 FloatingPetController: Updated pet to \(species) stage \(stage)")
        }
    }
    
    @objc private func update() {
        guard let hostingView = petHostingController?.view else { return }
        
        let screenWidth = UIScreen.main.bounds.width
        let islandWidth = DeviceInfo.dynamicIslandWidth
        let islandStartX = (screenWidth - islandWidth) / 2
        let islandEndX = islandStartX + islandWidth
        let viewWidth = hostingView.frame.width
        
        // Move pet horizontally along the top of the island
        petX += velocityX
        
        // Bounce at island edges
        let leftBound = islandStartX + 4
        let rightBound = islandEndX - viewWidth - 4
        
        if petX <= leftBound {
            petX = leftBound
            velocityX = abs(velocityX)
            flipPet(facingRight: true)
        }
        if petX >= rightBound {
            petX = rightBound
            velocityX = -abs(velocityX)
            flipPet(facingRight: false)
        }
        
        // Update position (keep Y constant)
        var frame = hostingView.frame
        frame.origin.x = petX
        hostingView.frame = frame
    }
    
    private func flipPet(facingRight: Bool) {
        guard let hostingView = petHostingController?.view else { return }
        
        UIView.animate(withDuration: 0.15) {
            hostingView.transform = facingRight ? .identity : CGAffineTransform(scaleX: -1, y: 1)
        }
    }
}

// MARK: - Passthrough Window

class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Pass all touches through — pet is not interactive
        return nil
    }
}

// MARK: - Floating Pet SwiftUI View

struct FloatingPetView: View {
    let species: Species
    let stage: Int
    
    var body: some View {
        MiniPixelPet(species: species, stage: stage, scale: 2.5)
    }
}
