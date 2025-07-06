//
//  SixthViewController.swift
//  wq
//
//  Created by Роман on 23.11.2021.
//

import UIKit
import CoreData

protocol Animation: AnyObject {}

final class UserViewController: UIViewController, Animation {
  // Presenter
  var presenter: UserViewPresenterProtocol!
  
  // Private
  private let fetchedResultController = DatabaseHandler.shared.fetchedResultsController(entityName: "ShooterdImages", keyForSort: "date")
  private var operations = [BlockOperation]()
  private let myPhotoImageView = UIImageView()
  private var index: Int?
  
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: (view.frame.width/3)-1, height: (view.frame.width/3)-1)
    layout.sectionInset = .init(top: 0, left: 0, bottom: 0, right: 0)
    layout.minimumInteritemSpacing = 1
    layout.minimumLineSpacing = 1
    layout.scrollDirection = .vertical
    
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.register(SmallCollectionViewCell.self, forCellWithReuseIdentifier: SmallCollectionViewCell.identifier)
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.backgroundColor = .systemGray6
    return collectionView
  }()
  
  //MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = .white
    navigationItem.title = "user"
    self.navigationController?.navigationBar.prefersLargeTitles = true
    
    navigationController?.delegate = self
    
    setup()
  }
  
  deinit {
    print("user deinit")
  }
  
  //MARK: - Private Methods
  
  private func setup() {
    addSubViews()
    setupFetchedResultController()
    rightBarItem()
    createProfileImageView()
    setupConstraints()
  }
  
  private func addSubViews() {
    [myPhotoImageView,
     collectionView].forEach { elem in
      view.addSubview(elem)
      elem.translatesAutoresizingMaskIntoConstraints = false
    }
  }
  
  private func setupFetchedResultController() {
    fetchedResultController.delegate = self
    try? fetchedResultController.performFetch()
  }
  
  private func rightBarItem() {
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openCamera))
    navigationItem.rightBarButtonItem?.tintColor = .black
  }
  
  private func createProfileImageView() {
    guard let image = UIImage(named: "me") else { return }
    
    //        guard let data = myPhoto.img else { return }
    //        guard let image = UIImage(data: data) else { return }
    
    myPhotoImageView.image = image
    myPhotoImageView.backgroundColor = UIColor.systemGray5
    myPhotoImageView.layer.cornerRadius = 50  //myPhotoImageView.bounds.height / 2
    myPhotoImageView.clipsToBounds = true
    myPhotoImageView.isUserInteractionEnabled = true
    myPhotoImageView.contentMode = .scaleAspectFill
    
    let gesture = UITapGestureRecognizer(target: self,
                                         action: #selector(moveToProfilePhoto))
    myPhotoImageView.addGestureRecognizer(gesture)
  }
  
  private func setupConstraints() {
    myPhotoImageView.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true
    myPhotoImageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
    myPhotoImageView.heightAnchor.constraint(equalToConstant: 100.0).isActive = true
    myPhotoImageView.widthAnchor.constraint(equalToConstant: 100.0).isActive = true
    
    collectionView.topAnchor.constraint(equalTo: self.myPhotoImageView.bottomAnchor, constant: self.view.frame.height / 20).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
  }
  
}

//MARK: - Extensions

extension UserViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let sections = fetchedResultController.sections else { return 0 }
    return sections[section].numberOfObjects
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SmallCollectionViewCell.identifier, for: indexPath) as? SmallCollectionViewCell,
          let shootedImage = fetchedResultController.object(at: indexPath) as? ShooterdImages else { return UICollectionViewCell() }
    cell.configure(with: shootedImage, and: nil)
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    var shootedImages = [ShooterdImages]()
    let _ = fetchedResultController.fetchedObjects?.map({
      guard let shootedImage = $0 as? ShooterdImages else { return }
      shootedImages.append(shootedImage)
    })
    let type = Types.shooterdImages(shootedImages)

    self.index = indexPath.item
    presenter?.openDetails(img: type, view: self, index: indexPath.item)
  }
  
}

extension UserViewController: UserViewProtocol {
  @objc func moveToProfilePhoto(_ sender: Any) {
    presenter?.moveToProfilePhoto(view: self)
  }
  
  @objc private func openCamera(_ sender: Any) {
    presenter?.openCamera(view: self)
  }
  
}

extension UserViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
    switch operation {
    case .push:
      guard let cell = collectionView.cellForItem(at: IndexPath(row: index ?? 0, section: 0)) as? SmallCollectionViewCell,
            let selectedLayout = self.collectionView.layoutAttributesForItem(at: IndexPath(item: index ?? 0, section: 0)),
            let image = cell.searchPageImageView.image else { return .none }
      
      let selectedCellFrame = collectionView.convert(selectedLayout.frame, to: collectionView.superview)
      
      return Present(image: image, originframe: selectedCellFrame)
      
    case .pop:
      let detailedVC = fromVC as? DetailedSearchViewController
      guard let indexPath = detailedVC?.collectionView.indexPathsForVisibleItems.first,
            let cell = detailedVC?.collectionView.cellForItem(at: indexPath) as? DetailedCollectionViewCell,
            let selectedLayout = self.collectionView.layoutAttributesForItem(at: indexPath) else { return .none }
      let returningCellFrame = self.collectionView.convert(selectedLayout.frame, to: self.collectionView.superview)
      
      return Dismiss(finalFrame: returningCellFrame, image: cell.imgView.image ?? UIImage())
      
    default:
      return .none
    }
  }
  
}

extension UserViewController: NSFetchedResultsControllerDelegate {
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    operations = []
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    
    switch type {
    case .insert:
      guard let indexPath = newIndexPath else { return }
      operations.append(BlockOperation(block: { [weak self] in
        self?.collectionView.insertItems(at: [indexPath])
      }))
      
    case .update:
      operations.append(BlockOperation(block: { [weak self] in
        guard let indexPath = indexPath else { return }
        let photo = self?.fetchedResultController.object(at: indexPath) as? ShooterdImages
        let cell = self?.collectionView.cellForItem(at: indexPath) as? SmallCollectionViewCell
        cell?.configure(with: photo, and: nil)
      }))
      
    case .move:
      operations.append(BlockOperation(block: { [weak self] in
        DispatchQueue.main.async {
          guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
          self?.collectionView.moveItem(at: indexPath, to: newIndexPath)
        }
      }))
      
    case .delete:
      operations.append(BlockOperation(block: { [weak self] in
        guard let indexPath = indexPath else { return }
        self?.collectionView.deleteItems(at: [indexPath])
      }))
      
    @unknown default:
      fatalError()
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    DispatchQueue.main.async { [unowned self] in
      for operation in self.operations {
        operation.start()
      }
    }
  }
}
