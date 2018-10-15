//
//  ViewController.swift
//  mobilytics
//
//  Created by Xiao Li on 9/24/18.
//  Copyright © 2018 Xiao Li. All rights reserved.
//

// 问题1: search bar点了一个地址之后fill到search bar里 done
// 问题2: search bar点了一个地址后为啥不center到该地址要跳回来？？好像模拟器上就可以center到新地址，手机上不行。想法：判断是否是first launch但不行。还有thread总报异常 + 如果search完地址不打空格直接点tableview的cell会跳到错误的地址... done
// zoom放大一些 done
// 问题3: 写一个方法，take两个address然后实现animation，暂时用点就可以
// 问题4：实现navigation bar，先有一个home button，左边放一个marker，点home跳到地图界面
// 问题5: navigation icon写在search bar里面，跟google map一样
// 问题6: tapGesture和annotation didSelect conflict  done

import UIKit
import Mapbox
import MapKit
import CoreLocation
import MapboxGeocoder

let MapboxAccessToken = "pk.eyJ1IjoibGl4aWFvOTAwOTIxIiwiYSI6ImNqbHVkNnlvcjBpMHIzd29kMXExd2RweGQifQ.PdaL8KX_tijW_ADH21BO0Q"

class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    var locationManager:CLLocationManager!
    var currentLocation:CLLocation!
    var mapView:MGLMapView!
    var tap = UITapGestureRecognizer()
    var gestureRecognizer = UILongPressGestureRecognizer()
    
    var searchBar: UISearchBar!
    //var resultsLabel: UILabel!
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    
    var dropDownList: UITableView!
    var selectCoordinate = [GeocodedPlacemark]()
    
    var search_datas = [String]()
    var searchActive: Bool = false
    // a global annotation, everytime user longpress map assign global marker to new position
    var annotation = MGLPointAnnotation()
    var selectLatitude: CLLocationDegrees!
    var selectLongtitude: CLLocationDegrees!
    
    var multipleAnnotations = [MGLPointAnnotation]()
   
    //let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
    var firstLaunch: Bool = true
    
    var timer: Timer?
    var polylineSource: MGLShapeSource?
    var currentIndex = 1
    var allCoordinates: [CLLocationCoordinate2D]!
    
    var selectAnnotation: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MGLAccountManager.accessToken = MapboxAccessToken
        
        self.multipleAnnotations.reserveCapacity(5)
        
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
        view.addSubview(mapView)
        mapView.delegate = self
        
        allCoordinates = coordinates()

        // Allow the map view to display the user's location
        mapView.showsUserLocation = true
        
