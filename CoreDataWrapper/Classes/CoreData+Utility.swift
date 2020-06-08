//  Created by Axel Ancona Esselmann on 4/7/20.
//  Copyright © 2020 Axel Ancona Esselmann. All rights reserved.
//

import CoreData

public protocol CoreDataManaged {
    init?(managedObject managed: NSManagedObject)
    static var entityName: String { get }
    func set(in managedContext: NSManagedObjectContext) throws
}

public enum CoreDataError: Error {
    case unknownEntityName
}
