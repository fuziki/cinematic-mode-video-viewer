//
//  CinematicVideoReader.swift
//  cinematic-mode-video-viewer
//
//  Created by fuziki on 2024/02/12.
//

import Cinematic
import CoreImage
import Foundation

class CinematicVideoReader {
    let asset: AVAsset
    let naturalTimeScale: CMTimeScale

    let assetReader: AVAssetReader
    let videoTrackOutput: AVAssetReaderTrackOutput
    let disparityTrackOutput: AVAssetReaderTrackOutput

    let kernel: CIColorKernel
    let context = CIContext()

    init(asset: AVAsset) async {
        self.asset = asset
        naturalTimeScale = try! await asset.loadTracks(withMediaType: .video).first!.load(.naturalTimeScale)

        assetReader = try! AVAssetReader(asset: asset)
        let assetInfo: CNAssetInfo = try! await CNAssetInfo(asset: asset)

        let videoOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any]()
        ]
        videoTrackOutput = AVAssetReaderTrackOutput(track: assetInfo.cinematicVideoTrack, outputSettings: videoOutputSettings)
        videoTrackOutput.alwaysCopiesSampleData = false
        assetReader.add(videoTrackOutput)

        let disparityOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_DisparityFloat16]
        ]
        disparityTrackOutput = AVAssetReaderTrackOutput(track: assetInfo.cinematicDisparityTrack, outputSettings: disparityOutputSettings)
        disparityTrackOutput.alwaysCopiesSampleData = false
        assetReader.add(disparityTrackOutput)

        assetReader.startReading()

        let url = Bundle.main.url(forResource: "kernel", withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        kernel = try! CIColorKernel(functionName: "grayscale", fromMetalLibraryData: data, outputPixelFormat: .RGBAf)
    }

    func copyNextFrame() -> (video: CGImage, disparity: CGImage)? {
        guard let videoSampleBuffer = videoTrackOutput.copyNextSampleBuffer(),
              let disparitySampleBuffer = disparityTrackOutput.copyNextSampleBuffer() else { return nil }

        let ciVideo = CIImage(cvPixelBuffer: videoSampleBuffer.imageBuffer!)
            .transformed(by: CGAffineTransform(rotationAngle: .pi))
        let cgVideo = context.createCGImage(ciVideo, from: ciVideo.extent)!

        let ciDisparity = CIImage(cvPixelBuffer: disparitySampleBuffer.imageBuffer!)
            .transformed(by: CGAffineTransform(rotationAngle: .pi))
        let ciGrayScaledDisparity = kernel.apply(extent: ciDisparity.extent, arguments: [ciDisparity])!
        let cgGrayScaledDisparity = context.createCGImage(ciGrayScaledDisparity, from: ciGrayScaledDisparity.extent)!

        return (video: cgVideo, disparity: cgGrayScaledDisparity)
    }
}