//        resultsLabel = UILabel(frame: CGRect(x: 10, y: 20, width: view.bounds.size.width - 20, height: 30))
//        resultsLabel.autoresizingMask = .flexibleWidth
//        resultsLabel.adjustsFontSizeToFitWidth = true
//        resultsLabel.backgroundColor = UIColor.white.withAlphaComponent(0.5)
//        resultsLabel.isUserInteractionEnabled = false
//        view.addSubview(resultsLabel)
        //print(self.resultsLabel.text ?? "")
        
        geocoder = Geocoder(accessToken: MapboxAccessToken)
        
        // tap gesture to didsmiss keyword
        tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // longpress gesture to pop up an annotation
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPin2(_:)))
        mapView.addGestureRecognizer(gestureRecognizer)
        
        self.searchBar = UISearchBar(frame: CGRect(x: 15, y: 50, width: (view.bounds.width-30), height: 50))
        self.searchBar.delegate = self
        
        mapView.addSubview(searchBar)
        
        // dropdown list when tapping on search bar
        dropDownList = UITableView(frame: CGRect(x:15 , y:100 , width: (view.bounds.width-30), height: (view.bounds.height*0.3)))
        dropDownList.register(UITableViewCell.self, forCellReuseIdentifier: "mycell")
        dropDownList.dataSource = self
        dropDownList.delegate = self
        dropDownList.isHidden = true
        mapView.addSubview(dropDownList)
        
        multiAnnotations(multipleAnnotations: &multipleAnnotations)
    }
    
    // Wait until the map is loaded before adding to the map.
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        addPolyline(to: mapView.style!)
        animatePolyline()
    }
    
    
    
    func addPolyline(to style: MGLStyle) {
        // Add an empty MGLShapeSource, we’ll keep a reference to this and add points to this later.
        let source = MGLShapeSource(identifier: "polyline", shape: nil, options: nil)
        style.addSource(source)
        polylineSource = source
        
        // Add a layer to style our polyline.
        let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        layer.lineColor = NSExpression(forConstantValue: UIColor.red)
        
        // The line width should gradually increase based on the zoom level.
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                       [14: 5, 18: 20])
        style.addLayer(layer)
    }
    
    func animatePolyline() {
        currentIndex = 1
        
        // Start a timer that will simulate adding points to our polyline. This could also represent coordinates being added to our polyline from another source, such as a CLLocationManagerDelegate.
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
    
    @objc func tick() {
        if currentIndex > allCoordinates.count {
            timer?.invalidate()
            timer = nil
            return
        }
        
        // Create a subarray of locations up to the current index.
        let coordinates = Array(allCoordinates[0..<currentIndex])
        
        // Update our MGLShapeSource with the current locations.
        updatePolylineWithCoordinates(coordinates: coordinates)
        
        currentIndex += 1
    }
    
    func updatePolylineWithCoordinates(coordinates: [CLLocationCoordinate2D]) {
        var mutableCoordinates = coordinates
        
        let polyline = MGLPolylineFeature(coordinates: &mutableCoordinates, count: UInt(mutableCoordinates.count))
        
        // Updating the MGLShapeSource’s shape will have the map redraw our polyline with the current coordinates.
        polylineSource?.shape = polyline
    }
    
    func coordinates() -> [CLLocationCoordinate2D] {
        return [
            (-122.63748, 45.52214),
            (-122.64855, 45.52218),
            (-122.6545, 45.52219),
            (-122.65497, 45.52196),
            (-122.65631, 45.52104),
            (-122.6578, 45.51935),
            (-122.65867, 45.51848),
            (-122.65872, 45.51293),
            (-122.66576, 45.51295),
            (-122.66745, 45.51252),
            (-122.66813, 45.51244),
            (-122.67359, 45.51385),
            (-122.67415, 45.51406),
            (-122.67481, 45.51484),
            (-122.676, 45.51532),
            (-122.68106, 45.51668),
            (-122.68503, 45.50934),
            (-122.68546, 45.50858),
            (-122.6852, 45.50783),
            (-122.68424, 45.50714),
            (-122.68433, 45.50585),
            (-122.68429, 45.50521),
            (-122.68456, 45.50445),
            (-122.68538, 45.50371),
            (-122.68653, 45.50311),
            (-122.68731, 45.50292),
            (-122.68742, 45.50253),
            (-122.6867, 45.50239),
            (-122.68545, 45.5026),
            (-122.68407, 45.50294),
            (-122.68357, 45.50271),
            (-122.68236, 45.50055),
            (-122.68233, 45.49994),
            (-122.68267, 45.49955),
            (-122.68257, 45.49919),
            (-122.68376, 45.49842),
            (-122.68428, 45.49821),
            (-122.68573, 45.49798),
            (-122.68923, 45.49805),
            (-122.68926, 45.49857),
            (-122.68814, 45.49911),
            (-122.68865, 45.49921),
            (-122.6897, 45.49905),
            (-122.69346, 45.49917),
            (-122.69404, 45.49902),
            (-122.69438, 45.49796),
            (-122.69504, 45.49697),
            (-122.69624, 45.49661),
            (-122.69781, 45.4955),
            (-122.69803, 45.49517),
            (-122.69711, 45.49508),
            (-122.69688, 45.4948),
            (-122.69744, 45.49368),
            (-122.69702, 45.49311),
            (-122.69665, 45.49294),
            (-122.69788, 45.49212),
            (-122.69771, 45.49264),
            (-122.69835, 45.49332),
            (-122.7007, 45.49334),
            (-122.70167, 45.49358),
            (-122.70215, 45.49401),
            (-122.70229, 45.49439),
            (-122.70185, 45.49566),
            (-122.70215, 45.49635),
            (-122.70346, 45.49674),
            (-122.70517, 45.49758),
            (-122.70614, 45.49736),
            (-122.70663, 45.49736),
            (-122.70807, 45.49767),
            (-122.70807, 45.49798),
            (-122.70717, 45.49798),
            (-122.70713, 45.4984),
            (-122.70774, 45.49893)
            ].map({CLLocationCoordinate2D(latitude: $0.1, longitude: $0.0)})
    }

    // tableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.search_datas.count
    
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mycell")
        cell?.textLabel?.text = self.search_datas[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        self.selectLatitude = self.selectCoordinate[indexPath.row].location?.coordinate.latitude
        self.selectLongtitude = self.selectCoordinate[indexPath.row].location?.coordinate.longitude
        addAnnotation(lat: self.selectLatitude, lng: self.selectLongtitude)
        mapView.setCenter(CLLocationCoordinate2D(latitude: self.selectLatitude, longitude: self.selectLongtitude), zoomLevel: 15, animated: false)
        //print(search_datas[indexPath.row])
        self.dropDownList.isHidden = true
    }
    
    // searchBar
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
        if(searchText.isEmpty){
            dropDownList.isHidden = true
            search_datas.removeAll()
            DispatchQueue.main.async {
                self.dropDownList.reloadData()
                
            }
        }else{
            dropDownList.isHidden = false
            forwardGeocoder(address: searchText)
            DispatchQueue.main.async {
                self.dropDownList.reloadData()
            }
        }
    }
    
    // query real time location array
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
            guard let placemarks = placemarks else {
                return 
            }
            self.search_datas.removeAll()
            self.selectCoordinate.removeAll()
            
            for placemark in placemarks{
                self.search_datas.append(placemark.formattedName)
//                print("appended placemark: ")
//                print(placemark.formattedName)
                self.selectCoordinate.append(placemark)
                
            }
            
            //let coordinate = placemark.location?.coordinate
            
            #if !os(tvOS)
                let formatter = CNPostalAddressFormatter()
            #endif
        }

    }
    
    // annotation
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
        
        self.mapView.setCenter(center, zoomLevel: 10, animated: true)
        locationManager.stopUpdatingLocation()
        //self.mapView.setCenter(center, animated: true)

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
    
    // function to dismissKeyboard
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        //mapView.endEditing(true)
        self.searchBar.resignFirstResponder()
        tap.cancelsTouchesInView = false
        mapView.isUserInteractionEnabled = true
        
    }
    
    
    
    func addAnnotation(lat: CLLocationDegrees, lng: CLLocationDegrees) {
        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        //annotation.title = "\(Double(round(1000*locCoord.latitude)/1000)), \(Double(round(1000*locCoord.longitude)/1000))"
        //annotation.subtitle = "random callout"
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MGLMapView, regionWillChangeAnimated animated: Bool) {
        geocodingDataTask?.cancel()
    }
    
