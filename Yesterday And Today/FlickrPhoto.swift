//
//  FlickrPhoto.swift
//  Yesterday And Today
//
//  Created by Tim on 10/09/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import RealmSwift

class FlickrPhoto: Object {
    
    dynamic var url: String?
    dynamic var photo: NSData?
    var date: NSDate?
    var latitude: Double?
    var longitude: Double?

}
