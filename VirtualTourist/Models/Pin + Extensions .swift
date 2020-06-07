//
//  Pin + Extensions .swift
//  VirtualTourist
//
//  Created by Marlhex on 2020-06-05.
//  Copyright © 2020 Ignacio Arias. All rights reserved.
//

import Foundation
import MapKit

extension Pin: MKAnnotation {
	public var coordinate: CLLocationCoordinate2D {
		let lat = CLLocationDegrees(latitude)

		let long = CLLocationDegrees(longitude)

		return CLLocationCoordinate2D(latitude: lat, longitude: long)
	}
}
