//
//  ViewController.swift
//  Portrait
//
//  Created by Rina Kotake on 2018/12/01.
//  Copyright © 2018年 koooootake. All rights reserved.
//

import UIKit
import CropViewController
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate {

    let kGradientLayerName = "Gradient"

    var viewModel: ViewModel = ViewModel()

    //base
    @IBOutlet weak var imageSizeLabel: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var sourceImageView: UIImageView!

    //segment
    private var selectedRect: CGRect?
    @IBOutlet weak var maskImageView: UIImageView!
    @IBOutlet weak var drawImageView: DrawView!
    @IBOutlet weak var drawPenSizeSlider: UISlider!

    //result
    private var resultImage: UIImage?
    private var blurWithoutGradientImage: UIImage?
    private var inpaintingImage: UIImage?
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var blurSizeSlider: UISlider!

    //dof
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var gradientAdjustView: UIView!
    private var startPoint: CGPoint?
    private var endPoint: CGPoint?
    private var startView: GradientAdjustPointView?
    private var endView: GradientAdjustPointView?
    private let pointSize = CGSize(width: 50, height: 50)

    //editView
    @IBOutlet weak var indicatorBaseView: UIView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var editView: UIView!
    @IBOutlet var segmentEditView: UIView!
    @IBOutlet var resultEditView: UIView!
    @IBOutlet var dofEditView: UIView!
    @IBOutlet weak var safeAreaView: UIView!

    private lazy var tapFeedbackGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        reload(status: .load)
        setupIndicatorBaseView()
    }

    private func setupIndicatorBaseView() {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        visualEffectView.frame = indicatorBaseView.bounds
        indicatorBaseView.addSubview(visualEffectView)
        indicatorBaseView.layer.cornerRadius = 4
        indicatorBaseView.layer.masksToBounds = true
        indicatorBaseView.bringSubviewToFront(indicatorView)
        indicatorBaseView.alpha = 0
    }

    private func reload(status: ViewModel.Status) {
        viewModel.reload(status: status)
        maskImageView.isHidden = viewModel.isHiddenSegmentView
        drawImageView.isHidden = viewModel.isHiddenSegmentView
        resultImageView.isHidden = viewModel.isHiddenResultImageView
        gradientAdjustView.isHidden = viewModel.isHiddenGradientView
        gradientView.isHidden = viewModel.isHiddenGradientView
        navigationItem.title = viewModel.navigationTitle
        safeAreaView.backgroundColor = viewModel.viewBackgroundColor

        for view in editView.subviews {
            view.removeFromSuperview()
        }

        let editContentView: UIView
        switch status {
        case .load:
            //do nothing
            return
        case .segment:
            editContentView = segmentEditView
        case .result:
            editContentView = resultEditView
        case .dof:
            editContentView = dofEditView
        }

        editView.addSubview(editContentView)
        editView.addConstraintsFitParentView(editContentView)
    }

    private func reset() {
        resetDraw()
        gradientView.layer.sublayers = nil
        reload(status: .load)
    }

    private func resetDraw() {
        drawImageView.reset()
        OpenCVManager.shared()?.resetManager()
    }

    private func startLoading() {
        UIApplication.shared.beginIgnoringInteractionEvents()
        indicatorView.startAnimating()
        indicatorBaseView.isHidden = false
        UIView.animate(withDuration: 0.1, animations: {
            self.indicatorBaseView.alpha = 1
        })
    }

    private func stopLoading() {
        UIApplication.shared.endIgnoringInteractionEvents()
        UIView.animate(withDuration: 0.3, animations: {
            self.indicatorBaseView.alpha = 0
        }, completion: { _ in
            self.indicatorView.stopAnimating()
            self.indicatorBaseView.isHidden = true
        })
    }
}

///1. 画像取得 + 前景矩形選択
extension ViewController {

