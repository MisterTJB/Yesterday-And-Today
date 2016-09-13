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
        
        let imageData = realm.objects(ReshootPhoto.self)[imageIndex!].photo
        let image = UIImage(data: imageData!)
        imageView.contentMode = .ScaleAspectFill
        imageView.image = image
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
