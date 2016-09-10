//
//  ImageCaptureViewController.swift
//  Yesterday And Today
//
//  Created by Tim on 8/09/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import AVFoundation

class ImageCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, PassBackImageDelegate {

    @IBOutlet weak var pastImage: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cameraView: UIView!
    
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var error: NSError?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBarHidden = true
        pastImage.contentMode = .ScaleAspectFill

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        
        let devices = AVCaptureDevice.devices().filter{ $0.hasMediaType(AVMediaTypeVideo) && $0.position == AVCaptureDevicePosition.Back }
        if let captureDevice = devices.first as? AVCaptureDevice  {
            
            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            } catch {
                print ("MRH")
            }
            
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
            captureSession.startRunning()
            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
            if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
                previewLayer.bounds = view.bounds
                previewLayer.position = CGPointMake(view.bounds.midX, view.bounds.midY)
                previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                let cameraPreview = UIView(frame: CGRectMake(0.0, 0.0, cameraView.bounds.size.width, cameraView.bounds.size.height))
                cameraPreview.layer.addSublayer(previewLayer)
                cameraView.addSubview(cameraPreview)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showImagePicker(sender: UIButton) {
        getImageFromImagePicker()
    }
    
    func getImageFromImagePicker(){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        presentViewController(imagePickerController, animated: true){
            print("Stuff giot picked")
        }
    }
    
    @IBAction func captureImage(sender: UIButton){
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                imageDataSampleBuffer, error in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                
            }
        }
    }
    
    @IBAction func segueToImageSearch(sender: UIButton) {
        let findPhotosVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("FlickrSearchModal") as! FindPhotosViewController
        findPhotosVC.delegate = self
        presentViewController(findPhotosVC, animated: true, completion: nil)
    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        pastImage.image = image
        print (image.size)
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return pastImage
    }
    
    func displaySelectedImage(data: UIImage) {
        pastImage.image = data
    }
    
    
}
