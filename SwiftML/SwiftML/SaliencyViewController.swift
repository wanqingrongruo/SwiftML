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

        languageTagger()
        tokenization()
        partOfSpeech()
        lemmatization()
        entityRecognzation()
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
        guard let image = selectedImage else {
            print("wdf, 没图片")
            return
        }

        guard let ciImage = CIImage(image: image) else {
            return
        }

        if #available(iOS 13.0, *) {
            let faceRectanglesRequest = VNGenerateAttentionBasedSaliencyImageRequest { (request, error) in
                guard error == nil else {
                    print("\(error!.localizedDescription)")
                    return
                }

                // 只有一个重点数据
                guard let faceObservation = request.results?.first as? VNSaliencyImageObservation, let rect = faceObservation.salientObjects?.first else { return }

                let faceRect = self.convertRect(with: rect.boundingBox, and: image)

                let view = self.addRectangleView(rect: faceRect)
                DispatchQueue.main.async {
                    self.imageView.addSubview(view)
                }
            }

            faceRectanglesRequest.revision = VNGenerateAttentionBasedSaliencyImageRequestRevision1

            let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])

            DispatchQueue.main.async {
                do {
                    try requestHandler.perform([faceRectanglesRequest])
                } catch {
                    print("\(error.localizedDescription)")
                }
            }
        } else {
            // Fallback on earlier versions
        }

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

// MARK: - NLP
extension SaliencyViewController {
    // 语言识别
    func languageTagger() {
        print("========语言识别==========")
        let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        tagger.string = "王德发"
        if let language = tagger.dominantLanguage {
            print("当前语言: \(language)")
        }
    }

    // 切分
    func tokenization() {
        print("========文本切分==========")
        let text = "机器学习是什么?"
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = text

        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { tag, tokenRange, stop in
            let token = (text as NSString).substring(with: tokenRange)
            print("====\(token)")
        }
    }

    // 词性
    func partOfSpeech() {
        print("========词性分析==========")
        let schemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let tagger = NSLinguisticTagger(tagSchemes: schemes, options: 0)
        let text = "My name is roni."
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)

        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameTypeOrLexicalClass, options: options) { (tag, tokenRange, stop) in
            guard let tag = tag else { return }
            let token = (text as NSString).substring(with: tokenRange)
            print(token + ": " + tag.rawValue)
        }
    }

    // 词形还原
    func lemmatization() {
        print("========词形还原==========")
        let tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
        let text = "My name is roni."
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { (tag, tokenRange, stop) in
            let token = (text as NSString).substring(with: tokenRange)
            guard let lemma = tag?.rawValue, lemma != token else {
                return
            }
            print(token + ": " + lemma)
        }

        print("========华丽分割线==========")
    }

    // 实体识别
    func entityRecognzation() {
        print("========实体识别==========")
        let schemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let tagger = NSLinguisticTagger(tagSchemes: schemes, options: 0)
        let text = "China is number one."
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        // 列举实体种类
        let tags: [NSLinguisticTag] = [.personalName, .placeName, .organizationName, .number, .otherWord]

        tagger.enumerateTags(in: range, unit: .word, scheme: .nameTypeOrLexicalClass, options: options) { (tag, tokenRange, stop) in
            guard let tag = tag, tags.contains(tag) else { return }
            let token = (text as NSString).substring(with: tokenRange)
            print(token + ": " + tag.rawValue)
        }
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
