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
    
    @IBOutlet var interfaceButtons: [UIButton]!
    @IBOutlet var preCaptureButtons: [UIButton]!
    @IBOutlet var postCaptureButtons: [UIButton]!
    
    @IBOutlet var chooseFromLibrary: UIButton!
    @IBOutlet var searchFlickr: UIButton!
    
    let notificationCenter = NSNotificationCenter.defaultCenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBarHidden = true
        
        // Register for notifications about application state
        notificationCenter.addObserver(self, selector:#selector(ImageCaptureViewController.applicationWillResignActiveNotification), name:UIApplicationWillResignActiveNotification, object:nil)
        notificationCenter.addObserver(self, selector:#selector(ImageCaptureViewController.applicationDidBecomeActiveNotification), name:UIApplicationDidBecomeActiveNotification, object:nil)
        
        // Prepare the scrollable pastImage window
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        pastImage.contentMode = .ScaleAspectFill
        
        startCamera()
    }
    
    deinit {
        // Deregister for notifications about application state
        notificationCenter.removeObserver(self, name:UIApplicationDidBecomeActiveNotification, object:nil)
        notificationCenter.removeObserver(self, name:UIApplicationWillResignActiveNotification, object:nil)
    }
    
    /**
     Selector to call when UIApplicationWillResignActive fires
     */
    func applicationWillResignActiveNotification(){
        stopWobble()
        toggleShootButton()
    }
    
    /**
     Selector to call when UIApplicationDidBecomeActive fires
     */
    func applicationDidBecomeActiveNotification(){
        toggleWobble()
        toggleShootButton()
    }
    
    
    /**
     Toggle the animation state for wobbling buttons. If no image is present in pastImage UIImageView, then wobbling will commence; otherwise, wobbling will stop
     */
    func toggleWobble(){
        if let _ = pastImage.image {
            shootButton.hidden = false
            stopWobble()
        } else {
            startWobble()
            shootButton.hidden = true
        }
    }
    
    /**
     Toggle the visibility of the image capture button. If an image is present in pastImage UIImageView, then the button is visible; otherwise, it is not
     */
    func toggleShootButton(){
        if let _ = pastImage.image {
            shootButton.hidden = false
        } else {
            shootButton.hidden = true
        }
    
    }
    
    /**
     Stops the animation on the chooseFromLibrary and searchFlickr buttons
     */
    func stopWobble(){
        
        // Reset the button transform
        let animation = {
            self.chooseFromLibrary.transform = CGAffineTransformIdentity
            self.searchFlickr.transform = CGAffineTransformIdentity
        }
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.AllowUserInteraction, UIViewAnimationOptions.Repeat, UIViewAnimationOptions.Autoreverse], animations: animation, completion: nil)
    }
    
    /**
     Starts the animation on the chooseFromLibrary and searchFlickr buttons
     */
    func startWobble() {
        
        // Initialise the chooseLibraryButton at 5 radians to the left, and the searchFlickr button at 5 radians to the right
        chooseFromLibrary.transform = CGAffineTransformRotate(CGAffineTransformIdentity, (-5 * 3.141) / 180.0)
        searchFlickr.transform = CGAffineTransformRotate(CGAffineTransformIdentity, (5 * 3.141) / 180.0)
        
        // Now move the button transforms to the opposite position
        let animation = {
            self.chooseFromLibrary.transform = CGAffineTransformRotate(CGAffineTransformIdentity, (5 * 3.141) / 180.0)
            self.searchFlickr.transform = CGAffineTransformRotate(CGAffineTransformIdentity, (-5 * 3.141) / 180.0)
        }
        
        // Animate the transition between the two transforms such that they move from side-to-size ten times per second
        UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.AllowUserInteraction, UIViewAnimationOptions.Repeat, UIViewAnimationOptions.Autoreverse], animations: animation, completion: nil)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBarHidden = true
        toggleWobble()
        toggleShootButton()
        
    }
    
    
    /**
     Initialise a capture session for the rear camera and present the camera input in the cameraView
     */
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
        
        
        // Add an output to the capture session
        stillImageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        captureSession.addOutput(stillImageOutput)
        
        // Present the camera's input in the previewLayer
        tempImageView.hidden = true
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        cameraView.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }

    @IBAction func showImagePicker(sender: UIButton) {
        getImageFromImagePicker()
    }
    
    /**
     Create an image from the two half-images on screen, write to the persistent data store, and present the library view
     */
    @IBAction func saveImage(sender: UIButton) {
        
        let image = createScreenshotImage()
        
        // Create a ReshootPhoto object and 
        let realm = try! Realm()
        try! realm.write {
            let reshoot = ReshootPhoto()
            reshoot.photo = UIImageJPEGRepresentation(image, 1.0)
            realm.add(reshoot)
        }
        
        // Present the library view
        let reshootLibraryViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ImageLibrary") as! ReshootLibraryCollectionViewController
        navigationController?.pushViewController(reshootLibraryViewController, animated: true)
        
        // Prepare the capture view for the next capture session
        pastImage.image = nil
        showPreCaptureElements()
        self.cameraView.hidden = false
        self.tempImageView.hidden = true
    }
    
    /**
     Remove extraneous UI elements and take a screenshot of the relevant onscreen content
     
     - Returns: UIImage representing the screenshot
     */
    func createScreenshotImage() -> UIImage {
        hideOnScreenElements()
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, true, 0)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        showPreCaptureElements()
        return image
    
    }
    
    
    /**
     Present a UIImagePicker to the user
     */
    func getImageFromImagePicker(){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    /**
     Iterate through the elements in the interfaceButtons outlet collection and hide them
     */
    func hideOnScreenElements(){
        interfaceButtons.forEach {
            $0.hidden = true
        }
    }
    
    /**
     Iterate through the elements in the preCaptureButtons outlet collection and show them, hiding all others
     */
    func showPreCaptureElements(){
        hideOnScreenElements()
        preCaptureButtons.forEach {
            $0.hidden = false
        }
        
    }
    
    /**
     Iterate through the elements in the postCaptureButtons outlet collection and show them, hiding all others
     */
    func showPostCaptureElements(){
        hideOnScreenElements()
        postCaptureButtons.forEach {
            $0.hidden = false
        }
    }
    
    
    @IBAction func captureImage(sender: UIButton){
        didPressTakePhoto()
        showPostCaptureElements()
    }
    
    
    /**
     Capture a still image from the input to the camera
     */
    func didPressTakePhoto(){
        
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) { sampleBuffer, error in
                
                if let sampleBuffer = sampleBuffer {
                    
                    
                    // Create an image by cropping to the currently visible data
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider  = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, .RenderingIntentDefault)
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    
                    // Hide irrelevant interface elements and present the image data
                    self.cameraView.hidden = true
                    self.tempImageView.image = image
                    self.tempImageView.hidden = false
                    
                }
                
            }
            
        }
    }
    
    @IBAction func restartCameraSession(sender: UIButton) {
        showPreCaptureElements()
        self.cameraView.hidden = false
        self.tempImageView.hidden = true
        
    }
    @IBAction func segueToImageSearch(sender: UIButton) {
        let findPhotosVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("FlickrSearchModal") as! FindPhotosViewController
        findPhotosVC.delegate = self
        presentViewController(findPhotosVC, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        pastImage.image = image
        self.stopWobble()
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return pastImage
    }
    
    /**
     Delegate method for passing image from the Flickr image chooser to this view
     */
    func displaySelectedImage(data: UIImage) {
        pastImage.image = data
        toggleWobble()
        toggleShootButton()
    }
    
}
