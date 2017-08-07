//
//  ViewController.swift
//  SoundCamera
//
//  Created by Chih-Kuang Chang on 2017/8/2.
//  Copyright © 2017年 Cytus Chang. All rights reserved.
//

import UIKit
import AudioKit
import GPUImage

class ViewController: UIViewController, CameraDelegate {
    @IBOutlet var cameraContainerView: RenderView!
    @IBOutlet var waveContainerView: UIView!
    
    // GPUImage components
    let videoCamera: Camera?
    let swirlFilter = SwirlDistortion()
    
    // AudioKit components
    var mic: AKMicrophone
    var fft: CustomFFT
//    var tracker: AKFrequencyTracker!
//    var silence: AKBooster!
    var accel: Float = 0.0
    
    required init(coder aDecoder: NSCoder)
    {
        do {
            videoCamera = try Camera(sessionPreset:AVCaptureSessionPreset640x480, location:.frontFacing)
        } catch {
            videoCamera = nil
            print("Couldn't initialize camera with error: \(error)")
        }
        
        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        fft = CustomFFT.init(mic)
//        tracker = AKFrequencyTracker(mic)
//        silence = AKBooster(tracker, gain: 0)
        
        super.init(coder: aDecoder)!
        guard videoCamera != nil else {
            return
        }
        videoCamera!.delegate = self
    }

    func startCamera() {
        guard let videoCamera = videoCamera else {
            let errorAlertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: "Couldn't initialize camera", preferredStyle: .alert)
            errorAlertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil))
            self.present(errorAlertController, animated: true, completion: nil)
            return
        }
        
        let rotationFilter = TransformOperation()
        let flipTransform = CATransform3DMakeRotation(CGFloat(Float.pi), 1, 0, 0)
        rotationFilter.transform = Matrix4x4(flipTransform)
        videoCamera --> rotationFilter --> swirlFilter --> cameraContainerView
        videoCamera.startCapture()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startCamera()
        AudioKit.output = mic
        AudioKit.start()

//        let plot = AKNodeOutputPlot(mic, frame: waveContainerView.bounds)
//        plot.plotType = .rolling
//        plot.shouldFill = true
//        plot.shouldMirror = true
//        plot.color = UIColor.blue
//        waveContainerView.addSubview(plot)
        
        swirlFilter.angle = 0
        swirlFilter.radius = 0.75
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let videoCamera = videoCamera {
            videoCamera.stopCapture()
            videoCamera.removeAllTargets()
        }
        
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
//        NSLog("Freq: %.1f, Amp: %.3f", tracker.frequency, tracker.amplitude)
//        let power = Float(tracker.frequency / 4000.0 + tracker.amplitude / 5)
//        updateSwirlFilter(freq: power > 0.06 ? power : 0)
        for i in 0..<256 {
            NSLog("%d Hz: %f", i, fft.fftData[i])
        }
    }
    
    func updateSwirlFilter(freq: Float) {
        let diff = freq - swirlFilter.angle
        
        if (diff >= 0 && accel < diff) || (diff < 0 && swirlFilter.angle + accel < 0) {
            accel += fabsf (diff / 10.0)
        } else {
            accel -= fabsf (diff / 10.0)
        }
        swirlFilter.angle += accel
        
        if swirlFilter.angle < 0 {
            swirlFilter.angle = 0
            accel = 0
        } else if swirlFilter.angle > 2 {
            swirlFilter.angle = 2
            accel = 0
        }
        
        //NSLog("Angle: %.3f", swirlFilter.angle)
    }
}

