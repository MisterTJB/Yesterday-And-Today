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

class FindPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet var radiusSlider: UISlider!
    @IBOutlet var searchResultsCollection: UICollectionView!
    @IBOutlet var radiusLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    
    
    @IBOutlet var afterBeforeDate: UIPickerView!
    
    var delegate: PassBackImageDelegate?
    
    var notificationToken: NotificationToken? = nil
    let realm = try! Realm()
    
    let locationManager = CLLocationManager()
    private var userLongitude = 171.612499
    private var userLatitude = -43.500124
    private var selectedAfterYear = 1825
    private var selectedBeforeYear = 1825
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (2016 - 1825)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(1825 + row)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedAfterYear = 1825 + row
        } else if component == 1 {
            selectedBeforeYear = 1825 + row
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchResultsCollection.dataSource = self
        searchResultsCollection.delegate = self
        
        afterBeforeDate.dataSource = self
        afterBeforeDate.delegate = self
        
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
    
    @IBAction func close(sender: AnyObject){
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
    
    
    @IBAction func search(sender: AnyObject){
        print ("Hit search")
        try! realm.write {
            realm.deleteAll()
        }
        
        
        let gregorianCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        
        
        let afterDateComponents = NSDateComponents()
        afterDateComponents.day = 1
        afterDateComponents.month = 1
        afterDateComponents.year = selectedAfterYear
        
        let beforeDateComponents = NSDateComponents()
        beforeDateComponents.day = 31
        beforeDateComponents.month = 12
        beforeDateComponents.year = selectedBeforeYear
        
        let afterDate = gregorianCalendar?.dateFromComponents(afterDateComponents)
        let beforeDate = gregorianCalendar?.dateFromComponents(beforeDateComponents)
        
        
        let parameters = [
            "lon": String(userLongitude),
            "lat": String(userLatitude),
            "radius": String(radiusSlider.value),
            "min_taken_date": String(Int(afterDate!.timeIntervalSince1970)),
            "max_taken_date": String(Int(beforeDate!.timeIntervalSince1970))
            
        ]
        FlickrDownloadManager.downloadImagesFromFlickrWithParametersAndPersist(parameters)
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
