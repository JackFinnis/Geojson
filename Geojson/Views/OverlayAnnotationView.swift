//
//  OverlayAnnotationView.swift
//  Geojson
//
//  Created by Jack Finnis on 12/02/2025.
//

import MapKit

class OverlayAnnotationView: MKAnnotationView {
    private let label = UILabel()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabel()
    }
    
    private func setupLabel() {
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .black
        label.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            if let annotation {
                label.text = annotation.title ?? nil
            }
        }
    }
}
