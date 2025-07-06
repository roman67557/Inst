//
//  DetailedCollectionViewCell.swift
//  ??
//
//  Created by Роман on 04.02.2022.
//

import UIKit

class DetailedCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
  
  //MARK: - Public Properties
  
  static var identifier = "DetailedCell"
  public let imgView = UIImageView()
  
  //MARK: - Private Properties
  
  private let activityIndicatorView = UIActivityIndicatorView(style: .large)
  private let scrollImg = UIScrollView()
  private var loadImageTask: Task<Void, Never>?
  private var presenter: DetailedViewPresenterProtocol?
  
  //MARK: - Public Methods
  
  public func configure<T>(with photo: T, and presenter: DetailedViewPresenterProtocol?) {
    self.presenter = presenter
    
    addSubViews()
    setupScroll()
    setupConstraints()
    
    if photo is Results {
      let result = photo as? Results
      
      guard let string = result?.urls.full,
            let url = URL(string: string),
            let height = result?.height,
            let width = result?.width else { return }
      
//      imgView.generateImage(height: height, width: width)
//      imgView.image = .background
      setupImageView(url: url)
    } else {
      guard let shootedImage = photo as? ShooterdImages else { return }
      setupImageView(shootedImage: shootedImage)
    }
  }
  
  //MARK: - Private Methods
  
  private func addSubViews() {
    self.addSubview(scrollImg)
    scrollImg.addSubview(imgView)
    addSubview(activityIndicatorView)
    
    [scrollImg, imgView, activityIndicatorView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
  }
  
  private func setupScroll() {
    scrollImg.delegate = self
    scrollImg.alwaysBounceVertical = false
    scrollImg.alwaysBounceHorizontal = false
    scrollImg.showsVerticalScrollIndicator = false
    scrollImg.showsHorizontalScrollIndicator = false
    scrollImg.isScrollEnabled = false
    scrollImg.flashScrollIndicators()
    
    scrollImg.minimumZoomScale = 1.0
    scrollImg.maximumZoomScale = 4.0
    
    let doubleTapGest = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView(recognizer:)))
    doubleTapGest.numberOfTapsRequired = 2
    scrollImg.addGestureRecognizer(doubleTapGest)
  }
  
  private func setupImageView(url: URL) {
    loadImageTask?.cancel()
    
    loadImageTask = Task { [weak self] in
      self?.imgView.contentMode = .scaleAspectFit
      self?.imgView.image = .background
      self?.activityIndicatorView.startAnimating()
      do {
        try await self?.imgView.setImage(by: url)
        if Task.isCancelled { return }
      } catch {
        presenter?.openAlert(error: error.localizedDescription)
        if Task.isCancelled { return }
        self?.imgView.image = .background
      }
      
      self?.activityIndicatorView.stopAnimating()
    }
  }
  
  private func setupImageView(shootedImage: ShooterdImages) {
    guard
        let string = shootedImage.fileUrl,
        let url = URL(string: string)
      else { return }
      activityIndicatorView.startAnimating()

      getData(from: url) { [weak self] data, _, _ in
          self?.activityIndicatorView.stopAnimating()

          let image = UIImage(data: data ?? Data())
          self?.imgView.image = image
          self?.imgView.contentMode = .scaleAspectFit
      }
  }
  
  @objc private func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
    if (scrollImg.zoomScale > scrollImg.minimumZoomScale) {
      scrollImg.setZoomScale(scrollImg.minimumZoomScale, animated: true)
    } else {
      scrollImg.setZoomScale(scrollImg.maximumZoomScale, animated: true)
    }
  }
  
  private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
    var zoomRect = CGRect.zero
    zoomRect.size.height = imgView.frame.size.height
    zoomRect.size.width  = imgView.frame.size.width
    let newCenter = imgView.convert(center, from: scrollImg)
    zoomRect.origin.x = newCenter.x
    zoomRect.origin.y = newCenter.y
    return zoomRect
  }
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return self.imgView
  }
  
  private func setupConstraints() {
    scrollImg.topAnchor.constraint(equalTo: topAnchor).isActive = true
    scrollImg.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    scrollImg.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    scrollImg.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    
    imgView.centerXAnchor.constraint(equalTo: scrollImg.centerXAnchor).isActive = true
    imgView.centerYAnchor.constraint(equalTo: scrollImg.centerYAnchor).isActive = true
    imgView.widthAnchor.constraint(equalToConstant: frame.width).isActive = true
    imgView.heightAnchor.constraint(equalToConstant: frame.height).isActive = true
    
    activityIndicatorView.centerXAnchor.constraint(equalTo: imgView.centerXAnchor).isActive = true
    activityIndicatorView.centerYAnchor.constraint(equalTo: imgView.centerYAnchor).isActive = true
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    imgView.image = nil
    scrollImg.setZoomScale(1, animated: true)
  }
  
  func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
      URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
  }
}
