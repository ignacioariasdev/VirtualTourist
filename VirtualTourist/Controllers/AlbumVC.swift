//
//  AlbumVC.swift
//  VirtualTourist
//
//  Created by Marlhex on 2020-06-05.
//  Copyright © 2020 Ignacio Arias. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class AlbumVC: UIViewController {

	@IBOutlet weak var mapView: MKMapView!

	@IBOutlet weak var resetButton: UIButton!

	@IBOutlet weak var collectionView: UICollectionView!

	var pin: Pin!

	private var coordinates: CLLocationCoordinate2D!

	private var fetchedResultsController: NSFetchedResultsController<Photo>!

	var dataController: DataController!

	private let reuseIdentifier = "PhotoViewCell"


	override func viewDidLoad() {
		super.viewDidLoad()
		// This map view should not be interactive
		mapView.isUserInteractionEnabled = false

		coordinates = pin.coordinate

		mapView.setCenter(coordinates, animated: true)
		mapView.addAnnotation(pin)

		// Initialize the fetchResultsController
		initializeFecthResultsController()

		// Get photos
		getPhotos()
	}

	private func getPhotos() {
		// Decide if we need to retrieve photos from Flickr
		if fetchedResultsController.fetchedObjects?.isEmpty ?? true {
			Client.getRandomPhotos(lat: coordinates.latitude, lng: coordinates.longitude) { (photos, error) in
				if let photos = photos {
					self.addPhotosInfoCoreData(photos: photos)

					self.collectionView.reloadData()
				} else {
					// Show the user a proper error message
				}
			}

		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		fetchedResultsController = nil
	}

	private func initializeFecthResultsController() {
		let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
		let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
		let predicate = NSPredicate(format: "pin == %@", pin)
		fetchRequest.sortDescriptors = [sortDescriptor]
		fetchRequest.predicate = predicate
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
		fetchedResultsController.delegate = self
		do {
			try fetchedResultsController.performFetch()
		} catch {
			fatalError("The fetch could not be performed: \(error.localizedDescription)")
		}
	}

	private func getData(from photo: Photo, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
		if let data = photo.imageData {
			completion(data, nil, nil)
		} else {
			URLSession.shared.dataTask(with: URL(string: photo.imageURL!)!, completionHandler: completion).resume()
		}
	}

	@IBAction func resetAlbum(_ sender: Any) {
		fetchedResultsController.fetchedObjects?.forEach({ (photo) in
			dataController.viewContext.delete(photo)

			try? dataController.viewContext.save()
		})

		collectionView.reloadData()

		// Get all photos again
		getPhotos()
	}


	private func addPhotosInfoCoreData(photos: [String]) {
		photos.forEach { (photoUrl) in
			let photo = Photo(context: dataController.viewContext)
			photo.imageURL = photoUrl
			photo.pin = pin // Associate each photo with the correspond pin

			dataController.viewContext.insert(photo)

			try? dataController.viewContext.save()
		}
	}
}

extension AlbumVC: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return fetchedResultsController.sections?[section].numberOfObjects ?? 0
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoViewCell

		let photo = fetchedResultsController.object(at: indexPath)

		getData(from: photo) { data, response, error in
			guard let data = data, error == nil else { return }

			DispatchQueue.main.async() {
				cell.photoView.image = UIImage(data: data)
			}
		}

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		// Remove the pin from Core Data and collection view
		let photoToDelete = fetchedResultsController.object(at: indexPath)

		dataController.viewContext.delete(photoToDelete)

		try? dataController.viewContext.save()

		collectionView.reloadData()
	}
}


extension AlbumVC: NSFetchedResultsControllerDelegate {
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
			case .insert:
				collectionView.insertItems(at: [newIndexPath!])
				break
			case .delete:
				collectionView.deleteItems(at: [indexPath!])
				break
			default:
				break
		}
	}
}
