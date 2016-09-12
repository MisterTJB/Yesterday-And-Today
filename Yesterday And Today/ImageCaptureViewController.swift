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
    
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var shootButton: UIButton!
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var error: NSError?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBarHidden = true
        pastImage.contentMode = .ScaleAspectFill
        scrollView.delegate = self
        

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        
        var backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        for device in AVCaptureDevice.devices() as! [AVCaptureDevice]{
            if device.position == AVCaptureDevicePosition.Front {
                backCamera = device
            }
        }
        
        var error : NSError?
        var input = try! AVCaptureDeviceInput(device: backCamera)

            
        captureSession.addInput(input)
        
        stillImageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        captureSession.addOutput(stillImageOutput)
        tempImageView.hidden = true
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        cameraView.layer.addSublayer(previewLayer!)
        captureSession.startRunning()
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
        
        didPressTakeAnother()
    }
    
    func didPressTakePhoto(){
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                (sampleBuffer, error) in
                
                if sampleBuffer != nil {
                    
                    
                    var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    var dataProvider  = CGDataProviderCreateWithCFData(imageData)
                    var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, .RenderingIntentDefault)
                    
                    var image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.cameraView.hidden = true
                    self.scrollView.alpha = 1.0
                    self.tempImageView.image = image
                    self.tempImageView.hidden = false
                    
                }
                
                
            })
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
    
    var didTakePhoto = Bool()
    
    func didPressTakeAnother(){
        if didTakePhoto == true{
            tempImageView.hidden = true
            didTakePhoto = false
            
        }
        else{
            captureSession.startRunning()
            didTakePhoto = true
            didPressTakePhoto()
            
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        didPressTakeAnother()
    }
    
}
