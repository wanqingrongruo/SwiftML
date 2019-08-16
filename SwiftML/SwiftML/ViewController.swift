//
//  ViewController.swift
//  SwiftML
//
//  Created by roni on 2019/8/16.
//  Copyright © 2019 roni. All rights reserved.
//

import UIKit
import CoreMedia
import Vision

class ViewController: UIViewController {
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var predictResultLabel: UILabel!
    @IBOutlet weak var visionSwitch: UISwitch!


    private let inceptionV3Model = Inceptionv3()
    private var videoCapture: VideoCapture!
    private var requests = [VNRequest]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVision()

        let spec = VideoSpec(fps: 5, size: CGSize(width: 299, height: 299))
        videoCapture = VideoCapture(captureType: .back, preferredSpec: spec, previewContainer: previewView.layer)
        videoCapture.imageBufferHandler = { [weak self] imageBuffer in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                if self.visionSwitch.isOn {
                    self.handleImageBufferWithVision(imageBuffer)
                } else {
                    self.handleImageBufferWithCoreML(imageBuffer)
                }
            }

        }
    }

    func handleImageBufferWithCoreML(_ imageBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer), let resizeBuffer = resize(pixelBuffer: pixelBuffer) else { return }
        do {
            let predition = try inceptionV3Model.prediction(image: resizeBuffer)
            DispatchQueue.main.async {
                if let prob = predition.classLabelProbs[predition.classLabel] {
                    self.predictResultLabel.text = String(format: "%@ %@", predition.classLabel, prob)
                }
            }
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription).")
        }
    }

    func handleImageBufferWithVision(_ imageBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer) else { return }

        var requestOptions = [VNImageOption: Any]()
        if let cameraIntrinsicData = CMGetAttachment(imageBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: UInt32(self.exifOrientationFromDeviceOrientation))!, options: requestOptions)

        do {
            try imageRequestHandler.perform(requests)
        }
        catch {
            print(error)
        }
    }

    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: inceptionV3Model.model) else {
            fatalError("can not load Vision ML Model")
        }

        let request = VNCoreMLRequest(model: visionModel) { (request, error) in
            guard let results = request.results else {
                print("wtf")
                return
            }

            let processResult = results.compactMap { $0 as? VNClassificationObservation }
                .filter { $0.confidence > 0.2 }
                .map { "\($0.identifier) \($0.confidence)" }

            DispatchQueue.main.async {
                self.predictResultLabel.text = processResult.joined(separator: "\n")
            }
        }

        request.imageCropAndScaleOption = .centerCrop
        self.requests = [request]
    }

    /// only support back camera
    var exifOrientationFromDeviceOrientation: Int32 {
        let exifOrientation: DeviceOrientation
        enum DeviceOrientation: Int32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = .top0ColLeft
        case .landscapeRight:
            exifOrientation = .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }


    /// resize CVPixelBuffer
    ///
    /// - Parameter pixelBuffer: CVPixelBuffer by camera output
    /// - Returns: CVPixelBuffer with size (299, 299)
    func resize(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let imageSide = 299
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        let transform = CGAffineTransform(scaleX: CGFloat(imageSide) / CGFloat(CVPixelBufferGetWidth(pixelBuffer)), y: CGFloat(imageSide) / CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        ciImage = ciImage.transformed(by: transform).cropped(to: CGRect(x: 0, y: 0, width: imageSide, height: imageSide))
        let ciContext = CIContext()
        var resizeBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, imageSide, imageSide, CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &resizeBuffer)
        ciContext.render(ciImage, to: resizeBuffer!)
        return resizeBuffer
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let videoCapture = videoCapture else {return}
        videoCapture.resizePreview()
    }

    override func viewWillDisappear(_ animated: Bool) {
        guard let videoCapture = videoCapture else {return}
        videoCapture.stopCapture()

        super.viewWillDisappear(animated)
    }

}

