//
//  ViewController.swift
//  mobilytics
//
//  Created by Xiao Li on 9/24/18.
//  Copyright © 2018 Xiao Li. All rights reserved.
//

// 问题4: 写一个方法take一个coordinate的list作为input，然后显示多个marker，用户点其中一个的时候其他marker消失
// 问题5: search bar实现，要有下拉列表，选中具体的某个place之后回问题3

import UIKit
import Mapbox
import MapKit
import CoreLocation
import MapboxGeocoder

let MapboxAccessToken = "pk.eyJ1IjoibGl4aWFvOTAwOTIxIiwiYSI6ImNqbHVkNnlvcjBpMHIzd29kMXExd2RweGQifQ.PdaL8KX_tijW_ADH21BO0Q"

class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    var locationManager:CLLocationManager!
    var currentLocation:CLLocation!
    var mapView:MGLMapView!
    var myLatitude = 0.0
    var myLongtitude = 0.0
    //var gestureRecognizer = UITapGestureRecognizer()
    var gestureRecognizer = UILongPressGestureRecognizer()
    var searchBar: UISearchBar!
    var resultsLabel: UILabel!
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    
    var dropDownList: UITableView!
    
    var search_datas = [String]()
    var searchActive: Bool = false
    // a global annotation, everytime user longpress map assign global marker to new position
    var annotation = MGLPointAnnotation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MGLAccountManager.accessToken = MapboxAccessToken
        
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
        mapView = MGLMapView(frame: view.bounds, styleURL: url)
        
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: self.myLatitude, longitude: self.myLongtitude), zoomLevel: 10, animated: false)
        view.addSubview(mapView)
        mapView.delegate = self
        
        // Allow the map view to display the user's location
        mapView.showsUserLocation = true
        
        resultsLabel = UILabel(frame: CGRect(x: 10, y: 20, width: view.bounds.size.width - 20, height: 30))
        resultsLabel.autoresizingMask = .flexibleWidth
        resultsLabel.adjustsFontSizeToFitWidth = true
        resultsLabel.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        resultsLabel.isUserInteractionEnabled = false
        view.addSubview(resultsLabel)
        //print(self.resultsLabel.text ?? "")
        
        geocoder = Geocoder(accessToken: MapboxAccessToken)
        
        //gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addPin2(_:)))
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPin2(_:)))
        mapView.addGestureRecognizer(gestureRecognizer)
        
        // add gesture on marker???
        // markerGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(popupCallout(_:)))
        
        self.searchBar = UISearchBar(frame: CGRect(x: 15, y: 50, width: (view.bounds.width-30), height: 50))
        self.searchBar.delegate = self
        mapView.addSubview(searchBar)
        
        //dropdown
        //let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        //let displayWidth: CGFloat = self.mapView.frame.width
       // let displayHeight: CGFloat = self.mapView.frame.height
        
        dropDownList = UITableView(frame: CGRect(x:15 , y:100 , width: (view.bounds.width-30), height: (view.bounds.height*0.5)))
        dropDownList.register(UITableViewCell.self, forCellReuseIdentifier: "mycell")
        dropDownList.dataSource = self
        dropDownList.delegate = self
        dropDownList.isHidden = true
        mapView.addSubview(dropDownList)
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if (searchActive){
        return search_datas.count
    }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mycell")
        cell?.textLabel?.text = search_datas[indexPath.row]
        return cell!
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //print(searchText)
        //var placemark_list: [GeocodedPlacemark]
        dropDownList.isHidden = false
        forwardGeocoder(address: searchText)
        
        //self.dropDownList.reloadData()
    }
    
    
    func forwardGeocoder(address:String){
        let options = ForwardGeocodeOptions(query: address)
        options.autocompletesQuery = true
        // To refine the search, you can set various properties on the options object.
        //options.allowedISOCountryCodes = ["CA"]
        //options.focalLocation = CLLocation(latitude: 45.3, longitude: -66.1)
        options.allowedScopes = [.address, .pointOfInterest]
        
        let task = geocoder.geocode(options) { (placemarks, attribution, error) in
            //print("placemarks: ")
            //print(placemarks)
            guard let placemarks = placemarks else{
                return 
            }
            
            for placemark in placemarks{
                
                self.search_datas.append(placemark.formattedName)
               // print(placemark)
            }
            
            
        
            guard let placemark = placemarks.first else {
                return
            }
            //print("address name: ")
            //print(placemark.name)
            // 200 Queen St
            //print("detail address name: ")
            //print(placemark.qualifiedName)
            // 200 Queen St, Saint John, New Brunswick E2L 2X1, Canada
            
            let coordinate = placemark.location?.coordinate
            //print("address coordination: ")
            //print("\(coordinate?.latitude), \(coordinate?.longitude)")
            // 45.270093, -66.050985
            
            #if !os(tvOS)
                let formatter = CNPostalAddressFormatter()
               // print("zipcode: ")
                //print(formatter.string(from: placemark.postalAddress!))
                // 200 Queen St
                // Saint John New Brunswick E2L 2X1
                // Canada
            #endif
        }

    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    /* center the map to user current location */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        _ = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
       
        self.mapView.setCenter(center, animated: true)
    }
    
    /* TapGesture to add an annotation according to gesture location */
    //@objc func addPin2(_ sender: UITapGestureRecognizer) {
    @objc func addPin2(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: self.mapView)
        let locCoord = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        annotation.coordinate = CLLocationCoordinate2D(latitude: locCoord.latitude, longitude: locCoord.longitude)
        //annotation.title = "\(Double(round(1000*locCoord.latitude)/1000)), \(Double(round(1000*locCoord.longitude)/1000))"
        //annotation.subtitle = "random callout"
        mapView.addAnnotation(annotation)
        
        // pop-up the callout view
        mapView.selectAnnotation(annotation, animated: false)
    }
    
    func mapView(_ mapView: MGLMapView, regionWillChangeAnimated animated: Bool) {
        geocodingDataTask?.cancel()
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        geocodingDataTask?.cancel()
        let options = ReverseGeocodeOptions(coordinate: mapView.centerCoordinate)
        geocodingDataTask = geocoder.geocode(options) { [unowned self] (placemarks, attribution, error) in
            if let error = error {
                NSLog("%@", error)
            } else if let placemarks = placemarks, !placemarks.isEmpty {
                self.resultsLabel.text = placemarks[0].qualifiedName
            } else {
                self.resultsLabel.text = "No results"
            }
        }
    }
   
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation){
        let lat = annotation.coordinate.latitude
        let lng = annotation.coordinate.longitude
        self.annotation.title = "\(Double(round(1000*lat)/1000)), \(Double(round(1000*lng)/1000))"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

