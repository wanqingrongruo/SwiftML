# Swift 中的机器学习
## 机器学习
机器学习是一门人工智能的科学。它通过对经验、数据进行分析，来改进现有的计算机算法，优化现有的程序性能
模拟人类学习的过程
流程: 数据 -> 学习算法learning algorithm -> Model
关于数据: 不是简单的收集 => 认识客观数据、组织原始数据记录，去除数据记录中的噪音
数据收集:  
几个 开放数据库:
* [UCI Machine Learning Repository](http://archive.ics.uci.edu/ml/index.php)
* [Kaggle: Your Home for Data Science](https://www.kaggle.com)
* [Registry of Open Data on AWS](https://registry.opendata.aws)

![](Swift%20%E4%B8%AD%E7%9A%84%E6%9C%BA%E5%99%A8%E5%AD%A6%E4%B9%A0/IMG_0155.PNG)

## 时间轴
* iOS5 引入 `NSLinguisticTagger` 来分析自然语言
* iOS8  引入 `Metal` 提供了对设备 GPU 底层访问接口, 用来替代越越臃肿的 open gl, 发挥自家 CPU GPU 优势
* 2016年, 在 [Accelerate](https://developer.apple.com/documentation/accelerate) 框架中(一个大规模数学,计算图像计算, 针对高性能进行优化的框架) 添加 `BNNS` 帮助开发人员能够构建用于推理的神经网络.
* 2017 WWDC, 推出 CoreML 和 Vision. 其中 CoreML 便于开发者在应用中使用 训练的模型;  Vision 使开发者可以轻松访问 Apple 的模型，以检测面部、面部标记、文本、矩形、条形码和对象。
* 2018 WWDC, 继续完善 CoreML, 从 2017 支持的 6 个框架(第三方)增加到 11 个, 包括了最知名的 TensorFlow、IBM Watson. [Session 703 - Introducing Create ML - WWDC 2018 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2018/703/)
* 2019 WWDC,  CoreML 3.0 [Core ML 3 Framework - WWDC 2019 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2019/704/),  更好的 Vision [Understanding Images in Vision Framework - WWDC 2019 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2019/222/)
*官方 ViewModels [Machine Learning - Apple Developer](https://developer.apple.com/machine-learning/)
Eg. 
CoreML:  本地模型个性化, 神经网络的优化和支持, 性能优化
Vision: 图片重点区域(saliency) => 基于注意力和基于物体.  

##  CoreML
* `Core ML` 的底层是 `Accelerate BNNS`(文字) 和 `MPS`(Metal Performance shaders 处理图片)，并可以根据实际情况进行无缝切换
* 支持导入机器学习模型， 并生成对应高级代码

![](Swift%20%E4%B8%AD%E7%9A%84%E6%9C%BA%E5%99%A8%E5%AD%A6%E4%B9%A0/FullSizeRender.jpg)



### Vision： 图片分析
* 人脸检测：支持检测笑脸、侧脸、局部遮挡脸部、戴眼镜和帽子等场景，可以标记出人脸的矩形区域
* 人脸特征点：可以标记出人脸和眼睛、眉毛、鼻子、嘴、牙齿的轮廓，以及人脸的中轴线
* 图像相似度
* 矩形检测
* 二维码/条形码检测
* 文字检测
* 目标跟踪：脸部，矩形和通用模板
* 图片分类

#### 操作分类
1. 分析图片:  model/image/url -> request -> handler -> Observation
2. 跟踪队列: Observation -> VNTrackObjectRequest -> handler -> Observation
1 的结果作为 2 的输入


### NLP（Nature Language Processing ）： 自然语言分析  [WWDC 2017/208]( https://developer.apple.com/videos/play/wwdc2017/208/)  [译文](https://xiaozhuanlan.com/topic/1570264893)
* 文字输入（typed）
* 文字识别（recognized handwriting）
* 语音输入转换（transcribed speech）
* etc.
* 通过 `NSLingusticTagger` 使用
![](Swift%20%E4%B8%AD%E7%9A%84%E6%9C%BA%E5%99%A8%E5%AD%A6%E4%B9%A0/IMG_0154.PNG)

[Natural Language Processing on iOS with Turi Create | raywenderlich.com](https://www.raywenderlich.com/5213-natural-language-processing-on-ios-with-turi-create)

### 模型转换 [Coremltools](https://pypi.python.org/pypi/coremltools)


### CoreML 更高效, Vision 可为 CoreML 提供 图片处理流程
## 应用-实现将人头像显示在UIImgaview 中间
1. 思路： kingfisher 获取图片 - 开启 头像识别， 识别到头像区域剪裁图片， 替换 kingfisher 缓存的数据 - 显示 数据 - 下次读取缓存数据
VIsion -> `VNDetectFaceRectanglesRequest` -> [VNFaceObservation] -> [observation.boundingBox]


#学习/Swift/机器学习