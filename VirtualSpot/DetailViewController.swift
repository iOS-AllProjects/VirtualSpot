//
//  DetailViewController.swift
//  VirtualSpot
//
//  Created by Etjen Ymeraj on 3/14/17.
//  Copyright © 2017 Etjen Ymeraj. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import Alamofire

class DetailViewController: ViewController {
    //MARK: - Outlets
    @IBOutlet weak var detailMapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    //MARK: - Properties
    var pin: Pin?
    var totalNumberOfPhotos: Int = 0
    var tempPhotoContainer = [UIImage]() { didSet { performUIUpdatesOnMain{ self.refresh() }}}
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI(){
        if let pin = pin{
            // Number of photos
            totalNumberOfPhotos = (pin.photos?.count)!
            // Display Pin
            displayPinOnMap(pin: pin)
            // Check if the pin already has photos
            if (totalNumberOfPhotos > 0){
                displayPhotosInCollectionViewFromPath(pin: pin)
            } else{
                displayPhotosInCollectionViewFromFlickr(pin: pin)
            }
        }
    }
    
    func displayPinOnMap(pin: Pin){
        //Create Pin Annotation
        let annotation = MKPointAnnotation()
        //Set its Coordinate based on Pin coordinate
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        // Add to Map
        detailMapView.addAnnotation(annotation)
        // Adjust zoom level for the map and add the pin to it
        let span = MKCoordinateSpanMake(0.06, 0.06)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        detailMapView.setRegion(region, animated: true)
    }
    
    func displayPhotosInCollectionViewFromPath(pin: Pin){
        for photo in pin.photos!.allObjects{
            let aPhoto = photo as! Photo
            let image = UIImage(contentsOfFile: aPhoto.imagePath!)
            self.tempPhotoContainer.append(image!)
        }
        self.newCollectionButton.isEnabled = true
    }
    
    func displayPhotosInCollectionViewFromFlickr(pin: Pin){
        Client.sharedInstance.getResponseFromFlickr(pin: pin, resultHandler: { (result) in
            Client.sharedInstance.getUrlFromResponse(data: result, pin: pin, resultHandler: { (result) in
                self.totalNumberOfPhotos = result!.count
                for url in result! {
                    Client.sharedInstance.downloadImagesFromUrl(photoURLString: url, pin: pin, resultHandler:  { (result) in
                        let downloadedImage = result!
                        self.tempPhotoContainer.append(downloadedImage)
                    })
                }
                self.newCollectionButton.isEnabled = true
            })
        })
    }

    
    @IBAction func downloadNewPhotos(_ sender: Any) {
        if let pin = pin{
            // Reset
            self.newCollectionButton.isEnabled = false
            self.totalNumberOfPhotos = 0
            self.tempPhotoContainer.removeAll()
            for photo in pin.photos!.allObjects{
                let aPhoto = photo as! Photo
                do { try FileManager.default.removeItem(atPath: aPhoto.imagePath!) } catch { print("error") }
                CoreDataStack.shared.context.delete(photo as! NSManagedObject)
            }
            // Load Again
            displayPhotosInCollectionViewFromFlickr(pin: pin)
        }
    }
    
    func refresh(){
        self.photoCollectionView.reloadData()
    }
}

    //MARK: - UICollectionViewDelegate
extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalNumberOfPhotos  
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Get Cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        // Check if we are in range
        if self.tempPhotoContainer.count >= indexPath.item + 1 {
            cell.image.image = self.tempPhotoContainer[indexPath.item]
            cell.activityIndicator.isHidden = true
            }else{
            cell.image.image = nil
            }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.newCollectionButton.isEnabled == false {
            print("Please wait until all photos are downloaded before removing one.")
        }else {
            // Update the total number of photos
            self.totalNumberOfPhotos -= 1
            // Remove the image from the array
            self.tempPhotoContainer.remove(at: indexPath.item)
            // Remove the image from the collection view
            self.photoCollectionView.deleteItems(at: [indexPath])
            // Remove the photo object from Core Data
            let allPhotoObjects = self.pin?.photos?.allObjects
            let photoObject = allPhotoObjects?[indexPath.item] as? Photo
            // Remove Image from Path
            do { try FileManager.default.removeItem(atPath: (photoObject?.imagePath!)!) } catch { print("error") }
            // Save Changes
            CoreDataStack.shared.context.delete(photoObject!)
            CoreDataStack.shared.saveContext()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width/3.2, height: collectionView.bounds.width/3.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
}
