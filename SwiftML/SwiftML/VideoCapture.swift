//
//  VideoCapture.swift
//  SwiftML
//
//  Created by roni on 2019/8/16.
//  Copyright © 2019 roni. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

enum VideoCaptureType {
    case back
    case font

    func captureDevice() -> AVCaptureDevice {
        switch self {
        case .font:
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [], mediaType: .video, position: .front).devices
            for device in devices where device.position == .front {
                return device
            }
        default:
            break
        }

        return AVCaptureDevice.default(for: .video)!
    }
}

struct VideoSpec {
    var fps: Int32?
    var size: CGSize?
}

typealias ImageBufferHandler = (_ imageBuffer: CMSampleBuffer) -> Void

class VideoCapture: NSObject {
    private let captureSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice
    private var videoConnection: AVCaptureConnection!
    private var previewLayer: AVCaptureVideoPreviewLayer?

    var imageBufferHandler: ImageBufferHandler?

    init(captureType: VideoCaptureType) {
        captureDevice = captureType.captureDevice()
        super.init()

        configSessionPreset()
        configVideoInput()
        configVideoConnection()
    }

    convenience init(captureType: VideoCaptureType, preferredSpec: VideoSpec?, previewContainer: CALayer?) {
        self.init(captureType: captureType)

        if let preferredSpec = preferredSpec {
            captureDevice.updateFormatWithPreferredVideoSpec(preferredSpec: preferredSpec)
        }

        if let previewContainer = previewContainer {
            configPreview(previewContainer)
        }
    }

    func startCapture() {
        if captureSession.isRunning { return }
        captureSession.startRunning()
    }

    func stopCapture() {
        if !captureSession.isRunning { return }
        captureSession.stopRunning()
    }

    func resizePreview() {
        if let previewLayer = previewLayer, let superLayer = previewLayer.superlayer {
            previewLayer.frame = superLayer.bounds
        }
    }

    private func configSessionPreset() {
        captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
    }

    private func configVideoInput() {
        let videoDeviceInput: AVCaptureDeviceInput
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
        }
        catch let error {
            fatalError(error.localizedDescription)
        }

        guard captureSession.canAddInput(videoDeviceInput) else {
            fatalError("wtf, i can add input")
        }
        captureSession.addInput(videoDeviceInput)
    }

    private func configVideoConnection() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        let queue = DispatchQueue(label: "com.roni.swiftml")
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)

        guard captureSession.canAddOutput(videoDataOutput) else {
            fatalError("I need wtf, give me device authorization")
        }
        captureSession.addOutput(videoDataOutput)
        videoConnection = videoDataOutput.connection(with: .video)
    }

    private func configPreview(_ previewContainer: CALayer) {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = previewContainer.bounds
        previewLayer.contentsGravity = .resizeAspectFill
        previewLayer.videoGravity = .resizeAspectFill
        previewContainer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        imageBufferHandler?(sampleBuffer)
//    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        imageBufferHandler?(sampleBuffer)
    }
}


extension AVCaptureDevice {
    private func availableFormatsFor(preferredFps: Float64) -> [AVCaptureDevice.Format] {
        var availableFormats: [AVCaptureDevice.Format] = []
        for format in formats
        {
            let ranges = format.videoSupportedFrameRateRanges
            for range in ranges where range.minFrameRate <= preferredFps && preferredFps <= range.maxFrameRate
            {
                availableFormats.append(format)
            }
        }
        return availableFormats
    }

    private func formatWithHighestResolution(_ availableFormats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format?
    {
        var maxWidth: Int32 = 0
        var selectedFormat: AVCaptureDevice.Format?
        for format in availableFormats {
            let desc = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
            let width = dimensions.width
            if width >= maxWidth {
                maxWidth = width
                selectedFormat = format
            }
        }
        return selectedFormat
    }

    private func formatFor(preferredSize: CGSize, availableFormats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format?
    {
        for format in availableFormats {
            let desc = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(desc)

            if dimensions.width >= Int32(preferredSize.width) && dimensions.height >= Int32(preferredSize.height)
            {
                return format
            }
        }
        return nil
    }

    func updateFormatWithPreferredVideoSpec(preferredSpec: VideoSpec)
    {
        let availableFormats: [AVCaptureDevice.Format]
        if let preferredFps = preferredSpec.fps {
            availableFormats = availableFormatsFor(preferredFps: Float64(preferredFps))
        }
        else {
            availableFormats = formats
        }

        var selectedFormat: AVCaptureDevice.Format?
        if let preferredSize = preferredSpec.size {
            selectedFormat = formatFor(preferredSize: preferredSize, availableFormats: availableFormats)
        } else {
            selectedFormat = formatWithHighestResolution(availableFormats)
        }
        print("selected format: \(String(describing: selectedFormat))")

        if let selectedFormat = selectedFormat {
            do {
                try lockForConfiguration()

                activeFormat = selectedFormat

                if let preferredFps = preferredSpec.fps {
                    activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: preferredFps)
                    activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: preferredFps)
                    unlockForConfiguration()
                }
            }
            catch let error {
                fatalError(error.localizedDescription)
            }
        }
    }
}
