//
//  DatabaseHandler.swift
//  
//
//  Created by Роман on 16.04.2022.
//

import Foundation
import CoreData

final class DatabaseHandler {
  
  static let shared = DatabaseHandler()
  
  public func fetchedResultsController(entityName: String, keyForSort: String) -> NSFetchedResultsController<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    let sortDescriptor = NSSortDescriptor(key: keyForSort, ascending: true)
    
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: DatabaseHandler.shared.persistentContainer.viewContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
    
    return fetchedResultsController
  }
  
  public func saveImage(imgData: Data?, date: String) {
    let context = persistentContainer.viewContext
    guard let photoEntity = NSEntityDescription.entity(forEntityName: "ShooterdImages", in: context) else { return }
    
    let newImage = NSManagedObject(entity: photoEntity, insertInto: context)
    
    let fileManager = FileManager.default
    let tempDirectoryURL = fileManager.temporaryDirectory
    let uniqueFileName = UUID().uuidString
    let fileURL = tempDirectoryURL.appendingPathComponent(uniqueFileName)
    
    try? imgData?.write(to: fileURL)
    
    newImage.setValue(fileURL, forKey: "url")
    newImage.setValue(date, forKey: "date")
    
    self.saveContext()
  }
  
  public func deleteData() {
    let manageContent = persistentContainer.viewContext
    
    let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ShooterdImages")
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
    
    do {
      try manageContent.execute(deleteRequest)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  // MARK: - Core Data stack
  
  lazy var persistentContainer: NSPersistentContainer = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
     */
    let container = NSPersistentContainer(name: "Inst")
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        
        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
  // MARK: - Core Data Saving support
  
  func saveContext () {
    let context = persistentContainer.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
  
}
