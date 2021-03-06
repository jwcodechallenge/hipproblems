//
//  HotelViewController.swift
//  Hotelzzz
//
//  Created by Steve Johnson on 3/22/17.
//  Copyright © 2017 Hipmunk, Inc. All rights reserved.
//

import Foundation
import UIKit


class HotelViewController: UIViewController {
    var hotelName: String?
    var hotelAddress: String?
    var hotelPrice = 0
    var hotelPhotoURLString = ""
    @IBOutlet var hotelNameLabel: UILabel!
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyLabel: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hotelNameLabel.text = hotelName
        addressLabel.text = hotelAddress
        priceLabel.text = (hotelPrice != 0 ? "$\(hotelPrice)" : "")
        
        guard let url = URL(string: hotelPhotoURLString) else {
            return
        }
        
        emptyLabel.isHidden = true
        imageLoadingIndicator.startAnimating()
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { (data, response, error) in
            guard let photoData = data, let photo = UIImage(data: photoData) else {
                return
            }

            DispatchQueue.main.async {
                self.photoView.image = photo
                self.imageLoadingIndicator.stopAnimating()
            }
        }
        task.resume()
    }
}

extension HotelViewController {
    func configure(with dictionary: [AnyHashable:Any]) {
        guard let result = dictionary["result"] as? [AnyHashable:Any],
        let hotel = result["hotel"] as? [AnyHashable:Any] else { return }
        
        self.hotelName = hotel["name"] as? String
        self.hotelAddress = hotel["address"] as? String
        self.hotelPrice = result["price"] as! Int
        self.hotelPhotoURLString = hotel["imageURL"] as! String
    }
}
