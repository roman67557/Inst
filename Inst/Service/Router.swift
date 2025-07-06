//
//  Router.swift
//  wq
//
//  Created by Роман on 29.01.2022.
//

import Foundation
import UIKit

protocol RouterMain {
  var tabBarController: UITabBarController { get set }
  var assemblyBuilder: BuilderProtocol { get set }
}

protocol RouterProtocol: RouterMain {
  func initialViewController()
  func moveToDetailedController(img: Types?, view: UIViewController, index: Int)
  func openCameraView(view: UIViewController)
  func openAlert(view: UIViewController, error: String)
}

final class Router: RouterProtocol {
  
  var tabBarController: UITabBarController
  var assemblyBuilder: BuilderProtocol
  
  init(tabBarController: UITabBarController, assemblyBuilder: BuilderProtocol) {
    self.tabBarController = tabBarController
    self.assemblyBuilder = assemblyBuilder
  }
  
  func initialViewController() {
    
    let mainView = assemblyBuilder.createMainModule(router: self)
    let searchView = assemblyBuilder.createSearchModule(router: self)
    let updatesView = assemblyBuilder.createUpdatesModule(router: self)
    let userView = assemblyBuilder.createUserModule(router: self)
    
    tabBarController.setViewControllers([mainView, searchView, updatesView, userView], animated: true)
    tabBarController.tabBar.isHidden = false
    
    let imagesArray = [
        UIImage(systemName: "house"),
        UIImage(systemName: "magnifyingglass"),
        UIImage(systemName: "heart"),
        UIImage(systemName: "person")
    ]
    
    let viewControllers = [0: mainView, 1: searchView, 2: updatesView, 3: userView]
    for (index, VC) in (viewControllers) {
      VC.tabBarItem = UITabBarItem(title: "", image: imagesArray[index], tag: index)
    }
  }
  
  func moveToDetailedController(img: Types?, view: UIViewController, index: Int) {
    guard let img = img else { return }
    let detailedVC = assemblyBuilder.createDetailedController(img: img, router: self, index: index)
    view.navigationController?.pushViewController(detailedVC, animated: true)
  }
  
  func openCameraView(view: UIViewController) {
    let cameraView = assemblyBuilder.createCameraViewCtonrtoller(router: self)
    view.present(cameraView, animated: true)
  }
  
  func openAlert(view: UIViewController, error: String) {
    let alert = AlertController(title: "Error", message: error, preferredStyle: .alert)
    view.present(alert, animated: true)
  }
}
