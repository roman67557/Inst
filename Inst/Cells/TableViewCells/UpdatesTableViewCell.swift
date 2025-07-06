//
//  UpdatesTableViewCell.swift
//  wq
//
//  Created by Роман on 24.12.2021.
//

import UIKit

final class UpdatesTableViewCell: UITableViewCell {
  // Internal
  static let identifier = "UpdatesTableViewCell"
  
  // Private
  private let photoImageView = UIImageView()
  private let activityIndicatorView = UIActivityIndicatorView()
  
  //MARK: - Public Methods
  
  func setup(data: ShooterdImages) {
    guard
        let date = data.date,
        let string = data.fileUrl,
        let url = URL(string: string)
    else { return }
    
    self.textLabel?.text = "\(date): user added a photo"
    self.accessoryView = activityIndicatorView
    self.activityIndicatorView.startAnimating()

    self.getData(from: url) { [weak self] data, _, _ in
        guard let self else { return }
        let img = UIImage(data: data ?? Data())
        photoImageView.contentMode = .scaleAspectFit
        photoImageView.image = img
        
        accessoryView = photoImageView
        accessoryView?.frame = CGRectMake(0, 0, 40, 40)
        selectionStyle = .none
    }
  }

  func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
    URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
  }
}
