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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        navigationController?.navigationBarHidden = false
        collectionView?.delegate = self

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return realm.objects(ReshootPhoto.self).count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
//        let image = realm.objects(ReshootPhoto.self)[indexPath.item]
//        let uiImageView = UIImageView(image: UIImage(data: image.photo!)!)
//        cell.contentView = uiImageView
    
        // Configure the cell
        
        cell.backgroundColor = UIColor.redColor()
        if let data = realm.objects(ReshootPhoto.self)[indexPath.item].photo {
            if let image = UIImage(data: data) {
                let imageView = UIImageView(image: image)
                imageView.frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height)
                imageView.contentMode = .ScaleAspectFill
                cell.contentView.addSubview(imageView)
            }
        }
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        print ("Getting cell size")
        return CGSize(width: collectionView.frame.width / 5.0, height: collectionView.frame.height / 5.0 )
    }
    

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let viewImageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ViewImage") as! ViewImageViewController
        viewImageViewController.imageIndex = indexPath.item
        presentViewController(viewImageViewController, animated: true) {
            collectionView.reloadData()
        }
    }

}
