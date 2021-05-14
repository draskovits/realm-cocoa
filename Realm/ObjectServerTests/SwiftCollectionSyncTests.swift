////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Realm
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
#endif

class ListSyncTests: SwiftSyncTestCase {
    private func roundTrip<T: _ManagedPropertyType>(keyPath: KeyPath<SwiftCollectionSyncObject, List<T>>,
                                                    values: [T],
                                                    partitionValue: String = #function) throws {
        let user = logInUser(for: basicCredentials(withName: partitionValue,
                                                   register: isParent))
        let realm = try openRealm(partitionValue: partitionValue, user: user)
        if isParent {
            checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            // Run the child again to add the values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            let collection = object[keyPath: keyPath]
            XCTAssertEqual(collection.count, values.count*2)
            for (el, ex) in zip(collection, values + values) {
                if let person = el as? SwiftPerson, let otherPerson = ex as? SwiftPerson {
                    XCTAssertEqual(person.firstName, otherPerson.firstName, "\(el) is not equal to \(ex)")
                } else {
                    XCTAssertEqual(el, ex)
                }
            }
            // Run the child again to delete the last 3 objects
            executeChild()
            waitForDownloads(for: realm)
            XCTAssertEqual(collection.count, values.count)
            // Run the child again to modify the first element
            executeChild()
            waitForDownloads(for: realm)
            if T.self is SwiftPerson.Type {
                XCTAssertEqual((collection as! List<SwiftPerson>)[0].firstName,
                               (values as! [SwiftPerson])[1].firstName)
            } else {
                XCTAssertEqual(collection[0], values[1])
            }
        } else {
            guard let object = realm.objects(SwiftCollectionSyncObject.self).first else {
                try realm.write({
                    realm.add(SwiftCollectionSyncObject())
                })
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
                return
            }
            let collection = object[keyPath: keyPath]

            if collection.count == 0 {
                try realm.write({
                    collection.append(objectsIn: values + values)
                })
                XCTAssertEqual(collection.count, values.count*2)
            } else if collection.count == 6 {
                try realm.write({
                    collection.removeSubrange(3...5)
                })
                XCTAssertEqual(collection.count, values.count)
            } else {
                if T.self is SwiftPerson.Type {
                    try realm.write({
                        (collection as! List<SwiftPerson>)[0].firstName
                            = (values as! [SwiftPerson])[1].firstName
                    })
                    XCTAssertEqual((collection as! List<SwiftPerson>)[0].firstName,
                                   (values as! [SwiftPerson])[1].firstName)
                } else {
                    try realm.write({
                        collection[0] = values[1]
                    })
                    XCTAssertEqual(collection[0], values[1])
                }
            }
            waitForUploads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
        }
    }

