//
//  FindPhotosViewController.swift
//  Yesterday And Today
//
//  Created by Tim on 10/09/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import RealmSwift
import CoreLocation
import MapKit

protocol PassBackImageDelegate {
    func displaySelectedImage(data: UIImage)
}

class FindPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate {
    
    @IBOutlet var accuracySegment: UISegmentedControl!
    @IBOutlet var radiusSlider: UISlider!
    @IBOutlet var indoorSwitch: UISwitch!
    @IBOutlet var outdoorSwitch: UISwitch!
    @IBOutlet var searchResultsCollection: UICollectionView!
    @IBOutlet var radiusLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    
    var delegate: PassBackImageDelegate?
    
    var notificationToken: NotificationToken? = nil
    let realm = try! Realm()
    
    let locationManager = CLLocationManager()
    private var userLongitude = 171.612499
    private var userLatitude = -43.500124
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchResultsCollection.dataSource = self
        searchResultsCollection.delegate = self
        
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestLocation()
        }
        
        let results = realm.objects(FlickrPhoto.self)
        notificationToken = results.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            print ("results changed")
            
            for photo in results {
                if let latitude = photo.latitude.value,
                    let longitude = photo.longitude.value,
                let map = self?.mapView{
                
                    let pin = MKPointAnnotation()
                    pin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    map.addAnnotation(pin)
                }
            
            }
            
            self!.searchResultsCollection.reloadData()
        }
        radiusLabel.text = "\(radiusSlider.value) km"
        mapView.showsUserLocation = true
        mapView.region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    }
    
    deinit {
        notificationToken?.stop()
    }
    
    @IBAction func updateRadius(sender: UISlider) {
        radiusLabel.text = "\(sender.value) km"
    }
    
    @IBAction func close(sender: UIButton){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print ("Couldn't get location")
        print (error)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLatitude = (locations.last?.coordinate.latitude)!
        userLongitude = (locations.last?.coordinate.longitude)!
    }
    
    
    @IBAction func search(sender: UIButton){
        print ("Hit search")
        try! realm.write {
            realm.deleteAll()
        }
        let parameters = [
            "lon": String(userLongitude),
            "lat": String(userLatitude),
            "accuracy": accuracySegment.selectedSegmentIndex == 0 ? "16" : "11",
            "geo_context": outdoorSwitch.on ? "2" : "0",
            "radius": String(radiusSlider.value)
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
            cell.backgroundView = imageView
            //cell.contentView.addSubview(imageView)
            
            
        }
//        
//        if let location = locationManager.location,
        
        let userLocation = CLLocation(latitude: userLatitude, longitude: userLongitude)
        if let latitude = results[indexPath.item].latitude.value,
        longitude = results[indexPath.item].longitude.value
        {
            
            mapView.centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print ("Selected something")
        if let imageData = realm.objects(FlickrPhoto.self)[indexPath.item].photo {
            delegate?.displaySelectedImage(UIImage(data: imageData)!)
        }
        dismissViewControllerAnimated(true, completion: nil)
        
    }
}
