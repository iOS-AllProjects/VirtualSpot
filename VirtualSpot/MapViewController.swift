//
//  MapViewController.swift
//  VirtualSpot
//
//  Created by Etjen Ymeraj on 3/14/17.
//  Copyright © 2017 Etjen Ymeraj. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        loadPinsInMap()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Fetch Pins
    
    func loadPinsInMap(){
        let fr = Pin.createFetchRequest()
        do {
            let pins = try CoreDataStack.shared.context.fetch(fr)
            
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                mapView.addAnnotation(annotation)
            }
        } catch {
            print("Loading pin data failed.")
        }
    }


    // MARK: - Add Pins
    @IBAction func dropPin(_ sender: UILongPressGestureRecognizer) {
        // Declare annotation
        let annotation = MKPointAnnotation()
        // Get Location where user dropped the pin
        let location = sender.location(in: mapView)
        // Convert the location into a coordinate
        annotation.coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        // Add Pin to Map
        mapView.addAnnotation(annotation)
        // Add Pin to Core Data and set its attributes
        let addedPin = Pin(context: CoreDataStack.shared.context)
        addedPin.latitude = annotation.coordinate.latitude
        addedPin.longitude = annotation.coordinate.longitude
        // Save changes
        CoreDataStack.shared.saveContext()
    }
}

    //MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pinView = MKPinAnnotationView()
        pinView.animatesDrop = true
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var selectedPin: Pin?
        if let annotation = view.annotation {
            let fr = Pin.createFetchRequest()
                do {
                    let pins = try (CoreDataStack.shared.context).fetch(fr)
            // Assign to selectedPin the pin whose coordinates correspond to the annotation
                    for pin in pins {
                        if pin.latitude == annotation.coordinate.latitude && pin.longitude == annotation.coordinate.longitude {
                            selectedPin = pin
                }
            }
        } catch {
            print("error")
            }
        }
        performSegue(withIdentifier: "pinDetailSegue", sender: selectedPin)

    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, let selectedPin = sender as? Pin {
            if identifier == "pinDetailSegue" {
                let pinDetail = segue.destination as! DetailViewController
                pinDetail.pin = selectedPin
            }
        }
    }
}
