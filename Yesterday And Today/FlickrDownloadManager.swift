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
    
    
    
    static func downloadImagesFromFlickrWithParametersAndPersist(parameters: [String: String], completion: (NSError?) -> ()) {
        
        var _parameters = parameters
        
        _parameters["api_key"] = "a4ebce9cbae74391014b23471293fb42"
        _parameters["per_page"] = "50"
        _parameters["format"] = "json"
        _parameters["nojsoncallback"] = "1"
        _parameters["extras"] = "url_m,date_taken,geo"
        _parameters["method"] = "flickr.photos.search"
        _parameters["content_type"] = "6"
        
        
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
                        print ("Added empty photo")
                        
                    }
                    else {
                        print ("Error unwrapping Flickr results")
                    }
                }
                
                downloadImageDataForPhotos(){ error in
                    completion(error)
                }
                
            

        }
    
    }
    
    private static func downloadImageDataForPhotos(completion: (NSError?) -> Void) {
        
        let realm = try! Realm()
        
        var count = realm.objects(FlickrPhoto.self).count
        var allPhotosDownloadedSuccessfully = true
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