    @IBAction func imagePickerButtonDidTap(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerC = UIImagePickerController()
            pickerC.sourceType = .photoLibrary
            pickerC.delegate = self
            present(pickerC, animated: true, completion: nil)
        } else {
            UIAlertController.show(title: "フォトライブラリの利用が許可されていません🌃", message: nil)
        }
    }

    @IBAction func cropButtonDidTap(_ sender: Any) {
        guard let img = sourceImageView.image else {
            assertionFailure()
            return
        }
        showCropViewController(image: img)
    }

    private func showCropViewController(image: UIImage) {
        let cropVC = CropViewController(image: image)
        cropVC.rotateButtonsHidden = true
        cropVC.title = "Rough outline of the subject"
        cropVC.delegate = self
        if let selectedRect = selectedRect {
            cropVC.imageCropFrame = selectedRect
        } else {
            cropVC.aspectRatioPreset = .presetSquare
        }
        present(cropVC, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            assertionFailure()
            return
        }
        //画像サイズ縮小
        let maxSize: CGFloat = 1800
        let imageMaxSize = max(image.size.width, image.size.height)
        let scale = imageMaxSize > maxSize ? maxSize / imageMaxSize : 1
        let resizeImg = image.scale(ratio: scale)
        sourceImageView.image = resizeImg
        imageSizeLabel.text = "\(Int(resizeImg.size.width)) x \(Int(resizeImg.size.height))"
        selectedRect = nil
        reset()
        self.dismiss(animated: true, completion: {
            self.showCropViewController(image: resizeImg)
        })
    }

}

extension ViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropImageToRect rect: CGRect, angle: Int) {
        selectedRect = rect
        resetDraw()
        startLoading()
        cropViewController.dismiss(animated: true, completion: {
            self.doGrabCut()
            self.stopLoading()
        })
    }
}

///2. 矩形でGrabCutする
extension ViewController {
    private func doGrabCut() {
        maskImageView.image = doGrabCutWithRect()
        reload(status: .segment)
    }

    private func doGrabCutWithRect() -> UIImage? {
        guard let img = sourceImageView.image else {
            assertionFailure()
            return nil
        }

        //矩形取得
        let rect: CGRect
        if let selectedR = selectedRect {
            if selectedR.size == img.size {//矩形が画像と同じサイズのとき僅かに小さくして入力
                rect = CGRect(origin: CGPoint(x: selectedR.origin.x + 1, y: selectedR.origin.y + 1), size: CGSize(width: selectedR.size.width - 2, height: selectedR.size.height - 2))
            } else {
                rect = selectedR
            }
        } else {
            rect = CGRect(origin: CGPoint(x: 1, y: 1), size: CGSize(width: img.size.width - 2, height: img.size.height - 2))
        }

        return OpenCVManager.shared()?.doGrabCut(img, foregroundRect: rect, iterationCount: 1)
    }
}

///3.マスクでGrabCutする
extension ViewController {
    private func doGrabCutWithMask() {
        guard let img = sourceImageView.image else {
            assertionFailure()
            return
        }
        startLoading()

        if let drawImg = drawImageView.image, let markersImg = cropInsideRectAndResize(image: drawImg, size: img.size) {
            DispatchQueue.global(qos: .default).async {
                let mask = OpenCVManager.shared()?.doGrabCut(img, markersImage: markersImg, iterationCount: 1)
                DispatchQueue.main.async {
                    self.stopLoading()
                    self.maskImageView.image = mask
                }
            }
        } else {
            stopLoading()
        }
    }

    ///UIImageのSizeにクロップ & リサイズ
    private func cropInsideRectAndResize(image: UIImage, size: CGSize) -> UIImage? {
        let frame = AVMakeRect(aspectRatio: size, insideRect: sourceImageView.bounds)
        if let cropImg = image.cropping(to: frame) {
            return cropImg.resize(size: size)
        }
        return nil
    }

    @IBAction func drawPenSizeSliderValueChanged(_ sender: Any) {
        drawImageView.penSize = CGFloat(drawPenSizeSlider.value)
    }

    @IBAction func drawColorSegmentedDidChangeValue(_ sender: Any) {
        guard let segumented = sender as? UISegmentedControl else {
            assertionFailure()
            return
        }
        switch segumented.selectedSegmentIndex {
        case 0:
            drawImageView.penColor = UIColor.white
        case 1:
            drawImageView.penColor = UIColor.black
        default:
            assertionFailure()
        }
    }

