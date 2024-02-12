//
//  DisplayLink.swift
//  cinematic-mode-video-viewer
//
//  Created by fuziki on 2024/02/12.
//

import Foundation
import UIKit

class DisplayLink: NSObject {
    var callback: (() -> Void)?
    var displayLink: CADisplayLink?

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink(link:)))
        displayLink?.add(to: .main, forMode: .common)
        displayLink?.preferredFrameRateRange = .init(minimum: 30, maximum: 30, preferred: 30)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc func onDisplayLink(link: CADisplayLink) {
        callback?()
    }
}
