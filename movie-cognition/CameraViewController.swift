//
//  CameraViewController.swift
//  movie-cognition
//
//  Created by Tomohiko Kuboyama on 2017/02/07.
//  Copyright © 2017年 Tomohiko Kuboyama. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var detector: CIDetector!
    var maskImage: UIImage!
    var startDate: NSDate!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var videoDisplayView: GLKView!
    var videoDisplayViewRect: CGRect!
    var renderContext: CIContext!
    var cpsSession: AVCaptureSession!
    
    @IBOutlet weak var cameraView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        
        
        captureSession = AVCaptureSession()
        stillImageOutput = AVCapturePhotoOutput()
        
        captureSession.sessionPreset = AVCaptureSessionPreset1920x1080 // 解像度の設定
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            // 入力
            if (captureSession.canAddInput(input)) {
                captureSession.addInput(input)
                
                // 出力
                if (captureSession.canAddOutput(stillImageOutput)) {
                    let myOutput = AVCaptureVideoDataOutput()
                    myOutput.alwaysDiscardsLateVideoFrames = true
                    captureSession.addOutput(stillImageOutput)
                    captureSession.startRunning()
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect // アスペクトフィット
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait // カメラの向き
                    
                    cameraView.layer.addSublayer(previewLayer!)
                    
                    let queue = DispatchQueue.init(label: "myqueue")
                    myOutput.setSampleBufferDelegate(self, queue: queue)
                    captureSession.addOutput(myOutput)
                    
                    previewLayer?.position = CGPoint(x: self.cameraView.frame.width / 2, y: self.cameraView.frame.height / 2)
                    previewLayer?.bounds = cameraView.frame
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    // 毎フレーム実行される処理
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    {
        //print("proceed")
        if (connection.isActive) {
            recognize(image: imageFromSampleBuffer(sampleBuffer: sampleBuffer))
        }
    }
    
    func recognize(image: UIImage){
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        // UIImage から CGImage を作る
        let cgImage = image.cgImage
        // CGImage から CIImage を作る
        let ciImage = CIImage(cgImage: cgImage!)
        
        // 顔検出実行
        var transform = CGAffineTransform(scaleX: 1, y: -1);
        transform = transform.translatedBy(x: 0, y: -self.cameraView.bounds.size.height);
        
        let features = detector?.features(in: ciImage, options: [CIDetectorSmile : true])
        
        // Proccessing each detected feature
        for feature in features as! [CIFaceFeature] {
            // Get the face rect: Convert CoreImage to UIKit coordinates
            let faceRect = feature.bounds.applying(transform)
            
            // Create a UIView using the bounds of the face
            // Red border: smile :-)
            // Blue border: not smile :-(
            let faceView = UIView(frame:faceRect)
            faceView.layer.borderWidth = 1;
            faceView.layer.borderColor = feature.hasSmile ? UIColor.red.cgColor : UIColor.blue.cgColor
            
            // Task must be on main thread to affect storyboard
            DispatchQueue.main.async {
                self.cameraView.addSubview(faceView)
            }
        }
    }
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        // サンプルバッファからピクセルバッファを取り出す
        let pixelBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // ピクセルバッファをベースにCoreImageのCIImageオブジェクトを作成
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        //CIImageからCGImageを作成
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageRect:CGRect = CGRect(x: 0,y: 0,width: pixelBufferWidth, height: pixelBufferHeight)
        let ciContext = CIContext.init()
        let cgimage = ciContext.createCGImage(ciImage, from: imageRect )
        
        // CGImageからUIImageを作成
        let image = UIImage(cgImage: cgimage!)
        return image
    }
}
