//
//  SaliencyViewController.swift
//  SwiftML
//
//  Created by roni on 2019/8/19.
//  Copyright © 2019 roni. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

let kScreenWidth = UIScreen.main.bounds.size.width
let kScreenHeight = UIScreen.main.bounds.size.height

class SaliencyViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    private var selectedImage: UIImage?
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func cleanAction(_ sender: Any) {
        let subviews = imageView.subviews
        subviews.forEach { $0.removeFromSuperview() }
    }

    func browsePhotoLibrary(){
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            print("不给你看, 滚!")
            return
        }

        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }

    // iOS 13
    @IBAction func saliencyRecognize(_ sender: Any) {
//        guard let image = selectedImage else {
//            print("wdf, 没图片")
//            return
//        }
//
//        guard let ciImage = CIImage(image: image) else {
//            return
//        }
//
//        let faceRectanglesRequest = VNGenerateAttentionBasedSaliencyImageRequest { (request, error) in
//            guard error == nil else {
//                print("\(error!.localizedDescription)")
//                return
//            }
//
//            // 只有一个重点数据
//            guard let faceObservation = request.results.first as? VNSaliencyImageObservation else { return }
//
//            let faceRect = self.convertRect(with: faceObservation.boundingBox, and: image)
//
//            let view = self.addRectangleView(rect: faceRect)
//            DispatchQueue.main.async {
//                self.imageView.addSubview(view)
//            }
//        }
//        request.revision = VNGenerateAttentionBasedSaliencyImageRequestRevision1
//
//        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
//
//        DispatchQueue.main.async {
//            do {
//                try requestHandler.perform([faceRectanglesRequest])
//            } catch {
//                print("\(error.localizedDescription)")
//            }
//        }
    }
    
    @IBAction func recognize(_ sender: Any) {
        guard let image = selectedImage else {
            print("wdf, 没图片")
            return
        }

        guard let ciImage = CIImage(image: image) else {
            return
        }

        let faceRectanglesRequest = VNDetectFaceRectanglesRequest { (request, error) in
            guard error == nil else {
                print("\(error!.localizedDescription)")
                return
            }

            guard let faceObservation = request.results as? [VNFaceObservation] else { return }

            let faceRects = faceObservation.map({ (observation) -> CGRect in
                return self.convertRect(with: observation.boundingBox, and: image)
            })
            faceRects.forEach({ (rect) in
                let view = self.addRectangleView(rect: rect)
                DispatchQueue.main.async {
                    self.imageView.addSubview(view)
                }
            })
        }

        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        DispatchQueue.main.async {
            do {
                try requestHandler.perform([faceRectanglesRequest])
            } catch {
                print("\(error.localizedDescription)")
            }
        }
    }


    /// 转换坐标
    ///
    /// - Parameters:
    ///   - boundingBox: 识别到的坐标, 以左下角为坐标原点的, 介于 [0,1]
    ///   - image: 当前识别图片
    /// - Returns: 相对于图片的坐标
    func convertRect(with boundingBox: CGRect, and image: UIImage) -> CGRect {
        let scale = image.scale
        let imageHeight = kScreenWidth / scale
        let width = boundingBox.width * kScreenWidth
        let height = boundingBox.height * imageHeight
        let originX = boundingBox.minX * kScreenWidth
        let originY = (1 - boundingBox.minY) * imageHeight - height
        return CGRect(x: originX, y: originY, width: width, height: height)
    }


    /// 为识别出来的区域做标记
    ///
    /// - Parameters:
    ///   - rect: 位置
    ///   - position: 摄像头位置, 坐标是以后摄像头为标准的, 前摄像头在后摄像头的基础上翻转了180度
    /// - Returns:  view
    func addRectangleView(rect: CGRect, position: AVCaptureDevice.Position = .back) -> UIView {
        let x = position == .back ? rect.minX : rect.width - rect.maxX
        let boxView = UIView(frame: CGRect(x: x, y: rect.minY, width: rect.width, height: rect.height))
        boxView.backgroundColor = UIColor.clear
        boxView.layer.borderColor = UIColor.red.cgColor
        boxView.layer.borderWidth = 2
        return boxView
    }

    @IBAction func selectAction(_ sender: UIButton) {
        browsePhotoLibrary()
    }

    @IBAction func dismissAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}

extension SaliencyViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }

        selectedImage = image
        let scale = image.scale
        let height = kScreenWidth / scale
        heightConstraint.constant = height
        heightConstraint.isActive = true
        imageView.image = image

        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
