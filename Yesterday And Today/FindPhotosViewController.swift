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

class FindPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, MKMapViewDelegate {
    
    @IBOutlet var radiusSlider: UISlider!
    @IBOutlet var searchResultsCollection: UICollectionView!
    @IBOutlet var radiusLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var searchButton: UIBarButtonItem!
    @IBOutlet var feedbackLabel: UILabel!
    
    @IBOutlet var afterBeforeDate: UIPickerView!
    
    var delegate: PassBackImageDelegate?
    
    var notificationToken: NotificationToken? = nil
    let realm = try! Realm()
    
    let locationManager = CLLocationManager()
    private var userLongitude = 171.612499
    private var userLatitude = -43.500124
    private var selectedAfterYear = 2010
    private var selectedBeforeYear = 2016
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (2017 - 1825)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return String(1825 + row)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if component == 0 && row >  pickerView.selectedRowInComponent(1) {
            pickerView.selectRow(pickerView.selectedRowInComponent(1), inComponent: 0, animated: true)
        } else if component == 1 && row <  pickerView.selectedRowInComponent(0) {
            pickerView.selectRow(pickerView.selectedRowInComponent(0), inComponent: 1, animated: true)
        } else {
        
        
            if component == 0 {
                selectedAfterYear = 1825 + row
            } else if component == 1 {
                selectedBeforeYear = 1825 + row
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSearchParameters()
        
        searchResultsCollection.dataSource = self
        searchResultsCollection.delegate = self
        
        afterBeforeDate.dataSource = self
        afterBeforeDate.delegate = self
        
        mapView.delegate = self
        
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestLocation()
        }
        
        let results = realm.objects(FlickrPhoto.self)
        notificationToken = results.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            print ("results changed")
            self!.toggleSearchButton()
            self!.searchResultsCollection.reloadData()
        }
        radiusLabel.text = "\(radiusSlider.value) km"
        mapView.showsUserLocation = true
        
        if results.count == 0 {
            feedbackLabel.text = "Let's find some photos!"
            feedbackLabel.hidden = false
        } else {
            feedbackLabel.hidden = true
        }
        
        afterBeforeDate.selectRow(selectedAfterYear - 1825, inComponent: 0, animated: true)
        afterBeforeDate.selectRow(selectedBeforeYear - 1825, inComponent: 1, animated: true)
        
        
    }
    
    deinit {
        notificationToken?.stop()
    }
    
    @IBAction func updateRadius(sender: UISlider) {
        sender.value = round(2 * sender.value)/2.0
        radiusLabel.text = "\(sender.value) km"
    }
    
    @IBAction func close(sender: AnyObject){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        feedbackLabel.text = "Search is disabled until your location can be determined"
        
        searchButton.enabled = false
        print ("Couldn't get location")
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print ("updated location")
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        mapView.setRegion(MKCoordinateRegionMake(userLocation.coordinate, MKCoordinateSpanMake(0.05, 0.05)), animated: true)
        userLatitude = (userLocation.coordinate.latitude)
        userLongitude = (userLocation.coordinate.longitude)
        print ("Got location")
        
        searchButton.enabled = true
        feedbackLabel.text = "Let's find some photos!"
    }
    
    func dataIsDownloading() -> Bool {
        
        var retVal = false
        for image in realm.objects(FlickrPhoto.self) {
            retVal = (image.photo == nil) || retVal
        }
        return retVal
    }
    
    func toggleSearchButton(){
        
        if dataIsDownloading(){
            searchButton.enabled = false
        } else {
            searchButton.enabled = true
        }
    }
    
    @IBAction func search(sender: AnyObject){
        print ("Hit search")
        searchButton.enabled = false
        persistSearchParameters()
        try! realm.write {
            realm.delete(realm.objects(FlickrPhoto.self))
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
        feedbackLabel.text = "Searching for images..."
        feedbackLabel.hidden = false
        FlickrDownloadManager.downloadImagesFromFlickrWithParametersAndPersist(parameters) { error in
            
            if let error = error {
                let alertVC = UIAlertController(title: "Network Error", message: "Something went wrong! Check your network availability and try again", preferredStyle: UIAlertControllerStyle.Alert)
                let dismiss = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel) { alertAction in
                    self.feedbackLabel.text = "Let's find some photos!"
                    self.feedbackLabel.hidden = false
                    self.searchButton.enabled = true
                }
                alertVC.addAction(dismiss)
                self.presentViewController(alertVC, animated: true, completion: nil)
                
            } else {
            
                if self.realm.objects(FlickrPhoto.self).count == 0 {
                    self.feedbackLabel.text = "No results"
                    self.feedbackLabel.hidden = false
                    self.searchButton.enabled = true
                } else {
                    self.feedbackLabel.hidden = true
                }
                
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let results = realm.objects(FlickrPhoto.self)
        return results.count
    }
    
    func addAnnotationToMapAtCoordinate(latitude latitude: Double, longitude: Double){
        mapView.removeAnnotations(mapView.annotations)
        
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.addAnnotation(pin)
        print ("Added annotation to map")
        mapView.setNeedsDisplay()
        
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        let results = realm.objects(FlickrPhoto.self)
        if let latitude = results[indexPath.item].latitude.value,
            let longitude = results[indexPath.item].longitude.value {
            addAnnotationToMapAtCoordinate(latitude: latitude, longitude: longitude)
        }
        
        
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrPhotoCell", forIndexPath: indexPath)
        
        let results = realm.objects(FlickrPhoto.self)
        
        if let photoData = results[indexPath.item].photo {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: cell.bounds.height))
            imageView.image = UIImage(data: photoData)
            imageView.contentMode = .ScaleAspectFill
            cell.backgroundView = imageView
            
            
            
            
        } else {
            let activityView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: cell.bounds.height))
            activityView.startAnimating()
            cell.backgroundView = activityView
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
    
    func persistSearchParameters(){
        NSUserDefaults.standardUserDefaults().setInteger(selectedBeforeYear, forKey: "beforeYear")
        NSUserDefaults.standardUserDefaults().setInteger(selectedAfterYear, forKey: "afterYear")
        NSUserDefaults.standardUserDefaults().setFloat(radiusSlider.value, forKey: "radius")
    }
    
    func loadSearchParameters(){
        
        let before = NSUserDefaults.standardUserDefaults().integerForKey("beforeYear")
        let after = NSUserDefaults.standardUserDefaults().integerForKey("afterYear")
        let radius = NSUserDefaults.standardUserDefaults().floatForKey("radius")
        
        if before != 0 {
            selectedBeforeYear = before
        } else {
            selectedBeforeYear = 2016
        }
        
        if after != 0 {
            selectedAfterYear = after
        } else {
            selectedAfterYear = 2010
        }
        
        if radius != 0 {
            radiusSlider.value = radius
        } else {
            radiusSlider.value = 0.5
        }
    }

    
}
