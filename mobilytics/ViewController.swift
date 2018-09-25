//
//  ViewController.swift
//  mobilytics
//
//  Created by Xiao Li on 9/24/18.
//  Copyright © 2018 Xiao Li. All rights reserved.
//

import UIKit
import Mapbox
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    var locationManager:CLLocationManager!
    var currentLocation:CLLocation!
    var mapView:MGLMapView!
    var myLatitude = 0.0
    var myLongtitude = 0.0
    var gestureRecognizer = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        //mapView.isUserInteractionEnabled = true
        mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: self.myLatitude, longitude: self.myLongtitude), zoomLevel: 10, animated: false)
        view.addSubview(mapView)
    
        // Allow the map view to display the user's location
        mapView.showsUserLocation = true
        
        //let gestureRecognizer = UILongPressGestureRecognizer(target: self, action:(Selector(("addPin2:"))))
        gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addPin2(_:)))
        //gestureRecognizer.addTarget(self, action:#selector(addPin2(_:)))
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        _ = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
       
        self.mapView.setCenter(center, animated: true)
    }
    
    @objc func addPin2(_ sender: UITapGestureRecognizer) {
        //print("sdfdsfdsfd")
        let location = sender.location(in: self.mapView)
        let locCoord = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        //print(locCoord)
        let annotation = MGLPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: locCoord.latitude, longitude: locCoord.longitude)
        annotation.title = "abcd"
        annotation.subtitle = "random callout"
        mapView.addAnnotation(annotation)
    }
   
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation){
        print("jjksdjfsdkfsdf")
        //let annotation = MGLPointAnnotation()
        //annotation.coordinate = CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        //annotation.title = "Central Park"
        //annotation.subtitle = "The biggest park in New York City!"
        //mapView.addAnnotation(annotation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

