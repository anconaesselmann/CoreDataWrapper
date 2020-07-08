//  Created by Axel Ancona Esselmann on 6/5/20.
//  Copyright © 2020 Axel Ancona Esselmann. All rights reserved.
//

import CoreData
import URN
import ValueTypeRepresentable

public class CoreDataWrapper {

    public enum E: Error {
        case elementNotFound
        case keyDoesNotExist
        case elementAlreadyExists
    }

    fileprivate class ContainerWrapper {
        private let container: NSPersistentContainer
        private var backgroundContext: NSManagedObjectContext?

        init(containerName: String) {
            container = NSPersistentContainer(name: containerName)
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
        }

        func nsManagedContext(for context: Context) -> NSManagedObjectContext {
            switch context {
            case .view:
                return container.viewContext
            case .background:
                if let backgroundContext = self.backgroundContext {
                    return backgroundContext
                } else {
                    let backgroundContext = container.newBackgroundContext()
                    self.backgroundContext = backgroundContext
                    return backgroundContext
                }
            }
        }
    }

    public enum Context {
        case view
        case background
    }

    private let container: ContainerWrapper

    public init(containerName: String) {
        self.container = ContainerWrapper(containerName: containerName)
    }

    @discardableResult
    public func insert<CD>(_ element: CD, in context: Context) -> Result<Void, Error> where CD: CoreDataManaged {
        let context = container.nsManagedContext(for: context)
        do {
            try element.set(in: context)
            try context.save()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    public func insert<CD>(_ element: CD, orUpdate updates: [UpdateDescriptor<CD>], in context: Context) -> Result<Void, Error> where CD: CoreDataManaged, CD: UrnIdentifyable {
        switch fetch(type(of: element), with: element.urn, in: context) {
        case .success(let existing):
            return update(existing, set: updates)
        case .failure:
            return insert(element, in: context)
        }
    }

    @discardableResult
    public func insert<CD>(_ element: CD, where selectors: [QueryDescriptor<CD>], orUpdate updates: [UpdateDescriptor<CD>], in context: Context) -> Result<Void, Error> where CD: CoreDataManaged {
        switch fetch(type(of: element))
            .query(selectors)
            .limitOne()
            .fetch(in: context)
        {
        case .success(let existing):
            return update(existing, where: selectors, set: updates)
        case .failure:
            return insert(element, in: context)
        }
    }

//    @discardableResult
//    public func insert<CD>(_ element: CD, orUpdate updates: UpdateDescriptor<CD>..., in context: Context) -> Result<Void, Error> where CD: CoreDataManaged, CD: UrnIdentifyable {
//        return insert(element, orUpdate: updates, in: context)
//    }

    @discardableResult
    public func insertUnique<CD>(_ element: CD, urnKey: CD.Keys? = nil, in context: Context = .background) -> Result<Void, Error> where CD: CoreDataManaged, CD: UrnIdentifyable {
        guard let key = urnKey ?? CD.Keys(stringValue: UrnKeys.urn.stringValue) else {
            return .failure(E.keyDoesNotExist)
        }
        guard !fetch(type(of: element))
            .query(.urn(key, equals: element.urn))
            .exists(in: context)
        else {
            return .failure(E.elementAlreadyExists)
        }
        return insert(element, in: context)
    }

    @discardableResult
    public func insertUnique<CD>(_ element: CD, in context: Context = .background, where query: QueryDescriptor<CD>...) -> Result<Void, Error> where CD: CoreDataManaged {
        guard !fetch(type(of: element))
            .query(query)
            .exists(in: context)
        else {
            return .failure(E.elementAlreadyExists)
        }
        return insert(element, in: context)
    }

    public func fetch<CD>(
        _ type: CD.Type,
        with urn: URN,
        key: CD.Keys? = nil,
        in context: Context = .view
    ) -> Result<CD, Error> where CD: CoreDataManaged, CD: UrnIdentifyable {
        guard let key = key ?? CD.Keys(stringValue: UrnKeys.urn.stringValue) else {
            return .failure(E.keyDoesNotExist)
        }
        return self.fetch(CD.self)
            .query(.urn(key, equals: urn))
            .limitOne()
            .fetch(in: context)
    }

    public func fetch<CD>(
        _ type: CD.Type,
        from startDate: Date,
        to endDate: Date? = nil,
        oldestToNewest: Bool = true,
        key: CD.Keys? = nil,
        query: [QueryDescriptor<CD>] = [],
        in context: Context = .view
    ) -> Result<[CD], Error> where CD: CoreDataManaged, CD: CodingKeyed {
        let endDate = endDate ?? Date()
        guard let key = key ?? CD.Keys(stringValue: "date") else {
            return .failure(E.keyDoesNotExist)
        }
        let sort = SortDescriptor<CD>(
            key: key,
            sorting: oldestToNewest ? .ascending : .descending
        )
        let dateQuery: [QueryDescriptor<CD>] = [
            .date(key, .greaterEqualThan, startDate),
            .date(key, .lessEqualThan, endDate)
        ]
        return self.fetch(type)
            .query(
                dateQuery + query
            )
            .sort(sort)
            .fetch(in: .view)
    }

    public func fetch<CD>(
        _ type: CD.Type,
        from startDate: Date,
        to endDate: Date? = nil,
        oldestToNewest: Bool = true,
        key: CD.Keys? = nil,
        query: QueryDescriptor<CD>...,
        in context: Context = .view
    ) -> Result<[CD], Error> where CD: CoreDataManaged, CD: CodingKeyed {
        fetch(
            type,
            from: startDate,
            to: endDate,
            oldestToNewest: oldestToNewest,
            key: key,
            query: query,
            in: context
        )
    }

    public func fetch<CD>(
        from startDate: Date,
        to endDate: Date? = nil,
        oldestToNewest: Bool = true,
        key: CD.Keys? = nil,
        query: [QueryDescriptor<CD>] = [],
        in context: Context = .view
    ) -> Result<[CD], Error> where CD: CoreDataManaged, CD: CodingKeyed {
        fetch(
            CD.self,
            from: startDate,
            to: endDate,
            oldestToNewest: oldestToNewest,
            key: key,
            query: query,
            in: context
        )
    }

    public func fetch<CD>(
        from startDate: Date,
        to endDate: Date? = nil,
        oldestToNewest: Bool = true,
        key: CD.Keys? = nil,
        query: QueryDescriptor<CD>...,
        in context: Context = .view
    ) -> Result<[CD], Error> where CD: CoreDataManaged, CD: CodingKeyed {
        fetch(
            CD.self,
            from: startDate,
            to: endDate,
            oldestToNewest: oldestToNewest,
            key: key,
            query: query,
            in: context
        )
    }

    public func fetchLatest<CD>(
        _ type: CD.Type,
        key: CD.Keys? = nil,
        in context: Context = .view
    ) -> Result<CD, Error> where CD: CoreDataManaged, CD: CodingKeyed {
        guard let key = key ?? CD.Keys(stringValue: "date") else {
            return .failure(E.keyDoesNotExist)
        }
        return self.fetch(type)
            .last(dateKey: key, in: context)
    }

    public func fetch<CD>(_ managedType: CD.Type) -> FetchRequestWrapper<CD> where CD: CoreDataManaged, CD: CodingKeyed {
        FetchRequestWrapper(
            NSFetchRequest<NSManagedObject>(
                entityName: managedType.entityName
            ),
            container: container
        )
    }

    @discardableResult
    public func update<CD>(_ element: CD, set updates: UpdateDescriptor<CD>..., in context: Context = .background) -> Result<Void, Error> where CD: CoreDataManaged, CD: UrnIdentifyable {
        update(element, set: updates, in: context)
    }

    @discardableResult
    public func update<CD>(_ element: CD, set updates: [UpdateDescriptor<CD>], in context: Context = .background) -> Result<Void, Error> where CD: CoreDataManaged, CD: UrnIdentifyable {
        guard let key = CD.Keys(stringValue: UrnKeys.urn.stringValue) else {
            return .failure(E.keyDoesNotExist)
        }
        return self.fetch(CD.self)
            .query(.urn(key, equals: element.urn))
            .limitOne()
            .update(updates, in: context)
    }

    // TODO: element not used
    @discardableResult
    public func update<CD>(_ element: CD, where selectors: [QueryDescriptor<CD>], set updates: [UpdateDescriptor<CD>], in context: Context = .background) -> Result<Void, Error> where CD: CoreDataManaged /*, CD: UrnIdentifyable*/ {
//        guard let urnKey = CD.Keys(stringValue: UrnKeys.urn.stringValue) else {
//            return .failure(E.keyDoesNotExist)
//        }
        return self.fetch(CD.self)
            .query(selectors) // .query([.urn(urnKey, equals: element.urn)] + selectors)
            .limitOne()
            .update(updates, in: context)
    }

    @discardableResult
    public func delete<CD>(type: CD.Type, where urn: URN, in context: Context = .background) -> Result<Void, Error> where CD: CoreDataManaged, CD: UrnIdentifyable {
        guard let urnKey = CD.Keys(stringValue: UrnKeys.urn.stringValue) else {
            return .failure(E.keyDoesNotExist)
        }
        return self.fetch(CD.self)
            .query(.urn(urnKey, equals: urn))
            .delete(in: context)
    }


    public struct FetchRequestWrapper<CD> where CD: CoreDataManaged, CD: CodingKeyed {
        private let fetchRequest: NSFetchRequest<NSManagedObject>
        private let container: ContainerWrapper

        fileprivate init(_ fetchRequest: NSFetchRequest<NSManagedObject>, container: ContainerWrapper) {
            self.container = container
            self.fetchRequest = fetchRequest
        }

        public func query(_ query: QueryDescriptor<CD>?...) -> Self {
            return self.query(query.compactMap { $0 })
        }

        public func query<Keyed>(_ query: [QueryDescriptor<Keyed>]) -> Self where Keyed: CodingKeyed {
            let predicates = query.compactMap { queryItem -> NSPredicate? in
                switch queryItem {
                case .urn(let key, equals: let urn):
                    let stringOperator = Comparison.equals.stringOperator
                    return NSPredicate(format: "\(key.stringValue) \(stringOperator) %@", urn.stringValue)
                case .uuid(let key, equals: let uuid):
                    let stringOperator = Comparison.equals.stringOperator
                    return NSPredicate(format: "\(key.stringValue) \(stringOperator) %@", uuid as CVarArg)
                case .string(let key, let comparison, let stringRepresentable):
                    let stringOperator = comparison.stringOperator
                    return NSPredicate(format: "\(key.stringValue) \(stringOperator) %@", stringRepresentable.stringValue)
                case .double(let key, let comparison, let doubleRepresentable):
                    let stringOperator = comparison.stringOperator
                    return NSPredicate(format: "\(key.stringValue) \(stringOperator) %f", doubleRepresentable.doubleValue)
                case .date(let key, let comparison, let dateRepresentable):
                    let stringOperator = comparison.stringOperator
                    return NSPredicate(format: "\(key.stringValue) \(stringOperator) %@", dateRepresentable.dateValue as NSDate)
                case .bool(let key, is: let boolRepresentable):
                    let stringOperator = Comparison.equals.stringOperator
                    return NSPredicate(format: "\(key.stringValue) \(stringOperator) %@", NSNumber(value: boolRepresentable.boolValue))
                }
            }

            fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
            return self
        }

        public func predicate(format predicateFormat: String, _ arguments: Any...) -> Self {
            let nsArguments: [Any] = arguments.map { argument in
                if let date = argument as? Date {
                    return date as NSDate
                } else {
                    return argument
                }
            }
            fetchRequest.predicate = NSPredicate(
                format: predicateFormat,
                argumentArray: nsArguments
            )
            return self
        }

        public func sort(_ descriptor: SortDescriptor<CD>) -> Self {
            fetchRequest.sortDescriptors = [descriptor.nsSortDescriptor]
            return self
        }

        public func last(dateKey: CD.Keys, in context: Context) -> Result<CD, Error> {
            let descriptor = SortDescriptor<CD>(key: dateKey, sorting: .descending)
            return sort(descriptor)
                .limitOne()
                .fetch(in: context)
        }

        public func first(dateKey: CD.Keys, in context: Context) -> Result<CD, Error> {
            let descriptor = SortDescriptor<CD>(key: dateKey, sorting: .descending)
            return sort(descriptor)
                .limitOne()
                .fetch(in: context)
        }

        public func limit(_ limit: Int) -> Self {
            fetchRequest.fetchLimit = limit
            return self
        }

        public func limitOne() -> SingleElementFetchRequestWrapper<CD> {
            SingleElementFetchRequestWrapper<CD>(fetchRequestWrapper: self)
        }

        public struct SingleElementFetchRequestWrapper<CD> where CD: CoreDataManaged, CD: CodingKeyed {
            private let fetchRequestWrapper: FetchRequestWrapper<CD>
            init(fetchRequestWrapper: FetchRequestWrapper<CD>) {
                self.fetchRequestWrapper = fetchRequestWrapper
            }

            public func fetch(in context: Context) -> Result<CD, Error> {
                let result = fetchRequestWrapper
                    .limit(1)
                    .fetch(in: context)
                    .map { $0.first }
                switch result {
                case .success(let maybeValue):
                    if let value = maybeValue {
                        return .success(value)
                    } else {
                        return .failure(E.elementNotFound)
                    }
                case .failure(let error):
                    return .failure(error)
                }
            }

            @discardableResult
            public func update(_ updates: UpdateDescriptor<CD>..., in context: Context) -> Result<Void, Error> {
                update(updates, in: context)
            }

            @discardableResult
            public func update(_ updates: [UpdateDescriptor<CD>], in context: Context) -> Result<Void, Error> {
                let fetchRequest = fetchRequestWrapper
                    .limit(1).fetchRequest

                do {
                    let managedContext = fetchRequestWrapper.container.nsManagedContext(for: context)
                    guard let managed = try managedContext.fetch(fetchRequest).first else {
                        return .failure(E.elementNotFound)
                    }
                    for update in updates {
                        let (key, maybeValue) = update.internalValue
                        if let value = maybeValue {
                            managed.setValue(value, forKey: key)
                        } else {
                            managed.setNilValueForKey(key)
                        }
                    }
                    try managedContext.save()
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }
        }

        public func fetch(in context: Context) -> Result<[CD], Error> {
            do {
                let managed = try container.nsManagedContext(for: context).fetch(fetchRequest)
                return .success(managed.compactMap { CD(managedObject: $0) })
            } catch {
                return .failure(error)
            }
        }

        public func exists(in context: Context) -> Bool {
            switch limitOne().fetch(in: context) {
            case .success: return true
            case .failure: return false
            }
        }

        public func delete(in context: Context) -> Result<Void, Error> {
            let context = container.nsManagedContext(for: context)
            do {
                for managed in try context.fetch(fetchRequest) {
                    context.delete(managed)
                }
                try context.save()
                return .success(())
            } catch {
                return .failure(error)
            }
        }
    }
}

public extension SortDescriptor {
    var nsSortDescriptor: NSSortDescriptor {
        return NSSortDescriptor(key: key.stringValue, ascending: sorting.ascending)
    }
}

public extension NSFetchRequest {
    @objc func predicate(_ predicate: NSPredicate) -> Self {
        self.predicate = predicate
        return self
    }

    @objc func fetchLimit(_ limit: Int) -> Self {
        self.fetchLimit = limit
        return self
    }
}

public enum UrnKeys: CodingKey {
    case urn
}

public protocol UrnIdentifyable: CodingKeyed {
    var urn: URN { get }
}

public extension UrnIdentifyable {
    static var keys: UrnKeys.Type { UrnKeys.self }
}

extension TimeInterval {
    public var dates: (startDate: Date, endDate: Date) {
        let now = Date()
        let maybeStartDate = Calendar.current.date(
            byAdding: .second,
            value: -Int(self),
            to: now
        )

        let maybeEndDate = Calendar.current.date(
            byAdding: .second,
            value: 0,
            to: now
        )
        // Todo: negative and positive time intervals
        guard let startDate = maybeStartDate, let endDate = maybeEndDate else {
            return (startDate: now, endDate: now)
        }
        return (startDate: startDate, endDate: endDate)
    }
}
