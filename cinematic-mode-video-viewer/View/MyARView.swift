//
//  MyARView.swift
//  cinematic-mode-video-viewer
//
//  Created by fuziki on 2024/02/12.
//

import Combine
import Cinematic
import Foundation
import RealityKit
import SwiftUI

struct MyARViewContainer: UIViewRepresentable {
    let asset: AVAsset
    let rot: AnyPublisher<(pitch: Float, yaw: Float), Never>
    let far: AnyPublisher<Float, Never>

    func makeUIView(context: Context) -> MyARView {
        let arView = MyARView(asset: asset, rot: rot, far: far)
        Task {
            await arView.start()
        }
        return arView
    }

    func updateUIView(_ arView: MyARView, context: Context) {}
}

@MainActor
class MyARView: ARView {
    let asset: AVAsset
    let rot: AnyPublisher<(pitch: Float, yaw: Float), Never>
    let far: AnyPublisher<Float, Never>

    let cinematicMaterial: CustomMaterial
    let planeEntity: ModelEntity
    let perspectiveCamera: PerspectiveCamera

    var cancellables: Set<AnyCancellable> = []

    let displayLink = DisplayLink()
    var cinematicVideoReader: CinematicVideoReader?

    init(asset: AVAsset, rot: AnyPublisher<(pitch: Float, yaw: Float), Never>, far: AnyPublisher<Float, Never>) {
        self.asset = asset
        self.rot = rot
        self.far = far

        // CinematicMaterial
        let lib = MTLCreateSystemDefaultDevice()!.makeDefaultLibrary()!
        let baseMaterial = SimpleMaterial()
        let surface = CustomMaterial.SurfaceShader(named: "surface", in: lib)
        let geometry = CustomMaterial.GeometryModifier(named: "geometry", in: lib)
        var cinematicMaterial = try! CustomMaterial(from: baseMaterial, surfaceShader: surface, geometryModifier: geometry)
        cinematicMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.0))
        cinematicMaterial.specular = .init(floatLiteral: 0)

        let renderer = ImageRenderer(content: Color.black)
        renderer.proposedSize = .init(width: 1920, height: 1080)
        let baseColorTex = CustomMaterial.Texture(try! TextureResource.generate(from: renderer.cgImage!, options: .init(semantic: nil)))
        cinematicMaterial.baseColor.texture = baseColorTex

        renderer.proposedSize = .init(width: 320, height: 180)
        let customTex = CustomMaterial.Texture(try! TextureResource.generate(from: renderer.cgImage!, options: .init(semantic: nil)))
        cinematicMaterial.custom.texture = customTex

        self.cinematicMaterial = cinematicMaterial

        // Plane
        let mesh = MeshResource.generatePlane(width: 3.2, height: 1.18, segmentWidth: 320, segmentHeight: 180)
        planeEntity = ModelEntity(mesh: mesh, materials: [cinematicMaterial])

        // Camera
        perspectiveCamera = PerspectiveCamera()
        perspectiveCamera.camera.fieldOfViewInDegrees = 30
        perspectiveCamera.look(at: .zero, from: [0, 0, 4], relativeTo: nil)

        super.init(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: true)

        // Environment
        environment.background = .color(.lightGray)

        // WorldAnchor
        let worldAnchor = AnchorEntity(world: .zero)
        worldAnchor.addChild(planeEntity)
        worldAnchor.addChild(perspectiveCamera)
        scene.anchors.append(worldAnchor)

        rot.sink { [weak self] (pitch: Float, yaw: Float) in
            self?.planeEntity.transform = .init(pitch: pitch, yaw: yaw, roll: 0)
        }.store(in: &cancellables)

        far.sink { [weak self] far in
            self?.perspectiveCamera.look(at: .zero, from: [0, 0, far], relativeTo: nil)
        }.store(in: &cancellables)

        displayLink.callback = { [weak self] in
            guard let frame = self?.cinematicVideoReader?.copyNextFrame() else { return }
            try! self?.cinematicMaterial.baseColor.texture!.resource.replace(withImage: frame.video, options: .init(semantic: nil))
            try! self?.cinematicMaterial.custom.texture!.resource.replace(withImage: frame.disparity, options: .init(semantic: nil))
        }
    }

    @MainActor required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink.stop()
    }

    func start() async {
        cinematicVideoReader = await CinematicVideoReader(asset: asset)
        displayLink.start()
    }
}
