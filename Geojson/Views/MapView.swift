//
//  FileView.swift
//  Geojson
//
//  Created by Jack Finnis on 11/03/2024.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    let mapView = MKMapView()
    
    @Binding var trackingMode: MKUserTrackingMode
    @Binding var lookAroundScene: MKLookAroundScene?
    let data: GeoData
    let mapStandard: Bool
    let preview: Bool
    let fail: (GeoError) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = !preview
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.isPitchEnabled = true
        mapView.selectableMapFeatures = [.physicalFeatures, .pointsOfInterest]
        mapView.layoutMargins = .init(length: preview ? -25 : 5)
        mapView.showsUserTrackingButton = !preview
        mapView.pitchButtonVisibility = preview ? .hidden : .visible
        
        mapView.addAnnotations(data.points)
        mapView.addOverlay(MKMultiPolyline(data.polylines), level: .aboveRoads)
        mapView.addOverlay(MKMultiPolygon(data.polygons), level: .aboveRoads)
        mapView.setVisibleMapRect(data.rect, edgePadding: .init(length: preview ? 35 : 10), animated: false)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        mapView.addGestureRecognizer(longPressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.preferredConfiguration = mapStandard ? MKStandardMapConfiguration(elevationStyle: .realistic) : MKHybridMapConfiguration(elevationStyle: .realistic)
        mapView.setUserTrackingMode(trackingMode, animated: true)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        @AppState("visitedCoords") var visitedCoords = Set<CLLocationCoordinate2D>()
        
        let parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            parent.trackingMode = mode
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            let color = UIColor(Color.orange)
            let lineWidth = parent.preview ? 2.0 : 3.0
            if let multiPolyline = overlay as? MKMultiPolyline {
                let renderer = MKMultiPolylineRenderer(multiPolyline: multiPolyline)
                renderer.lineWidth = lineWidth
                renderer.strokeColor = color
                return renderer
            } else if let multiPolygon = overlay as? MKMultiPolygon {
                let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
                renderer.lineWidth = lineWidth
                renderer.strokeColor = color
                renderer.fillColor = color.withAlphaComponent(0.1)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func getButton(systemName: String) -> UIButton {
            let button = UIButton()
            let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: Constants.size/2))
            let image = UIImage(systemName: systemName, withConfiguration: config)
            button.setImage(image, for: .normal)
            button.frame.size = CGSize(width: Constants.size, height: Constants.size)
            return button
        }
        
        func getAction(title: String, systemImage: String, destructive: Bool = false, action: @escaping () -> Void) -> UIAction {
            UIAction(title: title, image: UIImage(systemName: systemImage), attributes: destructive ? .destructive : []) { _ in action() }
        }
        
        func refreshAnnotation(_ annotation: MKAnnotation) {
            parent.mapView.deselectAnnotation(annotation, animated: true)
            parent.mapView.removeAnnotation(annotation)
            parent.mapView.addAnnotation(annotation)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            if let point = annotation as? Point,
               let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as? MKMarkerAnnotationView {
                let visited = visitedCoords.contains(point.coordinate)
                
                marker.canShowCallout = true
                marker.titleVisibility = parent.preview ? .hidden : .adaptive
                marker.displayPriority = .required
                marker.glyphText = point.index.map(String.init)
                marker.markerTintColor = UIColor(visited ? .blue : .orange)
                
                var actions = [UIMenuElement]()
                if visited {
                    actions.append(getAction(title: "Undo Visited", systemImage: "minus.circle", destructive: true) {
                        self.visitedCoords.remove(point.coordinate)
                        self.refreshAnnotation(point)
                    })
                } else {
                    actions.append(getAction(title: "Mark as Visited", systemImage: "checkmark.circle") {
                        self.visitedCoords.insert(point.coordinate)
                        self.refreshAnnotation(point)
                    })
                }
                if !point.isDroppedPin,
                   let url = point.googleURL,
                   UIApplication.shared.canOpenURL(url) {
                    actions.append(getAction(title: "Info", systemImage: "safari") {
                        UIApplication.shared.open(url)
                    })
                }
                actions.append(getAction(title: "Look Around", systemImage: "binoculars") {
                    Task {
                        await self.lookAround(coord: point.coordinate)
                    }
                })
                actions.append(getAction(title: "Get Directions", systemImage: "arrow.triangle.turn.up.right.circle") {
                    Task {
                        await self.openInMaps(annotation: point)
                    }
                })
                
                let menu = getButton(systemName: "ellipsis.circle")
                menu.menu = UIMenu(children: actions)
                menu.preferredMenuElementOrder = .fixed
                menu.showsMenuAsPrimaryAction = true
                marker.rightCalloutAccessoryView = menu
                
                return marker
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didDeselect annotation: any MKAnnotation) {
            if let point = annotation as? Point,
               point.isDroppedPin {
                mapView.removeAnnotation(point)
            }
        }
        
        func lookAround(coord: CLLocationCoordinate2D) async {
            do {
                parent.lookAroundScene = try await MKLookAroundSceneRequest(coordinate: coord).scene
                guard parent.lookAroundScene != nil else { throw GeoError.lookAround }
            } catch {
                print(error)
                parent.fail(.lookAround)
            }
        }
        
        func openInMaps(annotation: MKAnnotation) async {
            do {
                let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                if let point = annotation as? Point {
                    guard let placemark = try await CLGeocoder().reverseGeocodeLocation(point.coordinate.location).first else { return }
                    let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                    mapItem.name = point.title ?? mapItem.name
                    mapItem.openInMaps(launchOptions: launchOptions)
                } else if let feature = annotation as? MKMapFeatureAnnotation {
                    let mapItem = try await MKMapItemRequest(mapFeatureAnnotation: feature).mapItem
                    mapItem.openInMaps(launchOptions: launchOptions)
                } else if let _ = annotation as? MKUserLocation {
                    MKMapItem.forCurrentLocation().openInMaps()
                }
            } catch {
                print(error)
                parent.fail(.lookAround)
            }
        }
        
        @objc
        func handleLongPress(_ press: UILongPressGestureRecognizer) {
            let mapView = parent.mapView
            guard press.state == .began else { return }
            let location = press.location(in: mapView)
            let coord = mapView.convert(location, toCoordinateFrom: mapView)
            let point = Point(coordinate: coord, title: "Dropped Pin")
            mapView.addAnnotation(point)
            mapView.selectAnnotation(point, animated: true)
            Haptics.tap()
        }
    }
}
