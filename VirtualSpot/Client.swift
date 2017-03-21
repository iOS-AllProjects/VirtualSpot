//
//  Client.swift
//  VirtualSpot
//
//  Created by Etjen Ymeraj on 3/16/17.
//  Copyright © 2017 Etjen Ymeraj. All rights reserved.
//

import Foundation
import Alamofire
import CoreData
import UIKit

class Client {
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack(modelName: "Model")!.context
    }
    
    // Singleton
    static let sharedInstance = Client()

    
    func getResponseFromFlickr(pin: Pin, resultHandler: @escaping (_ result: Any) -> Void)  {
        // Build the parameters for the Flickr Call
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: pin.latitude, longitude: pin.longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Per_Page: Constants.FlickrParameterValues.Per_Page, 
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        // Make a Flickr Request
        Alamofire.request(Constants.Flickr.URL, method: .get, parameters: methodParameters).responseJSON { response in
            switch response.result {
            case .failure(let error):
                print(error.localizedDescription)
                return
                
            case .success(let data):
                //self.getUrlFromResponse(data: data, pin: pin)
                resultHandler(data)
            }
        }
    }
    
    func getUrlFromResponse(data: Any, pin: Pin, resultHandler: @escaping (_ result: [String]?) -> Void){
        
        var photoUrls = [String]()
        // Check if you got back a dictionary
        guard let json = data as? [String : AnyObject] else {
            print("Failed to get expected response from Flickr.")
            return
        }
        
        // GUARD: Check for "photos" key in our result
        guard let photosDictionary = json[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
            print("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(json)")
            return
        }
        
        // GUARD: Check for "photo" key in photosDictionary
        guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
            print("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
            return
        }
        
        // GUARD: Check for "url" key in photosArray
        for photoDictionary in photosArray{
            guard (photoDictionary["url_m"] as? String) != nil else {
                print("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photosArray)")
                return
            }
        }
        
        // Check if we have photos
        if photosArray.count == 0 {
            print("No Photos Found. Search Again.")
            return
        } else {
            for photoDictionary in photosArray {
                // Get Photo URL
                let photoURLString = photoDictionary["url_m"] as! String
                photoUrls.append(photoURLString)
            }
            resultHandler(photoUrls)
        }
    }


    func downloadImagesFromUrl(photoURLString: String, pin: Pin, resultHandler: @escaping (_ result: UIImage?) -> Void){
        // Specify where to download file
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        
        Alamofire.download(
            photoURLString,
            method: .get,
            encoding: JSONEncoding.default,
            headers: nil,
            to: destination).downloadProgress(closure: { (progress) in
                //In case we need to report the download progress
            }).response(completionHandler: { (DefaultDownloadResponse) in
                //Access the DefaultDownloadResponse
                if DefaultDownloadResponse.error == nil, let imagePath = DefaultDownloadResponse.destinationURL?.path {
                    // Add Photo to Core Data
                    let addedPhoto = Photo(context: CoreDataStack.shared.context)
                    addedPhoto.imagePath = imagePath
                    addedPhoto.imageUrl = photoURLString
                    addedPhoto.pin = pin
                    // Save Changes
                    CoreDataStack.shared.saveContext()
                    // Handle Image
                    let image = UIImage(contentsOfFile: imagePath)
                    resultHandler(image)
                }
            })
        }

    // Convert the coordinates into a string
    func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