//    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
//        geocodingDataTask?.cancel()
//        let options = ReverseGeocodeOptions(coordinate: mapView.centerCoordinate)
//        geocodingDataTask = geocoder.geocode(options) { [unowned self] (placemarks, attribution, error) in
//            if let error = error {
//                NSLog("%@", error)
//            } else if let placemarks = placemarks, !placemarks.isEmpty {
//                self.resultsLabel.text = placemarks[0].qualifiedName
//            } else {
//                self.resultsLabel.text = "No results"
//            }
//        }
//    }
    
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation){
        print("didSelect annotation           ")
        //self.searchBar.resignFirstResponder()
        let lat = annotation.coordinate.latitude
        let lng = annotation.coordinate.longitude
        
        if self.multipleAnnotations.count != 0{
            for singleAnnotation in multipleAnnotations{
                
                mapView.removeAnnotation(singleAnnotation)
            }
        }
        
        self.annotation.coordinate.latitude = lat
        self.annotation.coordinate.longitude = lng
        self.annotation.title = "\(Double(round(1000*lat)/1000)), \(Double(round(1000*lng)/1000))"
        mapView.addAnnotation(self.annotation)
//        guard let annotations = mapView.annotations else { return print("Annotations Error") }
//        if annotations.count != 0 {
//            for annotation in annotations {
//                mapView.removeAnnotation(annotation)
//            }
//        }else{}
    }
    
    func multiAnnotations(multipleAnnotations: inout [MGLPointAnnotation]){
        //print("running multiAnnotations func")
        var latitudeArray = [36.128, 36.038, 36.063, 36.056, 36.039]
        var longitudeArray = [-86.81, -86.838, -86.782, -86.836, -86.737]
        for index in 0..<5 {
            multipleAnnotations.append(MGLPointAnnotation())
            multipleAnnotations[index].coordinate = CLLocationCoordinate2D(latitude: latitudeArray[index], longitude: longitudeArray[index])
            //print("latitude: ")
            //print(multipleAnnotations[index].coordinate.latitude)
            //print("longitude: ")
            //print(multipleAnnotations[index].coordinate.longitude)
        }
        //print("total length: ")
        //print(multipleAnnotations.count)
        
        for annotation in multipleAnnotations {
            self.mapView.addAnnotation(annotation)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

