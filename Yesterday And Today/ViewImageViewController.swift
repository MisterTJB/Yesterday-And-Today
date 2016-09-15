//
//  ViewImageViewController.swift
//  Yesterday And Today
//
//  Created by Tim on 13/09/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import RealmSwift

class ViewImageViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    var imageIndex: Int?
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateImageView()
    }
    
    /**
     Load the relevant image data in to the image view
     */
    func updateImageView(){
        let imageData = realm.objects(ReshootPhoto.self)[imageIndex!].photo
        let image = UIImage(data: imageData!)
        imageView.contentMode = .ScaleAspectFill
        imageView.image = image
    }
    
    
    /**
     Manages left- and right-swiping between images
     */
    @IBAction func swipedImage(sender: UISwipeGestureRecognizer) {
        print ("Trying to swipe")
        if (sender.direction == UISwipeGestureRecognizerDirection.Left) {
            imageIndex = max(0, imageIndex! - 1)
            updateImageView()
        } else if (sender.direction == UISwipeGestureRecognizerDirection.Right) {
            imageIndex = min(realm.objects(ReshootPhoto.self).count - 1, imageIndex! + 1)
            updateImageView()
        }
    }

    @IBAction func deleteImage(sender: AnyObject) {
        
        try! realm.write{
            realm.delete(realm.objects(ReshootPhoto.self)[imageIndex!])
        }
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func share(sender: AnyObject) {
        let actionSheetViewController = UIActivityViewController(activityItems: [imageView.image!], applicationActivities: nil)
        presentViewController(actionSheetViewController, animated: true, completion: nil)
    }
    
    @IBAction func close(sender: AnyObject) {
        print ("Trying to dimiss")
        dismissViewControllerAnimated(true, completion: nil)
    }

}
