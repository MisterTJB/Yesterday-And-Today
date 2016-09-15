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

class FindPhotosViewController: UIViewController {
    
    // Input elements
    @IBOutlet var radiusSlider: UISlider!
    @IBOutlet var searchButton: UIBarButtonItem!
    @IBOutlet var afterBeforeDate: UIPickerView!
    
    // Labels
    @IBOutlet var radiusLabel: UILabel!
    @IBOutlet var feedbackLabel: UILabel!
    
    // Subviews
    @IBOutlet var searchResultsCollection: UICollectionView!
    @IBOutlet var mapView: MKMapView!
    
    var delegate: PassBackImageDelegate?
    
    // Realm objects
    var notificationToken: NotificationToken? = nil
    let realm = try! Realm()
    
    let locationManager = CLLocationManager()
    
    // User location
    private var userLongitude: Double?
    private var userLatitude: Double?
    
    // Date picker state
    private var selectedAfterYear = 2010
    private var selectedBeforeYear = 2016
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSearchParameters()
        
        // Establish as a delegate for the collection view
        searchResultsCollection.dataSource = self
        searchResultsCollection.delegate = self
        
        // Establish as a delegate for the year picker
        afterBeforeDate.dataSource = self
        afterBeforeDate.delegate = self
        
        // Establish as a delegate for the map
        mapView.delegate = self
        
        establishUserLocationPermission()
        
        // Configure realm
        let results = realm.objects(FlickrPhoto.self)
        notificationToken = results.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            print ("results changed")
            self!.toggleSearchButton()
            self!.searchResultsCollection.reloadData()
        }
        
        // Establish UI state
        radiusLabel.text = "\(radiusSlider.value) km"
        mapView.showsUserLocation = true
        
        afterBeforeDate.selectRow(selectedAfterYear - 1825, inComponent: 0, animated: true)
        afterBeforeDate.selectRow(selectedBeforeYear - 1825, inComponent: 1, animated: true)
        
        if results.count == 0 {
            feedbackLabel.text = "Let's find some photos!"
            feedbackLabel.hidden = false
        } else {
            feedbackLabel.hidden = true
        }
        
        
    }
    
    /**
     Ask the user for permission to access their location. If their location is unavailable, they are warned and Flickr download is disabled
     */
    func establishUserLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        
        // Configure location services
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestLocation()
        }
    }
    
    deinit {
        notificationToken?.stop()
    }
    
    @IBAction func updateRadius(sender: UISlider) {
        sender.value = round(2 * sender.value)/2.0 // Ensure that the radius is snaps to the nearest 0.5 km
        radiusLabel.text = "\(sender.value) km"
    }
    
    @IBAction func close(sender: AnyObject){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
     Determine whether image data is still being downloaded
     
     - Returns: true if there is still data to download; false otherwise
     */
    func dataIsDownloading() -> Bool {
        
        var retVal = false
        for image in realm.objects(FlickrPhoto.self) {
            retVal = (image.photo == nil) || retVal
        }
        return retVal
    }
    
    /**
     Delete results that do not have photo data associated with them
     */
    func deleteUnavailableImages(){
        for result in realm.objects(FlickrPhoto.self) {
            if result.photo == nil {
                try! realm.write {
                    realm.delete(result)
                }
                
            }
        }
    }
    
    /**
     Disable the search button if there is still data to download, or enable it otherwise
     */
    func toggleSearchButton(){
        
        if dataIsDownloading(){
            searchButton.enabled = false
        } else {
            searchButton.enabled = true
        }
    }
    
    @IBAction func search(sender: AnyObject){
        
        // Update UI
        searchButton.enabled = false
        feedbackLabel.text = "Searching for images..."
        feedbackLabel.hidden = false
        
        // Empty the persistent store to accommodate the new results
        try! realm.write {
            realm.delete(realm.objects(FlickrPhoto.self))
        }
        
        persistSearchParameters()
        let parameters = prepareSearchParameters()
        
        FlickrDownloadManager.downloadImagesFromFlickrWithParametersAndPersist(parameters, completion: updateUserInterfaceAfterDownload)
    }
    
    
    /**
     Extract relevant values from UI elements and prepare search parameters
     
     - Returns: A dictionary mapping search query parameters to values
     */
    func prepareSearchParameters() -> [String: String] {
        
        let gregorianCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        
        
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
            "lon": String(userLongitude!),
            "lat": String(userLatitude!),
            "radius": String(radiusSlider.value),
            "min_taken_date": String(Int(afterDate!.timeIntervalSince1970)),
            "max_taken_date": String(Int(beforeDate!.timeIntervalSince1970))
            
        ]
        
        return parameters
    
    }
    
    /**
     Update the user interface in repsonse to downloaded data. If errors have occurred, appropriate alerts are displayed; if no errors have occured, check for an empty result set 
     and update the user interface accordingly
     
     - Parameters:
        - errorState: The error passed up by the networking module
     */
    func updateUserInterfaceAfterDownload(errorState: NSError?) {
        
        if let error = errorState {
            
            // If an error occurs when downloading a specific image
            if (error.domain == "downloadImageDataForPhotos"){
                let alertVC = UIAlertController(title: "Network Error", message: "Some photos couldn't be downloaded. You may like to search again", preferredStyle: UIAlertControllerStyle.Alert)
                let dismiss = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel) { alertAction in
                    self.searchButton.enabled = true
                }
                alertVC.addAction(dismiss)
                self.presentViewController(alertVC, animated: true) {
                    // Delete any results from the result set whose image could not be downloaded
                    self.deleteUnavailableImages()
                }
            } else { // If an error occurs when trying to retrieve the initial enumeration of images
                let alertVC = UIAlertController(title: "Network Error", message: "Something went wrong! Check your network availability and try again", preferredStyle: UIAlertControllerStyle.Alert)
                let dismiss = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel) { alertAction in
                    
                    // Reset the user interface to enable a new search
                    self.feedbackLabel.text = "Let's find some photos!"
                    self.feedbackLabel.hidden = false
                    self.searchButton.enabled = true
                }
                alertVC.addAction(dismiss)
                self.presentViewController(alertVC, animated: true, completion: nil)
            }
            
        } else {
            
            // If there are no results, echo that fact to the UI
            if self.realm.objects(FlickrPhoto.self).count == 0 {
                self.feedbackLabel.text = "No results"
                self.feedbackLabel.hidden = false
                self.searchButton.enabled = true
            } else {
                self.feedbackLabel.hidden = true
            }
            
        }
    }
    
    
    /**
     Store search parameters in NSUserDefaults
     */
    func persistSearchParameters(){
        NSUserDefaults.standardUserDefaults().setInteger(selectedBeforeYear, forKey: "beforeYear")
        NSUserDefaults.standardUserDefaults().setInteger(selectedAfterYear, forKey: "afterYear")
        NSUserDefaults.standardUserDefaults().setFloat(radiusSlider.value, forKey: "radius")
    }
    
    /**
     Load the search parameters for the last search from NSUserDefaults
     */
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

