//
//  Client.swift
//  VirtualTourist
//
//  Created by Marlhex on 2020-06-06.
//  Copyright © 2020 Ignacio Arias. All rights reserved.
//

import Foundation
import MapKit

class Client {
	struct Auth {
		static let apiKey = "3b4ec9b4865511846cb341e7e56df049"
		static let secret = "913a9f659e3f7745"
	}

	class func createLatLnbBox(withLat latitude: Double, withLng longitude: Double) -> String {
		// Create a box that approximate to a 5 degree change in the lat and lng
		let minLon = max(longitude - 0.5, -180.0)
		let minLat = max(latitude  - 0.5, -90)
		let maxLon = min(longitude + 0.5, 180.0)
		let maxLat = min(latitude  + 0.5, 90.0)

		return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
	}

	enum EndPoints {
		static let base = "https://api.flickr.com/services/rest"

		case getRandomPhotos(lat: Double, lng: Double)

		private var stringValue: String {
			switch self {
				case .getRandomPhotos(let lat, let lng): return "\(EndPoints.base)?api_key=\(Auth.apiKey)&format=json&bbox=\(Client.createLatLnbBox(withLat: lat, withLng: lng))&page=\((1...10).randomElement() ?? 1)&nojsoncallback=1&method=flickr.photos.search&extras=url_n&per_page=7"
			}
		}

		var url: URL {
			return URL(string: stringValue)!
		}
	}

	class func getRandomPhotos(lat: Double, lng: Double, completion: @escaping ([String]?, Error?) -> Void) {
		let url = EndPoints.getRandomPhotos(lat: lat, lng: lng).url

		print("The url is: \(url)")

		taskForGETRequest(url: url, responseType: PhotosResponse.self) { (response, error) in
			if let response = response {
				var photoURLs = [String]()

				response.photos.photo.forEach { (singlePhoto) in
					photoURLs.append(singlePhoto.url_n)
				}

				completion(photoURLs, nil)

			} else {
				completion(nil, error)
			}
		}
	}

	class func taskForGETRequest<T: Decodable>(url: URL, responseType: T.Type, completion: @escaping (T?, Error?) -> Void) -> URLSessionTask {
		let task = URLSession.shared.dataTask(with: url) { data, response, error in
			guard let data = data else {
				DispatchQueue.main.async {
					completion(nil, error)
				}

				return
			}

			let decoder = JSONDecoder()
			do {
				let responseObject = try decoder.decode(T.self, from: data)

				DispatchQueue.main.async {
					completion(responseObject, nil)
				}

			} catch {
				DispatchQueue.main.async {
					completion(nil, error)
				}

			}
		}

		task.resume()

		return task
	}
}
