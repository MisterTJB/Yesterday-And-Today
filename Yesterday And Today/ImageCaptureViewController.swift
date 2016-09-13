//
//  ImageCaptureViewController.swift
//  Yesterday And Today
//
//  Created by Tim on 8/09/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import AVFoundation
import RealmSwift

class ImageCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, PassBackImageDelegate {

    @IBOutlet weak var pastImage: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var shootButton: UIButton!
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBarHidden = true
        pastImage.contentMode = .ScaleAspectFill
        scrollView.delegate = self
        

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        
        startCamera()
    }
    
    func startCamera(){
        // Get back camera
        let devices = AVCaptureDevice.devices().filter {
            $0.hasMediaType(AVMediaTypeVideo) && $0.position == AVCaptureDevicePosition.Back
        }
        if let captureDevice = devices.first as? AVCaptureDevice {
            
            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            } catch {
                print ("COULDNT ADD DEVICE TO CAPTURE SESSION")
            }
        }
        
        
        stillImageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        captureSession.addOutput(stillImageOutput)
        
        tempImageView.hidden = true
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        //previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
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
    
    @IBAction func saveImage(sender: UIButton) {
        hideOnScreenElements()
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, true, 0)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let realm = try! Realm()
        try! realm.write {
            let reshoot = ReshootPhoto()
            reshoot.photo = UIImageJPEGRepresentation(image, 1.0)
            realm.add(reshoot)
        }
        
        
        
        let reshootLibraryViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ImageLibrary") as! ReshootLibraryCollectionViewController
        navigationController?.pushViewController(reshootLibraryViewController, animated: true)
    }
    
    func getImageFromImagePicker(){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        presentViewController(imagePickerController, animated: true){
            print("Stuff giot picked")
        }
    }
    
    func hideOnScreenElements(){
        
    }
    
    @IBAction func captureImage(sender: UIButton){
        
        didPressTakePhoto()
    }
    
    
    func didPressTakePhoto(){
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) { sampleBuffer, error in
                
                if sampleBuffer != nil {
                    
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider  = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, .RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.cameraView.hidden = true
                    self.scrollView.alpha = 1.0
                    self.tempImageView.image = image
                    self.tempImageView.hidden = false
                    
                }
                
                
            }
        }
    }
    
    @IBAction func restartCameraSession(sender: UIButton) {
        self.cameraView.hidden = false
        self.scrollView.alpha = 0.75
        self.tempImageView.hidden = true
        
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