// MARK: Delegate methods for managing the year picker

extension FindPhotosViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (2017 - 1825) // Compute the range of valid years to present to the Flickr API
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2 // A picker for the after year, and a picker for the before year
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(1825 + row) // Compute a year from a row index
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        // Ensure that the before year can never be less than the after year, and vice versa
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

}

// MARK: Delegate methods for managing the display of data in the collection view

extension FindPhotosViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrPhotoCell", forIndexPath: indexPath)
        
        let results = realm.objects(FlickrPhoto.self)
        
        // If data is ready, show the image
        if let photoData = results[indexPath.item].photo {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: cell.bounds.height))
            imageView.image = UIImage(data: photoData)
            imageView.contentMode = .ScaleAspectFill
            cell.backgroundView = imageView
            
        } else {
            // If data is downloading, show an activity indicator
            let activityView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: cell.bounds.height))
            activityView.startAnimating()
            cell.backgroundView = activityView
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Return a cell the size of the containing collection view
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // After selecting an image, pass that image back to the presenting view controller
        if let imageData = realm.objects(FlickrPhoto.self)[indexPath.item].photo {
            delegate?.displaySelectedImage(UIImage(data: imageData)!)
        }
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        // Add a pin to the map to show the location that the photo was taken at
        let results = realm.objects(FlickrPhoto.self)
        if let latitude = results[indexPath.item].latitude.value,
            let longitude = results[indexPath.item].longitude.value {
            addAnnotationToMapAtCoordinate(latitude: latitude, longitude: longitude)
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let results = realm.objects(FlickrPhoto.self)
        return results.count
    }

}

// MARK: Delegate methods for capturing user location

extension FindPhotosViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        feedbackLabel.text = "Search is disabled until your location can be determined"
        searchButton.enabled = false
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print ("updated location")
    }
    
}

// MARK: Delegate and helper methods for updating the map view

extension FindPhotosViewController: MKMapViewDelegate {
    
    /**
     Remove annotations from the map and replace with an annotation at the passed in coordinates:
     
     - Parameters:
        - latitude: The latitude at which to place the pin
        - longitude: The longitude at which to place the pin
     */
    func addAnnotationToMapAtCoordinate(latitude latitude: Double, longitude: Double){
        mapView.removeAnnotations(mapView.annotations)
        
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.addAnnotation(pin)
        
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        
        // Show a region large enough to show all image locations
        mapView.setRegion(MKCoordinateRegionMake(userLocation.coordinate, MKCoordinateSpanMake(0.04, 0.04)), animated: true)
        
        // Update the user location properties with the user's current location
        userLatitude = userLocation.coordinate.latitude
        userLongitude = userLocation.coordinate.longitude
        
        // Enable the search button
        searchButton.enabled = true
        feedbackLabel.text = "Let's find some photos!"
    }


}