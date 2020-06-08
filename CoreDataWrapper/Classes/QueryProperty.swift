//  Created by Axel Ancona Esselmann on 6/5/20.
//  Copyright © 2020 Axel Ancona Esselmann. All rights reserved.
//

import URN

public protocol CodingKeyed {
    associatedtype Keys where Keys: CodingKey
    static var keys: Keys.Type { get }
}

public struct SortDescriptor<RemoteType> where RemoteType: CodingKeyed {
    public enum Sorting {
        case ascending
        case descending

        public var ascending: Bool {
            switch self {
            case .ascending: return true
            case .descending: return false
            }
        }
    }

    public let key: RemoteType.Keys
    public let sorting: Sorting
}

public enum Comparison {
    case equals
    case greaterThan
    case greaterEqualThan
    case lessThan
    case lessEqualThan

    public var stringOperator: String {
        switch self {
        case .equals: return "="
        case .greaterThan: return ">"
        case .greaterEqualThan: return ">="
        case .lessThan: return "<"
        case .lessEqualThan: return "<="
        }
    }
}

public enum UpdateDescriptor<RemoteType> where RemoteType: CodingKeyed {
    case string(RemoteType.Keys, to: StringRepresentable)
    case bool(RemoteType.Keys, to: BoolRepresentable)
    case double(RemoteType.Keys, to: DoubleRepresentable)
    case date(RemoteType.Keys, to: DateRepresentable)
    case int(RemoteType.Keys, to: IntRepresentable)
    case int16(RemoteType.Keys, to: Int16Representable)

    public var internalValue: (String, Any) {
        switch self {
        case .string(let key, to: let stringRepresentable):
            return (key.stringValue, stringRepresentable.stringValue)
        case .double(let key, to: let doubleRepresentable):
            return (key.stringValue, doubleRepresentable.doubleValue)
        case .bool(let key, to: let boolRepresentable):
            return (key.stringValue, boolRepresentable.boolValue)
        case .date(let key, to: let dateRepresentable):
            return (key.stringValue, dateRepresentable.dateValue)
        case .int(let key, to: let intRepresentable):
            return (key.stringValue, intRepresentable.intValue)
        case .int16(let key, to: let intRepresentable):
            return (key.stringValue, intRepresentable.int16Value)
        }
    }
}

public enum QueryDescriptor<RemoteType> where RemoteType: CodingKeyed {
    case urn(RemoteType.Keys, equals: URN)
    case bool(RemoteType.Keys, is: BoolRepresentable)
    case double(RemoteType.Keys, Comparison, DoubleRepresentable)
    case string(RemoteType.Keys, Comparison, StringRepresentable)
    case date(RemoteType.Keys, Comparison, DateRepresentable)

    public var internalValue: (String, Comparison, Any) {
        switch self {
        case .string(let key, let comparison, let stringRepresentable):
            return (key.stringValue, comparison, stringRepresentable.stringValue)
        case .double(let key, let comparison, let doubleRepresentable):
            return (key.stringValue, comparison, doubleRepresentable.doubleValue)
        case .date(let key, let comarison, let dateRepresentable):
            return (key.stringValue, comarison, dateRepresentable.dateValue)
        case .bool(let key, is: let isTrue):
            return (key.stringValue, .equals, isTrue.boolValue)
        case .urn(let key, equals: let urn):
            return (key.stringValue, .equals, urn.stringValue)
        }
    }
}

public protocol StringRepresentable {
    var rawValue: String { get }
    init?(rawValue: String)
}

public extension StringRepresentable {
    var stringValue: String {
        return rawValue
    }
}

extension String: StringRepresentable {
    public var rawValue: String {
        return self
    }

    public init?(rawValue: String) {
        self = rawValue
    }
}

public protocol DoubleRepresentable {
    var doubleValue: Double { get }
    init?(_ doubleValue: Double)
}

extension Double: DoubleRepresentable {
    public var doubleValue: Double {
        return self
    }
}

public protocol IntRepresentable {
    var intValue: Int { get }
    init?(_ intValue: Int)
}

extension Int: IntRepresentable {
    public var intValue: Int {
        return self
    }
}

public protocol Int16Representable {
    var int16Value: Int16 { get }
    init?(_ int16Value: Int16)
}

extension Int16: Int16Representable {
    public var int16Value: Int16 {
        return self
    }
    public init?(_ int16Value: Int16) {
        self.init(Float(int16Value))
    }
}

public protocol DateRepresentable {
    var dateValue: Date { get }
    init?(_ dateValue: Date)
}

extension Date: DateRepresentable {
    public init?(_ dateValue: Date) {
        self.init(timeIntervalSince1970: dateValue.timeIntervalSince1970)
    }

    public var dateValue: Date {
        return self
    }
}

public protocol BoolRepresentable {
    var boolValue: Bool { get }
    init?(_ boolValue: Bool)
}

extension Bool: BoolRepresentable {
    public var boolValue: Bool {
        return self
    }
}
