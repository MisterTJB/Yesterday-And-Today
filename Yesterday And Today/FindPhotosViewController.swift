//
//  FindPhotosViewController.swift
//  Yesterday And Today
//
//  Created by Tim on 10/09/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import RealmSwift

protocol PassBackImageDelegate {
    func displaySelectedImage(data: UIImage)
}

class FindPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var accuracySegment: UISegmentedControl!
    @IBOutlet var radiusSlider: UISlider!
    @IBOutlet var indoorSwitch: UISwitch!
    @IBOutlet var outdoorSwitch: UISwitch!
    @IBOutlet var searchResultsCollection: UICollectionView!
    
    var delegate: PassBackImageDelegate?
    
    var notificationToken: NotificationToken? = nil
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchResultsCollection.dataSource = self
        searchResultsCollection.delegate = self
        let results = realm.objects(FlickrPhoto.self)
        notificationToken = results.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            print ("results changed")
            self!.searchResultsCollection.reloadData()
        }
    }
    
    deinit {
        notificationToken?.stop()
    }
    
    
    @IBAction func close(sender: UIButton){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func search(sender: UIButton){
        print ("Hit search")
        var parameters = [
            "lon": "172.61249863125818",
            "lat": "-43.50012403389569"
        ]
        FlickrDownloadManager.downloadImagesFromFlickrWithParametersAndPersist(parameters)
    }

    @IBAction func setDefaults(sender: UIButton) {
        accuracySegment.selectedSegmentIndex = 0
        radiusSlider.setValue(0.5, animated: true)
        indoorSwitch.setOn(true, animated: true)
        outdoorSwitch.setOn(true, animated: true)
    
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let results = realm.objects(FlickrPhoto.self)
        return results.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrPhotoCell", forIndexPath: indexPath)
        
        let results = realm.objects(FlickrPhoto.self)
        
        if let photoData = results[indexPath.item].photo {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: cell.bounds.height))
            imageView.image = UIImage(data: photoData)
            imageView.contentMode = .ScaleAspectFill
            cell.addSubview(imageView)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print ("Selected something")
        if let imageData = realm.objects(FlickrPhoto.self)[indexPath.item].photo {
            delegate?.displaySelectedImage(UIImage(data: imageData)!)
        }
        dismissViewControllerAnimated(true, completion: nil)
        
    }
}