    @IBAction func segmentEditDoButtonDidTap(_ sender: Any) {
        doGrabCutWithMask()
    }

    @IBAction func segmentEditDoneButtonDidTap(_ sender: Any) {
        updateBlur(blurSize: blurSizeSlider.value, isUpdatedSegmentation: true)
    }
}

///4.ボカス
extension ViewController {

    @IBAction func blurSizeSliderTouchUpInside(_ sender: Any) {
        updateBlur(blurSize: blurSizeSlider.value)
    }

    @IBAction func blurSizeSliderTouchUpOutside(_ sender: Any) {
        updateBlur(blurSize: blurSizeSlider.value)
    }

    private func updateBlur(blurSize: Float, isUpdatedSegmentation: Bool = false) {
        guard let img = sourceImageView.image else {
            assertionFailure()
            return
        }
        startLoading()
        //blurSizeが画像sizeに比例しつつ奇数になるように調節
        let length = max(img.size.width, img.size.height)
        var val = length / 1500 * CGFloat(blurSize)
        if Int(val) % 2 == 0 { val += 1 }

        let layerImg = makeGradientLayerImage()
        DispatchQueue.global(qos: .default).async {
            let resultImg = OpenCVManager.shared()?.doBlur(CGFloat(val), isUpdatedSegmentation: isUpdatedSegmentation, gradientMaskImage: layerImg)
            DispatchQueue.main.async {
                self.doneBlur(image: resultImg)
            }
        }
    }

    private func doneBlur(image: UIImage?) {
        stopLoading()
        resultImageView.image = image
        resultImage = image
        inpaintingImage = OpenCVManager.shared()?.inpaintingImage()
        blurWithoutGradientImage = OpenCVManager.shared()?.blurWithoutGradientImage()
        reload(status: .result)
    }

    @objc func showResultOfSaveImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        let title: String
        if let error = error {
            title = "保存に失敗したよ\n\(error.description)"
        } else {
            title = "保存したよ"
        }
        UIAlertController.show(title: title, message: nil)
    }

    @IBAction func compareSourceButtonTouchDown(_ sender: Any) {
        maskImageView.isHidden = true
        drawImageView.isHidden = true
        resultImageView.isHidden = true
    }

    @IBAction func compareSourceButtonTouchUpInside(_ sender: Any) {
        reload(status: .result)
    }

    @IBAction func compareSourceButtonTouchUpOutside(_ sender: Any) {
        reload(status: .result)
    }

    @IBAction func compareInpaintingButtonTouchDown(_ sender: Any) {
        resultImageView.image = inpaintingImage
    }

    @IBAction func compareInpaintingButtonTouchUpInside(_ sender: Any) {
        resultImageView.image = resultImage
    }

    @IBAction func compareInpaintingButtonTouchUpOutside(_ sender: Any) {
        resultImageView.image = resultImage
    }

    @IBAction func compareDOFButtonTouchDown(_ sender: Any) {
        resultImageView.image = blurWithoutGradientImage
    }

    @IBAction func compareDOFButtonTouchUpInside(_ sender: Any) {
         resultImageView.image = resultImage
    }

    @IBAction func compareDOFTouchUpOutside(_ sender: Any) {
         resultImageView.image = resultImage
    }

    @IBAction func editSegmentButtonDidTap(_ sender: Any) {
        reload(status: .segment)
    }

    @IBAction func editDOFButtonDidTap(_ sender: Any) {
        reload(status: .dof)
        setupGradientAdjustView()
        addGradientLayer(startPoint: scalePoint(in: gradientView, pointView: startView!), endPoint: scalePoint(in: gradientView, pointView: endView!))
    }

    @IBAction func saveButtonDidTap(_ sender: Any) {
        guard let img = resultImageView.image else {
            assertionFailure()
            return
        }
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(self.showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }
}

///5. DOF調節
extension ViewController {

