//  Created by Axel Ancona Esselmann on 6/17/20.
//  Copyright © 2020 Axel Ancona Esselmann. All rights reserved.
//

import ValueTypeRepresentable
import CoreData
import URN

public struct CodingKeyedManagedObjectWrapper<CKed> where CKed: CodingKeyed, CKed: CoreDataManaged {
    let managed: NSManagedObject

    public func string(for key: CKed.Keys) -> String? {
        CKed.string(for: key, in: managed)
    }

    public func urn(for key: CKed.Keys) -> URN? {
        CKed.urn(for: key, in: managed)
    }

    public func uuid(for key: CKed.Keys) -> UUID? {
        CKed.uuid(for: key, in: managed)
    }

    public func data(for key: CKed.Keys) -> Data? {
        CKed.data(for: key, in: managed)
    }

    public func stringRepresentable<T>(for key: CKed.Keys) -> T? where T: ValueTypeRepresentable.StringRepresentable {
        CKed.stringRepresentable(for: key, in: managed)
    }

    public func value(for key: CKed.Keys) -> Date? {
        CKed.date(for: key, in: managed)
    }

    public func value(for key: CKed.Keys) -> URN? {
        CKed.urn(for: key, in: managed)
    }

    public func value(for key: CKed.Keys) -> UUID? {
        CKed.uuid(for: key, in: managed)
    }

    public func value(for key: CKed.Keys) -> Data? {
        CKed.data(for: key, in: managed)
    }

    public func value(for key: CKed.Keys) -> String? {
        CKed.string(for: key, in: managed)
    }

    public func value<T>(_ type: T.Type, for key: CKed.Keys, decoder: JSONDecoder = JSONDecoder()) -> T? where T: Decodable {
        CKed.jsonDataRepresentable(type: type, for: key, in: managed, decoder: decoder)
    }

    @discardableResult
    public func set(_ string: String, for key: CKed.Keys) -> Self {
        CKed.setString(string, for: key, in: managed)
        return self
    }

    @discardableResult
    public func set(_ uuid: UUID, for key: CKed.Keys) -> Self {
        CKed.setUuid(uuid, for: key, in: managed)
        return self
    }

    @discardableResult
    public func set(_ data: Data, for key: CKed.Keys) -> Self {
        CKed.setData(data, for: key, in: managed)
        return self
    }

    @discardableResult
    public func set(_ date: Date, for key: CKed.Keys) -> Self {
        CKed.setDate(date, for: key, in: managed)
        return self
    }

    @discardableResult
    public func setUrn(_ urn: URN, for key: CKed.Keys) -> Self {
        CKed.setUrn(urn, for: key, in: managed)
        return self
    }

    @discardableResult
    public func setStringRepresentable<T>(_ value: T, for key: CKed.Keys) -> Self where T: ValueTypeRepresentable.StringRepresentable {
        CKed.setStringRepresentable(value, for: key, in: managed)
        return self
    }

    @discardableResult
    public func setNilValue(for key: CKed.Keys) -> Self {
        CKed.setNilValue(for: key, in: managed)
        return self
    }
}

public extension CodingKeyed where Self: CoreDataManaged {

    static func container(for managed: NSManagedObject) -> CodingKeyedManagedObjectWrapper<Self> {
        return CodingKeyedManagedObjectWrapper<Self>(managed: managed)
    }

    static func container(in managedContext: NSManagedObjectContext) throws -> CodingKeyedManagedObjectWrapper<Self> {
        guard let entity =
            NSEntityDescription.entity(
                forEntityName: Self.entityName,
                in: managedContext
            )
        else {
            throw CoreDataError.unknownEntityName
        }
        let managed = NSManagedObject(entity: entity, insertInto: managedContext)
        return container(for: managed)
    }

    static func string(for key: Self.Keys, in managed: NSManagedObject) -> String? {
        return managed.value(forKeyPath: key.stringValue) as? String
    }

    static func uuid(for key: Self.Keys, in managed: NSManagedObject) -> UUID? {
        return managed.value(forKeyPath: key.stringValue) as? UUID
    }

    static func urn(for key: Self.Keys, in managed: NSManagedObject) -> URN? {
        guard let stringValue = string(for: key, in: managed) else {
            return nil
        }
        return URN(stringValue: stringValue)
    }

    static func stringRepresentable<T>(for key: Self.Keys, in managed: NSManagedObject) -> T? where T: ValueTypeRepresentable.StringRepresentable {
        guard let stringValue = string(for: key, in: managed) else {
            return nil
        }
        return T(stringValue)
    }

    static func date(for key: Self.Keys, in managed: NSManagedObject) -> Date? {
        return managed.value(forKeyPath: key.stringValue) as? Date
    }

    static func int16(for key: Self.Keys, in managed: NSManagedObject) -> Int16? {
        return managed.value(forKeyPath: key.stringValue) as? Int16
    }

    static func data(for key: Self.Keys, in managed: NSManagedObject) -> Data? {
        return managed.value(forKeyPath: key.stringValue) as? Data
    }

    static func int16Representable<T>(type: T.Type, for key: Self.Keys, in managed: NSManagedObject) -> T? where T: Int16Representable {
        guard let rawValue = int16(for: key, in: managed) else {
            return nil
        }
        return T(rawValue)
    }

    static func int16Representable<T>(for key: Self.Keys, in managed: NSManagedObject) -> T? where T: Int16Representable {
        return int16Representable(type: T.self, for: key, in: managed)
    }

    static func jsonDataRepresentable<T>(type: T.Type, for key: Self.Keys, in managed: NSManagedObject, decoder: JSONDecoder = JSONDecoder()) -> T? where T: Decodable {
        guard let data = data(for: key, in: managed) else {
            return nil
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    static func jsonDataRepresentable<T>(for key: Self.Keys, in managed: NSManagedObject, decoder: JSONDecoder = JSONDecoder()) -> T? where T: Decodable {
        return jsonDataRepresentable(type: T.self, for: key, in: managed)
    }

//    static func value<T>(for key: Self.Keys, in managed: NSManagedObject) -> T? {
//        switch T.self {
//        case is URN.Type:
//            return urn(for: key, in: managed) as? T
//
//        default:
//            return managed.value(forKeyPath: key.stringValue) as? T
//        }
//    }

    static func setString(_ stringValue: String, for key: Self.Keys, in managed: NSManagedObject) {
        managed.setValue(stringValue, forKey: key.stringValue)
    }

    static func setDate(_ dateValue: Date, for key: Self.Keys, in managed: NSManagedObject) {
        managed.setValue(dateValue, forKey: key.stringValue)
    }

    static func setUrn(_ urnValue: URN, for key: Self.Keys, in managed: NSManagedObject) {
        managed.setValue(urnValue.stringValue, forKey: key.stringValue)
    }

    static func setUuid(_ uuidValue: UUID, for key: Self.Keys, in managed: NSManagedObject) {
        managed.setValue(uuidValue, forKey: key.stringValue)
    }

    static func setData(_ dataValue: Data, for key: Self.Keys, in managed: NSManagedObject) {
        managed.setValue(dataValue, forKey: key.stringValue)
    }

    static func setStringRepresentable<T>(_ value: T, for key: Self.Keys, in managed: NSManagedObject) where T: ValueTypeRepresentable.StringRepresentable {
        managed.setValue(value.stringValue, forKey: key.stringValue)
    }

    static func setNilValue(for key: Self.Keys, in managed: NSManagedObject) {
        managed.setNilValueForKey(key.stringValue)
    }
}
