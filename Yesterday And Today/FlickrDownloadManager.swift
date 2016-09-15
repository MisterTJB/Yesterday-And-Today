//
//  FlickrDownloadManager.swift
//  Yesterday And Today
//
//  Created by Tim on 10/09/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import Alamofire
import RealmSwift

class FlickrDownloadManager: NSObject {
    
    
    /**
     Download relevant images from Flickr and store in a realm
     
     - Parameters:
        - parameters: A dictionary mapping valid Flickr query parameters to search values
        - completion: The completion handler to call. Will pass nil if no error occurs
     */
    static func downloadImagesFromFlickrWithParametersAndPersist(parameters: [String: String], completion: (NSError?) -> ()) {
        
        // Add additional query parameters that needn't be understood by the caller
        var _parameters = parameters
        _parameters["api_key"] = "a4ebce9cbae74391014b23471293fb42"
        _parameters["per_page"] = "50"
        _parameters["format"] = "json"
        _parameters["nojsoncallback"] = "1"
        _parameters["extras"] = "url_m,date_taken,geo"
        _parameters["method"] = "flickr.photos.search"
        _parameters["content_type"] = "6"
        
        
        // Initiate the search request
        Alamofire.request(.GET, "https://api.flickr.com/services/rest/", parameters: _parameters, encoding: .URL)
            .validate()
            .responseJSON { response in
                
                guard response.result.isSuccess else {
                    print("Error while fetching photos: \(response.result.error)")
                    completion(NSError(domain: "Initial Flickr request was unsuccessful", code: 0, userInfo: nil))
                    return
                }
                
                print (response.request?.URLString)
                guard let result = response.result.value as? [String: AnyObject],
                    photos = result["photos"] as? [String: AnyObject],
                    photo = photos["photo"] as? [[String: AnyObject]] else {
                        completion(NSError(domain: "Initial Flickr request response was malformed", code: 0, userInfo: nil))
                        return
                }
                
                
                
                // Create skeletal FlickrPhoto objects (i.e. with no image data) and persist
                let realm = try! Realm()
                for p in photo {
                    if let url = p["url_m"] as? String,
                        let dateTaken = p["datetaken"] as? String,
                        let latitudeString = p["latitude"] as? String,
                        let longitudeString = p["longitude"] as? String{
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let date = dateFormatter.dateFromString(dateTaken)
                        let newPhoto = FlickrPhoto()
                        newPhoto.url = url
                        newPhoto.date = date
                        newPhoto.latitude.value = Double(latitudeString)
                        newPhoto.longitude.value = Double(longitudeString)
                        try! realm.write {
                            realm.add(newPhoto)
                        }
                        
                    }
                    else {
                        print ("Error unwrapping Flickr results")
                    }
                }
                completion(nil)
                
                
                // Now download images data for the skeletal photos
                downloadImageDataForPhotos(){ error in
                    completion(error)
                }
        }
    
    }
    
    /**
     Download image data for each Flickr result
     
     - Parameters:
        - completion: The completion handler to call. Will pass nil if no error occurred
     */
    private static func downloadImageDataForPhotos(completion: (NSError?) -> Void) {
        
        let realm = try! Realm()
        var count = realm.objects(FlickrPhoto.self).count
        var allPhotosDownloadedSuccessfully = true
        
        // Iterate through Flickr results and initiate a download
        for flickrResult in realm.objects(FlickrPhoto.self) {
            downloadImageDataForPhoto(flickrResult){ data, error in
                
                if let _ = error {
                    allPhotosDownloadedSuccessfully = false
                }
                else {
                    try! realm.write {
                        flickrResult.photo = data!
                    }
                }
                count -= 1
                
                // If any images failed to download, alert the caller via the completion handler
                if count == 0 {
                    if allPhotosDownloadedSuccessfully {
                        completion(nil)
                    } else {
                        completion(NSError(domain: "downloadImageDataForPhotos", code: 0, userInfo: nil))
                    }
                }
            }
        }
    }
    
    
    /**
     Download image data for a specific FlickrPhoto
     
     - Parameters:
        - photo: The FlickrPhoto to download data for
        - completion: The completion handler to call after the download completes (or fails)
     */
    private static func downloadImageDataForPhoto(photo: FlickrPhoto, completion: (NSData?, NSError?) -> Void){
        
        
        request(.GET,photo.url!).response(){ _, _, data, error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(data, nil)
            }
            
        }
    }

}
