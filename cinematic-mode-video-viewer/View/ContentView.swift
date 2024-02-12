//
//  ContentView.swift
//  cinematic-mode-video-viewer
//
//  Created by fuziki on 2024/02/12.
//

import Combine
import SwiftUI
import Photos
import PhotosUI

struct ContentView : View {
    @StateObject var vm = ContentViewModel()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let asset = vm.asset {
                MyARViewContainer(asset: asset, rot: vm.rot.eraseToAnyPublisher(), far: vm.far.eraseToAnyPublisher())
                    .edgesIgnoringSafeArea(.all)
                    .gesture(SimultaneousGesture(magnificationGesture, dragGesture))
                    .id(asset)
            }
            let selection = Binding<PhotosPickerItem?> {
                vm.item
            } set: { newItem in
                vm.onFetch(newItem: newItem)
            }
            PhotosPicker(selection: selection,
                         matching: .cinematicVideos,
                         photoLibrary: .shared()) {
                Label("Select Cinematic Video", systemImage: "photo")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.lightGray).ignoresSafeArea())
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { (value: DragGesture.Value) in
                vm.onChangedDrag(value: value)
            }
            .onEnded { (value: DragGesture.Value) in
                vm.onEndedDrag(value: value)
            }
    }

    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { (value: MagnificationGesture.Value) in
                vm.onChangedMagnification(value: value)
            }
            .onEnded { (value: MagnificationGesture.Value) in
                vm.onEndedMagnification(value: value)
            }
    }
}

@MainActor
class ContentViewModel: ObservableObject {
    @Published private(set) var item: PhotosPickerItem?
    @Published private(set) var asset: AVAsset?

    private var storeRot: (pitch: Float, yaw: Float) = (pitch: 0, yaw: 0)
    let rot = CurrentValueSubject<(pitch: Float, yaw: Float), Never>((pitch: 0, yaw: 0))

    private var storeFar: Float = 4
    let far = CurrentValueSubject<Float, Never>(4)

    func onFetch(newItem: PhotosPickerItem?) {
        PHPhotoLibrary.requestAuthorization { _ in
            guard let itemIdentifier = newItem?.itemIdentifier else { return }
            let phAssets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [itemIdentifier], options: nil)
            let phAsset = phAssets.lastObject!

            let resources = PHAssetResource.assetResources(for: phAsset)
            print("originalFilenames: \(resources.map({ $0.originalFilename }))")

            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = .original
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { [weak self] asset, _, _ in
                DispatchQueue.main.async {
                    self?.asset = asset
                }
            }
        }
    }

    func onChangedDrag(value: DragGesture.Value) {
        rot.send(toRot(from: value))
    }

    func onEndedDrag(value: DragGesture.Value) {
        rot.send(toRot(from: value))
        storeRot = rot.value
    }

    func onChangedMagnification(value: MagnificationGesture.Value) {
        far.send(storeFar / Float(value))
    }

    func onEndedMagnification(value: MagnificationGesture.Value) {
        far.send(storeFar / Float(value))
        storeFar = far.value
    }

    func toRot(from value: DragGesture.Value) -> (pitch: Float, yaw: Float) {
        (pitch: storeRot.pitch + Float(value.translation.height) * .pi / 180, yaw: storeRot.yaw + Float(value.translation.width) * .pi / 180)
    }
}