    func testIntList() {
        do {
            try roundTrip(keyPath: \.intList, values: [1, 2, 3])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBoolList() {
        do {
            try roundTrip(keyPath: \.boolList, values: [true, false, false])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testStringList() {
        do {
            try roundTrip(keyPath: \.stringList, values: ["Hey", "Hi", "Bye"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDataList() {
        do {
            try roundTrip(keyPath: \.dataList, values: [Data(repeating: 0, count: 64),
                                                        Data(repeating: 1, count: 64),
                                                        Data(repeating: 2, count: 64)])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDateList() {
        do {
            try roundTrip(keyPath: \.dateList, values: [Date(timeIntervalSince1970: 10000000),
                                                        Date(timeIntervalSince1970: 20000000),
                                                        Date(timeIntervalSince1970: 30000000)])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDoubleList() {
        do {
            try roundTrip(keyPath: \.doubleList, values: [123.456, 234.456, 567.333])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectIdList() {
        do {
            try roundTrip(keyPath: \.objectIdList, values: [.init("6058f12b957ba06156586a7c"),
                                                            .init("6058f12682b2fbb1f334ef1d"),
                                                            .init("6058f12d42e5a393e67538d0")])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecimalList() {
        do {
            try roundTrip(keyPath: \.decimalList, values: [123.345,
                                                           213.345,
                                                           321.345])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUuidList() {
        do {
            try roundTrip(keyPath: \.uuidList, values: [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                                        UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                                        UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectList() {
        do {
            try roundTrip(keyPath: \.objectList, values: [SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                                          SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                                          SwiftPerson(firstName: "Stephen", lastName: "Strange")])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAnyList() {
        do {
            try roundTrip(keyPath: \.anyList, values: [.int(12345), .string("Hello"), .none])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

class SetSyncTests: SwiftSyncTestCase {

    private typealias MutableSetKeyPath<T: RealmCollectionValue> = KeyPath<SwiftCollectionSyncObject, MutableSet<T>>
    private typealias MutableSetKeyValues<T: RealmCollectionValue> = (keyPath: MutableSetKeyPath<T>, values: [T])

    private func roundTrip<T: _ManagedPropertyType>(set: MutableSetKeyValues<T>,
                                                    otherSet: MutableSetKeyValues<T>,
                                                    partitionValue: String = #function) throws {
        let user = logInUser(for: basicCredentials(withName: partitionValue, register: isParent))
        let realm = try openRealm(partitionValue: partitionValue, user: user)
        if isParent {
            checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            // Run the child again to insert the values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            let collection = object[keyPath: set.keyPath]
            let otherCollection = object[keyPath: otherSet.keyPath]
            XCTAssertEqual(collection.count, set.values.count)
            XCTAssertEqual(otherCollection.count, otherSet.values.count)
            // Run the child again to intersect the values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            if !(T.self is SwiftPerson.Type) {
                XCTAssertTrue(collection.intersects(object[keyPath: otherSet.keyPath]))
                XCTAssertEqual(collection.count, 1)
            }
            // The intersection should have assigned the last value from `values`
            if !(T.self is SwiftPerson.Type) {
                XCTAssertTrue(collection.contains(set.values.last!))
            }
            // Run the child again to delete the objects in the sets.
            executeChild()
            waitForDownloads(for: realm)
            XCTAssertEqual(collection.count, 0)
            XCTAssertEqual(otherCollection.count, 0)
        } else {
            guard let object = realm.objects(SwiftCollectionSyncObject.self).first else {
                try realm.write({
                    realm.add(SwiftCollectionSyncObject())
                })
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
                return
            }
            let collection = object[keyPath: set.keyPath]
            let otherCollection = object[keyPath: otherSet.keyPath]
            if collection.count == 0,
               otherCollection.count == 0 {
                try realm.write({
                    collection.insert(objectsIn: set.values)
                    otherCollection.insert(objectsIn: otherSet.values)
                })
                XCTAssertEqual(collection.count, set.values.count)
                XCTAssertEqual(otherCollection.count, otherSet.values.count)
            } else if collection.count == 3,
                      otherCollection.count == 3 {
                if !(T.self is SwiftPerson.Type) {
                    try realm.write({
                        collection.formIntersection(otherCollection)
                    })
                } else {
                    try realm.write({
                        // formIntersection won't work with unique Objects
                        collection.removeAll()
                        collection.insert(set.values[0])
                    })
                }
                XCTAssertEqual(collection.count, 1)
                XCTAssertEqual(otherCollection.count, otherSet.values.count)
            } else {
                try realm.write({
                    collection.removeAll()
                    otherCollection.removeAll()
                })
                XCTAssertEqual(collection.count, 0)
                XCTAssertEqual(otherCollection.count, 0)
            }
            waitForUploads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
        }
    }

    func testIntSet() {
        do {
            try roundTrip(set: (\.intSet, [1, 2, 3]), otherSet: (\.otherIntSet, [3, 4, 5]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testStringSet() {
        do {
            try roundTrip(set: (\.stringSet, ["Who", "What", "When"]),
                          otherSet: (\.otherStringSet, ["When", "Strings", "Collide"]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDataSet() {
        do {
            try roundTrip(set: (\.dataSet, [Data(repeating: 1, count: 64),
                                            Data(repeating: 2, count: 64),
                                            Data(repeating: 3, count: 64)]),
                          otherSet: (\.otherDataSet, [Data(repeating: 3, count: 64),
                                                      Data(repeating: 4, count: 64),
                                                      Data(repeating: 5, count: 64)]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDateSet() {
        do {
            try roundTrip(set: (\.dateSet, [Date(timeIntervalSince1970: 10000000),
                                            Date(timeIntervalSince1970: 20000000),
                                            Date(timeIntervalSince1970: 30000000)]),
                          otherSet: (\.otherDateSet, [Date(timeIntervalSince1970: 30000000),
                                                      Date(timeIntervalSince1970: 40000000),
                                                      Date(timeIntervalSince1970: 50000000)]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDoubleSet() {
        do {
            try roundTrip(set: (\.doubleSet, [123.456, 345.456, 789.456]),
                          otherSet: (\.otherDoubleSet, [789.456,
                                                        888.456,
                                                        987.456]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectIdSet() {
        do {
            try roundTrip(set: (\.objectIdSet, [.init("6058f12b957ba06156586a7c"),
                                                .init("6058f12682b2fbb1f334ef1d"),
                                                .init("6058f12d42e5a393e67538d0")]),
                          otherSet: (\.otherObjectIdSet, [.init("6058f12d42e5a393e67538d0"),
                                                          .init("6058f12682b2fbb1f334ef1f"),
                                                          .init("6058f12d42e5a393e67538d1")]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecimalSet() {
        do {
            try roundTrip(set: (\.decimalSet, [123.345,
                                               213.345,
                                               321.345]),
                          otherSet: (\.otherDecimalSet, [321.345,
                                                         333.345,
                                                         444.345]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUuidSet() {
        do {
            try roundTrip(set: (\.uuidSet, [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                            UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                            UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!]),
                          otherSet: (\.otherUuidSet, [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!,
                                                      UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ae")!,
                                                      UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90bf")!]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectSet() {
        do {
            try roundTrip(set: (\.objectSet, [SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                              SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                              SwiftPerson(firstName: "Stephen", lastName: "Strange")]),
                          otherSet: (\.otherObjectSet, [SwiftPerson(firstName: "Stephen", lastName: "Strange"),
                                                        SwiftPerson(firstName: "Tony", lastName: "Stark"),
                                                        SwiftPerson(firstName: "Clark", lastName: "Kent")]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAnySet() {
        do {
            try roundTrip(set: (\.anySet, [.int(12345), .none, .string("Hello")]),
                          otherSet: (\.otherAnySet, [.string("Hello"), .double(765.6543), .objectId(.generate())]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

class MapSyncTests: SwiftSyncTestCase {

    private typealias MapKeyPath<T: RealmCollectionValue> = KeyPath<SwiftCollectionSyncObject, Map<String, T>>
    private typealias MapKeyValues<T: RealmCollectionValue> = (keyPath: MapKeyPath<T>, values: Map<String, T>)

    private func roundTrip<T: _ManagedPropertyType>(map: MapKeyValues<T>,
                                                    otherMap: MapKeyValues<T>,
                                                    partitionValue: String = #function) throws {
        let user = logInUser(for: basicCredentials(withName: partitionValue, register: isParent))
        let realm = try openRealm(partitionValue: partitionValue, user: user)
        if isParent {
            // Run to add initial empty object
            checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            // Run the child again to add values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            let collection = object[keyPath: map.keyPath]
            let otherCollection = object[keyPath: otherMap.keyPath]
            XCTAssertEqual(collection.count, map.values.count)
            XCTAssertEqual(otherCollection.count, otherMap.values.count)
            // Run the child again to add more values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            // Run the child again to remove values
            executeChild()
            waitForDownloads(for: realm)
            XCTAssertEqual(collection.count, 0)
            XCTAssertEqual(otherCollection.count, 0)
        } else {
            guard let object = realm.objects(SwiftCollectionSyncObject.self).first else {
                try realm.write({
                    realm.add(SwiftCollectionSyncObject())
                })
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
                return
            }
            let collection = object[keyPath: map.keyPath]
            let otherCollection = object[keyPath: otherMap.keyPath]
            if collection.count == 0,
               otherCollection.count == 0 {
                try realm.write({
                    for entry in map.values {
                        collection[entry.key] = entry.value
                    }
                    for entry in otherMap.values {
                        otherCollection[entry.key] = entry.value
                    }
                })
                XCTAssertEqual(collection.count, 3)
                XCTAssertEqual(otherCollection.count, 3)
            } else if collection.count == 3,
                      otherCollection.count == 3 {
                try realm.write({
                    for entry in otherMap.values {
                        collection[entry.key] = entry.value
                    }
                    for entry in map.values {
                        otherCollection[entry.key] = entry.value
                    }
                })
                XCTAssertEqual(collection.count, map.values.count + otherMap.values.count)
                XCTAssertEqual(otherCollection.count, map.values.count + otherMap.values.count)
            } else {
                try realm.write({
                    collection.removeAll()
                    otherCollection.removeAll()
                })
                XCTAssertEqual(collection.count, 0)
                XCTAssertEqual(otherCollection.count, 0)
            }
            waitForUploads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
        }
    }

    func createMap<T>(_ values: [T]) -> Map<String, T> {
        let map = Map<String, T>()
        for value in values {
            map[UUID().uuidString] = value
        }
        return map
    }
    
    func testIntMap() {
        do {
            let map = createMap([1, 2, 3])
            let otherMap = createMap([3, 4, 5])
            try roundTrip(map: (\.intMap, map), otherMap: (\.otherIntMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    func testStringMap() {
        do {
            let map = createMap(["Who", "What", "When"])
            let otherMap = createMap(["When", "Strings", "Collide"])
            try roundTrip(map: (\.stringMap, map), otherMap: (\.otherStringMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDataMap() {
        do {
            let map = createMap([Data(repeating: 1, count: 64),
                                 Data(repeating: 2, count: 64),
                                 Data(repeating: 3, count: 64)])
            let otherMap = createMap([Data(repeating: 3, count: 64),
                                      Data(repeating: 4, count: 64),
                                      Data(repeating: 5, count: 64)])
            try roundTrip(map: (\.dataMap, map), otherMap: (\.otherDataMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDateMap() {
        do {
            let map = createMap([Date(timeIntervalSince1970: 10000000),
                                 Date(timeIntervalSince1970: 20000000),
                                 Date(timeIntervalSince1970: 30000000)])
            let otherMap = createMap([Date(timeIntervalSince1970: 30000000),
                                      Date(timeIntervalSince1970: 40000000),
                                      Date(timeIntervalSince1970: 50000000)])
            try roundTrip(map: (\.dateMap, map), otherMap: (\.otherDateMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDoubleMap() {
        do {
            let map = createMap([123.456, 345.456, 789.456])
            let otherMap = createMap([789.456, 888.456, 987.456])
            try roundTrip(map: (\.doubleMap, map), otherMap: (\.otherDoubleMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectIdMap() {
        do {
            let map = createMap([ObjectId("6058f12b957ba06156586a7c"),
                                 ObjectId("6058f12682b2fbb1f334ef1d"),
                                 ObjectId("6058f12d42e5a393e67538d0")])
            let otherMap = createMap([ObjectId("6058f12d42e5a393e67538d0"),
                                      ObjectId("6058f12682b2fbb1f334ef1f"),
                                      ObjectId("6058f12d42e5a393e67538d1")])
            try roundTrip(map: (\.objectIdMap, map), otherMap: (\.otherObjectIdMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecimalMap() {
        do {
            let map = createMap([Decimal128(123.345), Decimal128(213.345), Decimal128(321.345)])
            let otherMap = createMap([Decimal128(321.345), Decimal128(333.345), Decimal128(444.345)])
            try roundTrip(map: (\.decimalMap, map), otherMap: (\.otherDecimalMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUuidMap() {
        do {
            let map = createMap([UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                 UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                 UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!])
            let otherMap = createMap([UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!,
                                      UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ae")!,
                                      UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90bf")!])
            try roundTrip(map: (\.uuidMap, map), otherMap: (\.otherUuidMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectMap() {
        do {
            let map = createMap([SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                 SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                 SwiftPerson(firstName: "Stephen", lastName: "Strange")])
            let otherMap = createMap([SwiftPerson(firstName: "Stephen", lastName: "Strange"),
                                      SwiftPerson(firstName: "Tony", lastName: "Stark"),
                                      SwiftPerson(firstName: "Clark", lastName: "Kent")])
            try roundTrip(map: (\.objectMap, map), otherMap: (\.otherObjectMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAnyMap() {
        do {
            let map: Map<String, AnyRealmValue> = createMap([.int(12345), .none, .string("Hello")])
            let otherMap: Map<String, AnyRealmValue> = createMap([.string("Hello"), .double(765.6543), .objectId(.generate())])
            try roundTrip(map: (\.anyMap, map), otherMap: (\.otherAnyMap, otherMap))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
