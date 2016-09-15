//
//  ReshootLibraryCollectionViewController.swift
//  Yesterday And Today
//
//  Created by Tim on 13/09/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import RealmSwift

private let reuseIdentifier = "Cell"
private let realm = try! Realm()

class ReshootLibraryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet var feedbackLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        navigationController?.navigationBarHidden = false
        collectionView?.delegate = self
        
        toggleFeedback()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        toggleFeedback()
    }
    
    /**
     If the user's library is empty, display an appropriate message
     */
    func toggleFeedback(){
        if (realm.objects(ReshootPhoto.self).count == 0) {
            feedbackLabel.text = "Your album is empty"
            feedbackLabel.hidden = false
        } else {
            feedbackLabel.hidden = true
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return realm.objects(ReshootPhoto.self).count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        
        // Ensure that collection view shows the most recent addition to the library firest
        let lastIndex = realm.objects(ReshootPhoto.self).count - 1
        if let data = realm.objects(ReshootPhoto.self)[lastIndex - indexPath.item].photo {
            if let image = UIImage(data: data) {
                let imageView = UIImageView(image: image)
                imageView.frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height)
                imageView.contentMode = .ScaleAspectFill
                cell.contentView.addSubview(imageView)
            }
        }
    
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // If the user taps on an image, show it in a ViewImageViewController modal
        let viewImageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ViewImage") as! ViewImageViewController
        let lastIndex = realm.objects(ReshootPhoto.self).count - 1
        viewImageViewController.imageIndex = lastIndex - indexPath.item
        presentViewController(viewImageViewController, animated: true) {
            // The user may have deleted the image via the modal; data should be reloaded
            collectionView.reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Enforce an (n x 2) grid of images
        return CGSize(width: (collectionView.frame.width - 20 ) / 2.0, height: collectionView.frame.height / 2.0 )
    }

}