    private func makeGradientLayerImage() -> UIImage? {
        guard let img = sourceImageView.image else {
            assertionFailure()
            return nil
        }

        if let layer = gradientView.layer.sublayers?.filter({ $0.name == kGradientLayerName }).first {
            UIGraphicsBeginImageContext(gradientView.frame.size)
            layer.render(in: UIGraphicsGetCurrentContext()!)
            let gradientImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return cropInsideRectAndResize(image: gradientImage, size: img.size)
        }
        return nil
    }

    private func setupGradientAdjustView() {
        guard startView == nil, endView == nil else {
            //do nothing
            return
        }
        startView = GradientAdjustPointView()
        endView = GradientAdjustPointView()

        resetPointPosition()
        startView?.setup(pointType: .start)
        startView?.delegate = self
        endView?.setup(pointType: .end)
        endView?.delegate = self
        gradientAdjustView.addSubview(startView!)
        gradientAdjustView.addSubview(endView!)
    }

    private func resetPointPosition() {
        let defaultX = self.view.frame.width / 2 - pointSize.width / 2
        let defaultY = self.view.frame.height / 2
        startPoint = CGPoint(x: defaultX, y: defaultY - pointSize.width * 2)
        endPoint = CGPoint(x: defaultX, y: defaultY)
        startView?.frame = CGRect(origin: startPoint!, size: pointSize)
        endView?.frame = CGRect(origin: endPoint!, size: pointSize)
    }

    private func addGradientLayer(startPoint: CGPoint?, endPoint: CGPoint?) {
        if let startP = startPoint {
            self.startPoint = startP
        }

        if let endP = endPoint {
            self.endPoint = endP
        }

        let layer = CAGradientLayer()
        layer.colors = [UIColor.black.cgColor, UIColor.white.cgColor]
        layer.frame = CGRect(origin: CGPoint.zero, size: gradientView.frame.size)
        layer.startPoint = self.startPoint!
        layer.endPoint = self.endPoint!
        layer.name = kGradientLayerName
        gradientView.layer.sublayers = nil
        gradientView.layer.addSublayer(layer)
    }

    ///画像の中でpointの位置する比率
    private func scalePoint(in baseView: UIView, pointView: UIView) -> CGPoint {
        return CGPoint(x: (pointView.frame.origin.x + pointView.frame.width / 2) / baseView.frame.width, y: (pointView.frame.origin.y + pointView.frame.height / 2) / baseView.frame.height)
    }

    @IBAction func dofEditResetButtonDidTap(_ sender: Any) {
        resetPointPosition()
        addGradientLayer(startPoint: scalePoint(in: gradientView, pointView: startView!), endPoint: scalePoint(in: gradientView, pointView: endView!))
    }

    @IBAction func dofEditDoneButtonDidTap(_ sender: Any) {
        updateBlur(blurSize: blurSizeSlider.value)
        reload(status: .result)
    }

    @IBAction func dofEditColoseButtonDidTap(_ sender: Any) {
        gradientView.layer.sublayers = nil
        updateBlur(blurSize: blurSizeSlider.value)
        reload(status: .result)
    }
}

extension ViewController: GradientAdjustPointViewDelegate {
    func startViewTouchesMoved(_ view: GradientAdjustPointView, point: CGPoint) {
        addGradientLayer(startPoint: scalePoint(in :gradientView, pointView: view), endPoint: nil)
        if Int(view.frame.origin.x) == Int(endView!.frame.origin.x) || Int(view.frame.origin.y) == Int(endView!.frame.origin.y) {
            tapFeedbackGenerator.impactOccurred()
        }
    }

    func endViewTouchesMoved(_ view: GradientAdjustPointView, point: CGPoint) {
        addGradientLayer(startPoint: nil, endPoint: scalePoint(in: gradientView, pointView: view))
        if Int(view.frame.origin.x) == Int(startView!.frame.origin.x) || Int(view.frame.origin.y) == Int(startView!.frame.origin.y) {
            tapFeedbackGenerator.impactOccurred()
        }
    }
}

extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return baseView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        drawImageView.beginZooming()
    }
}
