//  Created by Axel Ancona Esselmann on 6/5/20.
//  Copyright © 2020 Axel Ancona Esselmann. All rights reserved.
//

import URN
import ValueTypeRepresentable

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
    case string(RemoteType.Keys, to: ValueTypeRepresentable.StringRepresentable?)
    case bool(RemoteType.Keys, to: BoolRepresentable?)
    case double(RemoteType.Keys, to: DoubleRepresentable?)
    case date(RemoteType.Keys, to: DateRepresentable?)
    case int(RemoteType.Keys, to: IntRepresentable?)
    case int16(RemoteType.Keys, to: Int16Representable?)

    public var internalValue: (String, Any?) {
        switch self {
        case .string(let key, to: let stringRepresentable):
            return (key.stringValue, stringRepresentable?.stringValue)
        case .double(let key, to: let doubleRepresentable):
            return (key.stringValue, doubleRepresentable?.doubleValue)
        case .bool(let key, to: let boolRepresentable):
            return (key.stringValue, boolRepresentable?.boolValue)
        case .date(let key, to: let dateRepresentable):
            return (key.stringValue, dateRepresentable?.dateValue)
        case .int(let key, to: let intRepresentable):
            return (key.stringValue, intRepresentable?.intValue)
        case .int16(let key, to: let intRepresentable):
            return (key.stringValue, intRepresentable?.int16Value)
        }
    }
}

public enum QueryDescriptor<RemoteType> where RemoteType: CodingKeyed {
    case urn(RemoteType.Keys, equals: URN)
    case bool(RemoteType.Keys, is: BoolRepresentable)
    case double(RemoteType.Keys, Comparison, DoubleRepresentable)
    case string(RemoteType.Keys, Comparison, ValueTypeRepresentable.StringRepresentable)
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
