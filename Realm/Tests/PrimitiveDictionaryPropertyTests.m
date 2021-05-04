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

#import "RLMTestCase.h"

static NSDate *date(int i) {
    return [NSDate dateWithTimeIntervalSince1970:i];
}
static NSData *data(int i) {
    return [NSData dataWithBytesNoCopy:calloc(i, 1) length:i freeWhenDone:YES];
}
static RLMDecimal128 *decimal128(int i) {
    return [RLMDecimal128 decimalWithNumber:@(i)];
}
static NSMutableArray *objectIds;
static RLMObjectId *objectId(NSUInteger i) {
    if (!objectIds) {
        objectIds = [NSMutableArray new];
    }
    while (i >= objectIds.count) {
        [objectIds addObject:RLMObjectId.objectId];
    }
    return objectIds[i];
}
static NSUUID *uuid(NSString *uuidString) {
    return [[NSUUID alloc] initWithUUIDString:uuidString];
}
static void count(NSArray *values, double *sum, NSUInteger *count) {
    for (id value in values) {
        if (value != NSNull.null) {
            ++*count;
            *sum += [value doubleValue];
        }
    }
}
static double sum(NSDictionary *dictionary) {
    NSArray *values = dictionary.allValues;
    double sum = 0;
    NSUInteger c = 0;
    count(values, &sum, &c);
    return sum;
}
static double average(NSDictionary *dictionary) {
    NSArray *values = dictionary.allValues;
    double sum = 0;
    NSUInteger c = 0;
    count(values, &sum, &c);
    return sum / c;
}
@interface NSUUID (RLMUUIDCompateTests)
- (NSComparisonResult)compare:(NSUUID *)other;
@end
@implementation NSUUID (RLMUUIDCompateTests)
- (NSComparisonResult)compare:(NSUUID *)other {
    return [[self UUIDString] compare:other.UUIDString];
}
@end

@interface LinkToAllPrimitiveDictionaries : RLMObject
@property (nonatomic) AllPrimitiveDictionaries *link;
@end
@implementation LinkToAllPrimitiveDictionaries
@end

@interface LinkToAllOptionalPrimitiveDictionaries : RLMObject
@property (nonatomic) AllOptionalPrimitiveDictionaries *link;
@end
@implementation LinkToAllOptionalPrimitiveDictionaries
@end

@interface PrimitiveDictionaryPropertyTests : RLMTestCase
@end

@implementation PrimitiveDictionaryPropertyTests {
    AllPrimitiveDictionaries *unmanaged;
    AllPrimitiveDictionaries *managed;
    AllOptionalPrimitiveDictionaries *optUnmanaged;
    AllOptionalPrimitiveDictionaries *optManaged;
    RLMRealm *realm;
    NSArray<RLMDictionary *> *allDictionaries;
}

- (void)setUp {
    unmanaged = [[AllPrimitiveDictionaries alloc] init];
    optUnmanaged = [[AllOptionalPrimitiveDictionaries alloc] init];
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    managed = [AllPrimitiveDictionaries createInRealm:realm withValue:@[]];
    optManaged = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[]];
    allDictionaries = @[
        unmanaged.boolObj,
        optUnmanaged.boolObj,
        managed.boolObj,
        optManaged.boolObj,
        unmanaged.intObj,
        optUnmanaged.intObj,
        managed.intObj,
        optManaged.intObj,
        unmanaged.stringObj,
        optUnmanaged.stringObj,
        managed.stringObj,
        optManaged.stringObj,
        unmanaged.dateObj,
        optUnmanaged.dateObj,
        managed.dateObj,
        optManaged.dateObj,
    ];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)addObjects {
    [unmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optUnmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [managed.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optManaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [unmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optUnmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [managed.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optManaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [unmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optUnmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [managed.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optManaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [unmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optUnmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [managed.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optManaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
}

- (void)testCount {
    XCTAssertEqual(unmanaged.intObj.count, 0U);
    unmanaged.intObj[@"testVal"] = @1;
    XCTAssertEqual(unmanaged.intObj.count, 1U);
}

- (void)testType {
    XCTAssertEqual(unmanaged.boolObj.type, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.intObj.type, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.floatObj.type, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.doubleObj.type, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.stringObj.type, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.dataObj.type, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.dateObj.type, RLMPropertyTypeDate);
    XCTAssertEqual(optUnmanaged.boolObj.type, RLMPropertyTypeBool);
    XCTAssertEqual(optUnmanaged.intObj.type, RLMPropertyTypeInt);
    XCTAssertEqual(optUnmanaged.floatObj.type, RLMPropertyTypeFloat);
    XCTAssertEqual(optUnmanaged.doubleObj.type, RLMPropertyTypeDouble);
    XCTAssertEqual(optUnmanaged.stringObj.type, RLMPropertyTypeString);
    XCTAssertEqual(optUnmanaged.dataObj.type, RLMPropertyTypeData);
    XCTAssertEqual(optUnmanaged.dateObj.type, RLMPropertyTypeDate);
}

- (void)testOptional {
    XCTAssertFalse(unmanaged.boolObj.optional);
    XCTAssertFalse(unmanaged.intObj.optional);
    XCTAssertFalse(unmanaged.floatObj.optional);
    XCTAssertFalse(unmanaged.doubleObj.optional);
    XCTAssertFalse(unmanaged.stringObj.optional);
    XCTAssertFalse(unmanaged.dataObj.optional);
    XCTAssertFalse(unmanaged.dateObj.optional);
    XCTAssertTrue(optUnmanaged.boolObj.optional);
    XCTAssertTrue(optUnmanaged.intObj.optional);
    XCTAssertTrue(optUnmanaged.floatObj.optional);
    XCTAssertTrue(optUnmanaged.doubleObj.optional);
    XCTAssertTrue(optUnmanaged.stringObj.optional);
    XCTAssertTrue(optUnmanaged.dataObj.optional);
    XCTAssertTrue(optUnmanaged.dateObj.optional);
}

- (void)testObjectClassName {
    XCTAssertNil(unmanaged.boolObj.objectClassName);
    XCTAssertNil(unmanaged.intObj.objectClassName);
    XCTAssertNil(unmanaged.floatObj.objectClassName);
    XCTAssertNil(unmanaged.doubleObj.objectClassName);
    XCTAssertNil(unmanaged.stringObj.objectClassName);
    XCTAssertNil(unmanaged.dataObj.objectClassName);
    XCTAssertNil(unmanaged.dateObj.objectClassName);
    XCTAssertNil(optUnmanaged.boolObj.objectClassName);
    XCTAssertNil(optUnmanaged.intObj.objectClassName);
    XCTAssertNil(optUnmanaged.floatObj.objectClassName);
    XCTAssertNil(optUnmanaged.doubleObj.objectClassName);
    XCTAssertNil(optUnmanaged.stringObj.objectClassName);
    XCTAssertNil(optUnmanaged.dataObj.objectClassName);
    XCTAssertNil(optUnmanaged.dateObj.objectClassName);
}

- (void)testRealm {
    XCTAssertNil(unmanaged.boolObj.realm);
    XCTAssertNil(unmanaged.intObj.realm);
    XCTAssertNil(unmanaged.floatObj.realm);
    XCTAssertNil(unmanaged.doubleObj.realm);
    XCTAssertNil(unmanaged.stringObj.realm);
    XCTAssertNil(unmanaged.dataObj.realm);
    XCTAssertNil(unmanaged.dateObj.realm);
    XCTAssertNil(optUnmanaged.boolObj.realm);
    XCTAssertNil(optUnmanaged.intObj.realm);
    XCTAssertNil(optUnmanaged.floatObj.realm);
    XCTAssertNil(optUnmanaged.doubleObj.realm);
    XCTAssertNil(optUnmanaged.stringObj.realm);
    XCTAssertNil(optUnmanaged.dataObj.realm);
    XCTAssertNil(optUnmanaged.dateObj.realm);
}

- (void)testInvalidated {
    RLMDictionary *dictionary;
    @autoreleasepool {
        AllPrimitiveDictionaries *obj = [[AllPrimitiveDictionaries alloc] init];
        dictionary = obj.intObj;
        XCTAssertFalse(dictionary.invalidated);
    }
    XCTAssertFalse(dictionary.invalidated);
}

- (void)testDeleteObjectsInRealm {
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.boolObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.boolObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.intObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.intObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.stringObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.stringObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.dateObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.dateObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.boolObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, bool>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.boolObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, bool?>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.intObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, int>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.intObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, int?>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.stringObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, string>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.stringObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, string?>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.dateObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, date>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.dateObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, date?>: only RLMObjects can be deleted.");
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testSetObject {
    // Managed non-optional
    XCTAssertNil(managed.boolObj[@"key1"]);
    XCTAssertNil(managed.intObj[@"key1"]);
    XCTAssertNil(managed.stringObj[@"key1"]);
    XCTAssertNil(managed.dateObj[@"key1"]);
    XCTAssertNoThrow(managed.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(managed.intObj[@"key1"] = @2);
    XCTAssertNoThrow(managed.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(managed.dateObj[@"key1"] = date(1));
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    RLMAssertThrowsWithReason(managed.boolObj[@"key1"] = NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'.");
    RLMAssertThrowsWithReason(managed.intObj[@"key1"] = NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'int'.");
    RLMAssertThrowsWithReason(managed.stringObj[@"key1"] = NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'string'.");
    RLMAssertThrowsWithReason(managed.dateObj[@"key1"] = NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'date'.");
    XCTAssertNoThrow(managed.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.intObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.dateObj[@"key1"] = nil);
    XCTAssertNil(managed.boolObj[@"key1"]);
    XCTAssertNil(managed.intObj[@"key1"]);
    XCTAssertNil(managed.stringObj[@"key1"]);
    XCTAssertNil(managed.dateObj[@"key1"]);

    // Managed optional
    XCTAssertNil(optManaged.boolObj[@"key1"]);
    XCTAssertNil(optManaged.intObj[@"key1"]);
    XCTAssertNil(optManaged.stringObj[@"key1"]);
    XCTAssertNil(optManaged.dateObj[@"key1"]);
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = @2);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = date(1));
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = NSNull.null);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = NSNull.null);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = NSNull.null);
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], NSNull.null);
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = nil);
    XCTAssertNil(optManaged.boolObj[@"key1"]);
    XCTAssertNil(optManaged.intObj[@"key1"]);
    XCTAssertNil(optManaged.stringObj[@"key1"]);
    XCTAssertNil(optManaged.dateObj[@"key1"]);

    // Unmanaged non-optional
    XCTAssertNil(unmanaged.boolObj[@"key1"]);
    XCTAssertNil(unmanaged.intObj[@"key1"]);
    XCTAssertNil(unmanaged.stringObj[@"key1"]);
    XCTAssertNil(unmanaged.dateObj[@"key1"]);
    XCTAssertNoThrow(unmanaged.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(unmanaged.intObj[@"key1"] = @2);
    XCTAssertNoThrow(unmanaged.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(unmanaged.dateObj[@"key1"] = date(1));
    XCTAssertEqual(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqual(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqual(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqual(unmanaged.dateObj[@"key1"], date(1));
    RLMAssertThrowsWithReason(unmanaged.boolObj[@"key1"] = NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'.");
    RLMAssertThrowsWithReason(unmanaged.intObj[@"key1"] = NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'int'.");
    RLMAssertThrowsWithReason(unmanaged.stringObj[@"key1"] = NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'string'.");
    RLMAssertThrowsWithReason(unmanaged.dateObj[@"key1"] = NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'date'.");
    XCTAssertNoThrow(unmanaged.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.intObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.dateObj[@"key1"] = nil);
    XCTAssertNil(unmanaged.boolObj[@"key1"]);
    XCTAssertNil(unmanaged.intObj[@"key1"]);
    XCTAssertNil(unmanaged.stringObj[@"key1"]);
    XCTAssertNil(unmanaged.dateObj[@"key1"]);

    // Unmanaged optional
    XCTAssertNil(optUnmanaged.boolObj[@"key1"]);
    XCTAssertNil(optUnmanaged.intObj[@"key1"]);
    XCTAssertNil(optUnmanaged.stringObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dateObj[@"key1"]);
    XCTAssertNoThrow(optUnmanaged.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(optUnmanaged.intObj[@"key1"] = @2);
    XCTAssertNoThrow(optUnmanaged.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(optUnmanaged.dateObj[@"key1"] = date(1));
    XCTAssertEqual(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqual(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqual(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqual(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertNoThrow(optUnmanaged.boolObj[@"key1"] = NSNull.null);
    XCTAssertNoThrow(optUnmanaged.intObj[@"key1"] = NSNull.null);
    XCTAssertNoThrow(optUnmanaged.stringObj[@"key1"] = NSNull.null);
    XCTAssertNoThrow(optUnmanaged.dateObj[@"key1"] = NSNull.null);
    XCTAssertEqual(optUnmanaged.boolObj[@"key1"], NSNull.null);
    XCTAssertEqual(optUnmanaged.intObj[@"key1"], NSNull.null);
    XCTAssertEqual(optUnmanaged.stringObj[@"key1"], NSNull.null);
    XCTAssertEqual(optUnmanaged.dateObj[@"key1"], NSNull.null);
    XCTAssertNoThrow(optUnmanaged.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.intObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.dateObj[@"key1"] = nil);
    XCTAssertNil(optUnmanaged.boolObj[@"key1"]);
    XCTAssertNil(optUnmanaged.intObj[@"key1"]);
    XCTAssertNil(optUnmanaged.stringObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dateObj[@"key1"]);

    // Fail with nil key
    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.boolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.boolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.intObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:@"bar" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setObject:@"bar" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.stringObj setObject:@"bar" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.stringObj setObject:@"bar" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.dateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.dateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    // Fail on set nil for non-optional
    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.intObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");

    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setObject:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj setObject:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj setObject:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.intObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");

    unmanaged.boolObj[@"key1"] = @NO;
    optUnmanaged.boolObj[@"key1"] = @NO;
    managed.boolObj[@"key1"] = @NO;
    optManaged.boolObj[@"key1"] = @NO;
    unmanaged.intObj[@"key1"] = @2;
    optUnmanaged.intObj[@"key1"] = @2;
    managed.intObj[@"key1"] = @2;
    optManaged.intObj[@"key1"] = @2;
    unmanaged.stringObj[@"key1"] = @"bar";
    optUnmanaged.stringObj[@"key1"] = @"bar";
    managed.stringObj[@"key1"] = @"bar";
    optManaged.stringObj[@"key1"] = @"bar";
    unmanaged.dateObj[@"key1"] = date(1);
    optUnmanaged.dateObj[@"key1"] = date(1);
    managed.dateObj[@"key1"] = date(1);
    optManaged.dateObj[@"key1"] = date(1);
    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));

    optUnmanaged.boolObj[@"key1"] = NSNull.null;
    optManaged.boolObj[@"key1"] = NSNull.null;
    optUnmanaged.intObj[@"key1"] = NSNull.null;
    optManaged.intObj[@"key1"] = NSNull.null;
    optUnmanaged.stringObj[@"key1"] = NSNull.null;
    optManaged.stringObj[@"key1"] = NSNull.null;
    optUnmanaged.dateObj[@"key1"] = NSNull.null;
    optManaged.dateObj[@"key1"] = NSNull.null;
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], NSNull.null);
}
#pragma clang diagnostic pop

- (void)testAddObjects {
    RLMAssertThrowsWithReason([unmanaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj addEntriesFromDictionary:@{@"key1": NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.boolObj addEntriesFromDictionary:@{@"key1": NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addEntriesFromDictionary:@{@"key1": NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.intObj addEntriesFromDictionary:@{@"key1": NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addEntriesFromDictionary:@{@"key1": NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.stringObj addEntriesFromDictionary:@{@"key1": NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addEntriesFromDictionary:@{@"key1": NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.dateObj addEntriesFromDictionary:@{@"key1": NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");

    [self addObjects];
    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.intObj[@"key2"], @3);
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);
}

- (void)testRemoveObject {
    [self addObjects];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));

    [unmanaged.boolObj removeObjectForKey:@"key1"];
    [optUnmanaged.boolObj removeObjectForKey:@"key1"];
    [managed.boolObj removeObjectForKey:@"key1"];
    [optManaged.boolObj removeObjectForKey:@"key1"];
    [unmanaged.intObj removeObjectForKey:@"key1"];
    [optUnmanaged.intObj removeObjectForKey:@"key1"];
    [managed.intObj removeObjectForKey:@"key1"];
    [optManaged.intObj removeObjectForKey:@"key1"];
    [unmanaged.stringObj removeObjectForKey:@"key1"];
    [optUnmanaged.stringObj removeObjectForKey:@"key1"];
    [managed.stringObj removeObjectForKey:@"key1"];
    [optManaged.stringObj removeObjectForKey:@"key1"];
    [unmanaged.dateObj removeObjectForKey:@"key1"];
    [optUnmanaged.dateObj removeObjectForKey:@"key1"];
    [managed.dateObj removeObjectForKey:@"key1"];
    [optManaged.dateObj removeObjectForKey:@"key1"];

    XCTAssertEqual(unmanaged.boolObj.count, 1U);
    XCTAssertEqual(managed.boolObj.count, 1U);
    XCTAssertEqual(unmanaged.intObj.count, 1U);
    XCTAssertEqual(managed.intObj.count, 1U);
    XCTAssertEqual(unmanaged.stringObj.count, 1U);
    XCTAssertEqual(managed.stringObj.count, 1U);
    XCTAssertEqual(unmanaged.dateObj.count, 1U);
    XCTAssertEqual(managed.dateObj.count, 1U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 1U);
    XCTAssertEqual(optManaged.boolObj.count, 1U);
    XCTAssertEqual(optUnmanaged.intObj.count, 1U);
    XCTAssertEqual(optManaged.intObj.count, 1U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 1U);
    XCTAssertEqual(optManaged.stringObj.count, 1U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 1U);
    XCTAssertEqual(optManaged.dateObj.count, 1U);

    XCTAssertNil(unmanaged.boolObj[@"key1"]);
    XCTAssertNil(optUnmanaged.boolObj[@"key1"]);
    XCTAssertNil(managed.boolObj[@"key1"]);
    XCTAssertNil(optManaged.boolObj[@"key1"]);
    XCTAssertNil(unmanaged.intObj[@"key1"]);
    XCTAssertNil(optUnmanaged.intObj[@"key1"]);
    XCTAssertNil(managed.intObj[@"key1"]);
    XCTAssertNil(optManaged.intObj[@"key1"]);
    XCTAssertNil(unmanaged.stringObj[@"key1"]);
    XCTAssertNil(optUnmanaged.stringObj[@"key1"]);
    XCTAssertNil(managed.stringObj[@"key1"]);
    XCTAssertNil(optManaged.stringObj[@"key1"]);
    XCTAssertNil(unmanaged.dateObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dateObj[@"key1"]);
    XCTAssertNil(managed.dateObj[@"key1"]);
    XCTAssertNil(optManaged.dateObj[@"key1"]);
}

- (void)testRemoveObjects {
    [self addObjects];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));

    [unmanaged.boolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.boolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.boolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.boolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.intObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.intObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.intObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.intObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.stringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.stringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.stringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.stringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.dateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.dateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.dateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.dateObj removeObjectsForKeys:@[@"key1", @"key2"]];

    XCTAssertEqual(unmanaged.boolObj.count, 0U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 0U);
    XCTAssertEqual(managed.boolObj.count, 0U);
    XCTAssertEqual(optManaged.boolObj.count, 0U);
    XCTAssertEqual(unmanaged.intObj.count, 0U);
    XCTAssertEqual(optUnmanaged.intObj.count, 0U);
    XCTAssertEqual(managed.intObj.count, 0U);
    XCTAssertEqual(optManaged.intObj.count, 0U);
    XCTAssertEqual(unmanaged.stringObj.count, 0U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 0U);
    XCTAssertEqual(managed.stringObj.count, 0U);
    XCTAssertEqual(optManaged.stringObj.count, 0U);
    XCTAssertEqual(unmanaged.dateObj.count, 0U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 0U);
    XCTAssertEqual(managed.dateObj.count, 0U);
    XCTAssertEqual(optManaged.dateObj.count, 0U);
    XCTAssertNil(unmanaged.boolObj[@"key1"]);
    XCTAssertNil(optUnmanaged.boolObj[@"key1"]);
    XCTAssertNil(managed.boolObj[@"key1"]);
    XCTAssertNil(optManaged.boolObj[@"key1"]);
    XCTAssertNil(unmanaged.intObj[@"key1"]);
    XCTAssertNil(optUnmanaged.intObj[@"key1"]);
    XCTAssertNil(managed.intObj[@"key1"]);
    XCTAssertNil(optManaged.intObj[@"key1"]);
    XCTAssertNil(unmanaged.stringObj[@"key1"]);
    XCTAssertNil(optUnmanaged.stringObj[@"key1"]);
    XCTAssertNil(managed.stringObj[@"key1"]);
    XCTAssertNil(optManaged.stringObj[@"key1"]);
    XCTAssertNil(unmanaged.dateObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dateObj[@"key1"]);
    XCTAssertNil(managed.dateObj[@"key1"]);
    XCTAssertNil(optManaged.dateObj[@"key1"]);
}

- (void)testUpdateObjects {
    [self addObjects];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.intObj[@"key2"], @3);
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);

    unmanaged.boolObj[@"key2"] = unmanaged.boolObj[@"key1"];
    optUnmanaged.boolObj[@"key2"] = optUnmanaged.boolObj[@"key1"];
    managed.boolObj[@"key2"] = managed.boolObj[@"key1"];
    optManaged.boolObj[@"key2"] = optManaged.boolObj[@"key1"];
    unmanaged.intObj[@"key2"] = unmanaged.intObj[@"key1"];
    optUnmanaged.intObj[@"key2"] = optUnmanaged.intObj[@"key1"];
    managed.intObj[@"key2"] = managed.intObj[@"key1"];
    optManaged.intObj[@"key2"] = optManaged.intObj[@"key1"];
    unmanaged.stringObj[@"key2"] = unmanaged.stringObj[@"key1"];
    optUnmanaged.stringObj[@"key2"] = optUnmanaged.stringObj[@"key1"];
    managed.stringObj[@"key2"] = managed.stringObj[@"key1"];
    optManaged.stringObj[@"key2"] = optManaged.stringObj[@"key1"];
    unmanaged.dateObj[@"key2"] = unmanaged.dateObj[@"key1"];
    optUnmanaged.dateObj[@"key2"] = optUnmanaged.dateObj[@"key1"];
    managed.dateObj[@"key2"] = managed.dateObj[@"key1"];
    optManaged.dateObj[@"key2"] = optManaged.dateObj[@"key1"];
    unmanaged.boolObj[@"key1"] = unmanaged.boolObj[@"key2"];
    optUnmanaged.boolObj[@"key1"] = optUnmanaged.boolObj[@"key2"];
    managed.boolObj[@"key1"] = managed.boolObj[@"key2"];
    optManaged.boolObj[@"key1"] = optManaged.boolObj[@"key2"];
    unmanaged.intObj[@"key1"] = unmanaged.intObj[@"key2"];
    optUnmanaged.intObj[@"key1"] = optUnmanaged.intObj[@"key2"];
    managed.intObj[@"key1"] = managed.intObj[@"key2"];
    optManaged.intObj[@"key1"] = optManaged.intObj[@"key2"];
    unmanaged.stringObj[@"key1"] = unmanaged.stringObj[@"key2"];
    optUnmanaged.stringObj[@"key1"] = optUnmanaged.stringObj[@"key2"];
    managed.stringObj[@"key1"] = managed.stringObj[@"key2"];
    optManaged.stringObj[@"key1"] = optManaged.stringObj[@"key2"];
    unmanaged.dateObj[@"key1"] = unmanaged.dateObj[@"key2"];
    optUnmanaged.dateObj[@"key1"] = optUnmanaged.dateObj[@"key2"];
    managed.dateObj[@"key1"] = managed.dateObj[@"key2"];
    optManaged.dateObj[@"key1"] = optManaged.dateObj[@"key2"];

    XCTAssertEqualObjects(unmanaged.boolObj[@"key2"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key2"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key2"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key2"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key2"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key2"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key2"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key2"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], date(1));
}

- (void)testIndexOfObjectSorted {
    [unmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optUnmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [managed.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optManaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [unmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optUnmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [managed.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optManaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [unmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optUnmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [managed.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optManaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [unmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optUnmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [managed.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optManaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];

    XCTAssertEqual(0U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(0U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(0U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bar"]);
    XCTAssertEqual(0U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(1U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(1U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(1U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bar"]);
    XCTAssertEqual(1U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(0U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    XCTAssertEqual(0U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"foo"]);
    XCTAssertEqual(0U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);

    XCTAssertEqual(1U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
}

- (void)testIndexOfObjectDistinct {
    [unmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optUnmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [managed.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optManaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [unmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optUnmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [managed.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optManaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [unmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optUnmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [managed.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optManaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [unmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optUnmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [managed.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optManaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];

    XCTAssertEqual(1U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(1U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(1U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bar"]);
    XCTAssertEqual(1U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(0U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    XCTAssertEqual(0U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"foo"]);
    XCTAssertEqual(0U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);

    XCTAssertEqual(1U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(1U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(1U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bar"]);
    XCTAssertEqual(1U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(0U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
}

- (void)testSort {
    RLMAssertThrowsWithReason([unmanaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.boolObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([managed.boolObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.boolObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.intObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.intObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.stringObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.stringObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.dateObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.dateObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");

    [unmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optUnmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [managed.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optManaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [unmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optUnmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [managed.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optManaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [unmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optUnmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [managed.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optManaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [unmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optUnmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [managed.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optManaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@YES, @NO]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[NSNull.null, @NO]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@3, @2]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[NSNull.null, @2]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@"foo", @"bar"]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[NSNull.null, @"bar"]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[date(2), date(1)]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[NSNull.null, date(1)]));

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@YES, @NO]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@3, @2]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@"foo", @"bar"]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[date(2), date(1)]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@NO, NSNull.null]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@2, NSNull.null]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@"bar", NSNull.null]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[date(1), NSNull.null]));

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@NO, @YES]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@2, @3]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@"bar", @"foo"]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, @NO]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, @2]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, @"bar"]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, date(1)]));
}

- (void)testFilter {
    RLMAssertThrowsWithReason([unmanaged.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");

    RLMAssertThrowsWithReason([managed.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");

    RLMAssertThrowsWithReason([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
}

- (void)testNotifications {
    RLMAssertThrowsWithReason([unmanaged.boolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (void)testMin {
    RLMAssertThrowsWithReason([unmanaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool? dictionary");
    RLMAssertThrowsWithReason([unmanaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string? dictionary");
    RLMAssertThrowsWithReason([managed.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool dictionary 'AllPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool? dictionary 'AllOptionalPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string dictionary 'AllPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string? dictionary 'AllOptionalPrimitiveDictionaries.stringObj'");

    XCTAssertNil([unmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([managed.intObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([managed.dateObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.dateObj minOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optUnmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([managed.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optManaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([unmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([managed.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optManaged.dateObj minOfProperty:@"self"], date(1));
}

- (void)testMax {
    RLMAssertThrowsWithReason([unmanaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool? dictionary");
    RLMAssertThrowsWithReason([unmanaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string? dictionary");
    RLMAssertThrowsWithReason([managed.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool dictionary 'AllPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool? dictionary 'AllOptionalPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string dictionary 'AllPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string? dictionary 'AllOptionalPrimitiveDictionaries.stringObj'");

    XCTAssertNil([unmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.intObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.dateObj maxOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([managed.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([unmanaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([managed.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.intObj maxOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optManaged.intObj maxOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optUnmanaged.dateObj maxOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optManaged.dateObj maxOfProperty:@"self"], date(1));
}

- (void)testSum {
    RLMAssertThrowsWithReason([unmanaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool? dictionary");
    RLMAssertThrowsWithReason([unmanaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string? dictionary");
    RLMAssertThrowsWithReason([unmanaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date? dictionary");
    RLMAssertThrowsWithReason([managed.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool dictionary 'AllPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool? dictionary 'AllOptionalPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string dictionary 'AllPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string? dictionary 'AllOptionalPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([managed.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date dictionary 'AllPrimitiveDictionaries.dateObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date? dictionary 'AllOptionalPrimitiveDictionaries.dateObj'");

    XCTAssertEqualObjects([unmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @0);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.intObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": NSNull.null }), .001);
}

- (void)testAverage {
    RLMAssertThrowsWithReason([unmanaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool? dictionary");
    RLMAssertThrowsWithReason([unmanaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string? dictionary");
    RLMAssertThrowsWithReason([unmanaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date? dictionary");
    RLMAssertThrowsWithReason([managed.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool dictionary 'AllPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool? dictionary 'AllOptionalPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string dictionary 'AllPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string? dictionary 'AllOptionalPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([managed.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date dictionary 'AllPrimitiveDictionaries.dateObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date? dictionary 'AllOptionalPrimitiveDictionaries.dateObj'");

    XCTAssertNil([unmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj averageOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.intObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": NSNull.null }), .001);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [self addObjects];
    }

    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in unmanaged.boolObj) {
        id value = unmanaged.boolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.boolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": NSNull.null };
    for (id key in optUnmanaged.boolObj) {
        id value = optUnmanaged.boolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.boolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in managed.boolObj) {
        id value = managed.boolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.boolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": NSNull.null };
    for (id key in optManaged.boolObj) {
        id value = optManaged.boolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.boolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in unmanaged.intObj) {
        id value = unmanaged.intObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.intObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": NSNull.null };
    for (id key in optUnmanaged.intObj) {
        id value = optUnmanaged.intObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.intObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in managed.intObj) {
        id value = managed.intObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.intObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": NSNull.null };
    for (id key in optManaged.intObj) {
        id value = optManaged.intObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.intObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"bar", @"key2": @"foo" };
    for (id key in unmanaged.stringObj) {
        id value = unmanaged.stringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.stringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"bar", @"key2": NSNull.null };
    for (id key in optUnmanaged.stringObj) {
        id value = optUnmanaged.stringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.stringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"bar", @"key2": @"foo" };
    for (id key in managed.stringObj) {
        id value = managed.stringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.stringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"bar", @"key2": NSNull.null };
    for (id key in optManaged.stringObj) {
        id value = optManaged.stringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.stringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in unmanaged.dateObj) {
        id value = unmanaged.dateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.dateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": NSNull.null };
    for (id key in optUnmanaged.dateObj) {
        id value = optUnmanaged.dateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.dateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in managed.dateObj) {
        id value = managed.dateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.dateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": NSNull.null };
    for (id key in optManaged.dateObj) {
        id value = optManaged.dateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.dateObj.count);
    }
    
}

- (void)testValueForKeyNumericAggregates {
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@sum.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@sum.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@sum.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@sum.self"]);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@avg.self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@max.self"], @2);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @2);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@max.self"], date(1));
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(1));
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": NSNull.null }), .001);
}

// Sort the distinct results to match the order used in values, as it
// doesn't preserve the order naturally
static NSArray *sortedDistinctUnion(id array, NSString *type, NSString *prop) {
    return [[array valueForKeyPath:[NSString stringWithFormat:@"@distinctUnionOf%@.%@", type, prop]]
            sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                bool aIsNull = a == NSNull.null;
                bool bIsNull = b == NSNull.null;
                if (aIsNull && bIsNull) {
                    return 0;
                }
                if (aIsNull) {
                    return 1;
                }
                if (bIsNull) {
                    return -1;
                }

                if ([a isKindOfClass:[NSData class]]) {
                    if ([a length] != [b length]) {
                        return [a length] < [b length] ? -1 : 1;
                    }
                    int result = memcmp([a bytes], [b bytes], [a length]);
                    if (!result) {
                        return 0;
                    }
                    return result < 0 ? -1 : 1;
                }

                if ([a isKindOfClass:[RLMObjectId class]]) {
                    int64_t idx1 = [objectIds indexOfObject:a];
                    int64_t idx2 = [objectIds indexOfObject:b];
                    return idx1 - idx2;
                }

                return [a compare:b];
            }];
}

- (void)testSetValueForKey {
    RLMAssertThrowsWithReason([unmanaged.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj setValue:NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.boolObj setValue:NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.intObj setValue:NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.stringObj setValue:NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.dateObj setValue:NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");

    [self addObjects];

    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));

    [optUnmanaged.boolObj setValue:NSNull.null forKey:@"key1"];
    [optManaged.boolObj setValue:NSNull.null forKey:@"key1"];
    [optUnmanaged.intObj setValue:NSNull.null forKey:@"key1"];
    [optManaged.intObj setValue:NSNull.null forKey:@"key1"];
    [optUnmanaged.stringObj setValue:NSNull.null forKey:@"key1"];
    [optManaged.stringObj setValue:NSNull.null forKey:@"key1"];
    [optUnmanaged.dateObj setValue:NSNull.null forKey:@"key1"];
    [optManaged.dateObj setValue:NSNull.null forKey:@"key1"];
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], NSNull.null);
}

- (void)testAssignment {
    unmanaged.boolObj = (id)@{@"key2": @YES};
    XCTAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    optUnmanaged.boolObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    managed.boolObj = (id)@{@"key2": @YES};
    XCTAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    optManaged.boolObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    unmanaged.intObj = (id)@{@"key2": @3};
    XCTAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    optUnmanaged.intObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    managed.intObj = (id)@{@"key2": @3};
    XCTAssertEqualObjects(managed.intObj[@"key2"], @3);
    optManaged.intObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    unmanaged.stringObj = (id)@{@"key2": @"foo"};
    XCTAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    optUnmanaged.stringObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    managed.stringObj = (id)@{@"key2": @"foo"};
    XCTAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    optManaged.stringObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    unmanaged.dateObj = (id)@{@"key2": date(2)};
    XCTAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    optUnmanaged.dateObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    managed.dateObj = (id)@{@"key2": date(2)};
    XCTAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    optManaged.dateObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);

    [unmanaged.intObj removeAllObjects];
    unmanaged.intObj = managed.intObj;

    XCTAssertEqual(unmanaged.intObj.count, 1);
    XCTAssertEqualObjects(unmanaged.intObj.allValues, managed.intObj.allValues);

    [managed.intObj removeAllObjects];
    managed.intObj = unmanaged.intObj;

    XCTAssertEqual(managed.intObj.count, 1);
    XCTAssertEqualObjects(managed.intObj.allValues, unmanaged.intObj.allValues);
}

- (void)testInvalidAssignment {
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@{@"0": NSNull.null},
                              @"Invalid value '<null>' of type 'NSNull' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@{@"0": @"a"},
                              @"Invalid value 'a' of type '__NSCFConstantString' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)(@{@"0": @1, @"1": @"a"}),
                              @"Invalid value 'a' of type '__NSCFConstantString' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)unmanaged.floatObj,
                              @"RLMDictionary<string, float> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)optUnmanaged.intObj,
                              @"RLMDictionary<string, int?> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = unmanaged[@"floatObj"],
                              @"RLMDictionary<string, float> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = optUnmanaged[@"intObj"],
                              @"RLMDictionary<string, int?> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");

    RLMAssertThrowsWithReason(managed.intObj = (id)@{@"0": NSNull.null},
                              @"Invalid value '<null>' of type 'NSNull' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)@{@"0": @"a"},
                              @"Invalid value 'a' of type '__NSCFConstantString' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)(@{@"0": @1, @"1": @"a"}),
                              @"Invalid value 'a' of type '__NSCFConstantString' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)managed.floatObj,
                              @"RLMDictionary<string, float> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)optManaged.intObj,
                              @"RLMDictionary<string, int?> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)managed[@"floatObj"],
                              @"RLMDictionary<string, float> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)optManaged[@"intObj"],
                              @"RLMDictionary<string, int?> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
}

- (void)testAllMethodsCheckThread {
    RLMDictionary *dictionary = managed.intObj;
    [self dispatchAsyncAndWait:^{
        RLMAssertThrowsWithReason([dictionary count], @"thread");
        RLMAssertThrowsWithReason([dictionary objectAtIndex:0], @"thread");
        RLMAssertThrowsWithReason(dictionary[@"0"], @"thread");
        RLMAssertThrowsWithReason([dictionary count], @"thread");

        RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"thread"], @"thread");
        RLMAssertThrowsWithReason([dictionary addEntriesFromDictionary:@{@"thread": @0}], @"thread");
        RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"thread"], @"thread");
        RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"thread"]], @"thread");
        RLMAssertThrowsWithReason([dictionary removeAllObjects], @"thread");
        RLMAssertThrowsWithReason([optManaged.intObj setObject:NSNull.null forKey:@"thread"], @"thread");

        RLMAssertThrowsWithReason([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES], @"thread");
        RLMAssertThrowsWithReason([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"thread");
        RLMAssertThrowsWithReason(dictionary[@"thread"], @"thread");
        RLMAssertThrowsWithReason(dictionary[@"thread"] = @0, @"thread");
        RLMAssertThrowsWithReason([dictionary valueForKey:@"self"], @"thread");
        RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"thread");
        RLMAssertThrowsWithReason({for (__unused id obj in dictionary);}, @"thread");
    }];
}

- (void)testAllMethodsCheckForInvalidation {
    RLMDictionary *dictionary = managed.intObj;
    [realm cancelWriteTransaction];
    [realm invalidate];

    XCTAssertNoThrow([dictionary objectClassName]);
    XCTAssertNoThrow([dictionary realm]);
    XCTAssertNoThrow([dictionary isInvalidated]);
    
    RLMAssertThrowsWithReason([dictionary count], @"invalidated");
    RLMAssertThrowsWithReason([dictionary objectAtIndex:0], @"invalidated");
    RLMAssertThrowsWithReason(dictionary[@"0"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary count], @"invalidated");

    RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"thread"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary addEntriesFromDictionary:@{@"invalidated": @0}], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"invalidated"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"invalidated"]], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeAllObjects], @"invalidated");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:NSNull.null forKey:@"invalidated"], @"invalidated");

    RLMAssertThrowsWithReason([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES], @"invalidated");
    RLMAssertThrowsWithReason([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"invalidated");
    RLMAssertThrowsWithReason(dictionary[@"invalidated"], @"invalidated");
    RLMAssertThrowsWithReason(dictionary[@"invalidated"] = @0, @"invalidated");
    RLMAssertThrowsWithReason([dictionary valueForKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason({for (__unused id obj in dictionary);}, @"invalidated");

    [realm beginWriteTransaction];
}

- (void)testMutatingMethodsCheckForWriteTransaction {
    RLMDictionary *dictionary = managed.intObj;
    [dictionary setObject:@0 forKey:@"testKey"];
    [realm commitWriteTransaction];

    XCTAssertNoThrow([dictionary objectClassName]);
    XCTAssertNoThrow([dictionary realm]);
    XCTAssertNoThrow([dictionary isInvalidated]);

    XCTAssertNoThrow([dictionary count]);
    XCTAssertNoThrow([dictionary objectAtIndex:0]);
    XCTAssertNoThrow(dictionary[@"0"]);
    XCTAssertNoThrow([dictionary count]);

    XCTAssertNoThrow([dictionary indexOfObject:@1]);
    XCTAssertNoThrow([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES]);
    XCTAssertNoThrow([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]]);
    XCTAssertNoThrow(dictionary[@"0"]);
    XCTAssertNoThrow([dictionary valueForKey:@"self"]);
    XCTAssertNoThrow({for (__unused id obj in dictionary);});
    
    RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"testKey"], @"write transaction");
    RLMAssertThrowsWithReason([dictionary addEntriesFromDictionary:@{@"testKey": @0}], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"testKey"], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"testKey"]], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeAllObjects], @"write transaction");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:NSNull.null forKey:@"testKey"], @"write transaction");

    RLMAssertThrowsWithReason(dictionary[@"testKey"] = @0, @"write transaction");
    RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"write transaction");
}

- (void)testDeleteOwningObject {
    RLMDictionary *dictionary = managed.intObj;
    XCTAssertFalse(dictionary.isInvalidated);
    [realm deleteObject:managed];
    XCTAssertTrue(dictionary.isInvalidated);
}

#pragma clang diagnostic ignored "-Warc-retain-cycles"

- (void)testNotificationSentInitially {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssertNil(change);
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationSentAfterCommit {
    [realm commitWriteTransaction];

    __block bool first = true;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssertNil(error);
        if (first) {
            XCTAssertNil(change);
        }
        else {
            XCTAssertEqualObjects(change.insertions, @[@0]);
        }

        first = false;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{
        RLMRealm *r = [RLMRealm defaultRealm];
        [r transactionWithBlock:^{
            RLMDictionary *dictionary = [(AllPrimitiveDictionaries *)[AllPrimitiveDictionaries allObjectsInRealm:r].firstObject intObj];
            dictionary[@"testKey"] = @0;
        }];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationNotSentForUnrelatedChange {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(__unused RLMDictionary *dictionary, __unused RLMCollectionChange *change, __unused NSError *error) {
        // will throw if it's incorrectly called a second time due to the
        // unrelated write transaction
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // All notification blocks are called as part of a single runloop event, so
    // waiting for this one also waits for the above one to get a chance to run
    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        [self dispatchAsyncAndWait:^{
            RLMRealm *r = [RLMRealm defaultRealm];
            [r transactionWithBlock:^{
                [AllPrimitiveDictionaries createInRealm:r withValue:@[]];
            }];
        }];
    }];
    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationSentOnlyForActualRefresh {
    [realm commitWriteTransaction];

    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, __unused RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssertNil(error);
        // will throw if it's called a second time before we create the new
        // expectation object immediately before manually refreshing
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Turn off autorefresh, so the background commit should not result in a notification
    realm.autorefresh = NO;

    // All notification blocks are called as part of a single runloop event, so
    // waiting for this one also waits for the above one to get a chance to run
    [self waitForNotification:RLMRealmRefreshRequiredNotification realm:realm block:^{
        [self dispatchAsyncAndWait:^{
            RLMRealm *r = [RLMRealm defaultRealm];
            [r transactionWithBlock:^{
                RLMDictionary *dictionary = [(AllPrimitiveDictionaries *)[AllPrimitiveDictionaries allObjectsInRealm:r].firstObject intObj];
                dictionary[@"testKey"] = @0;
            }];
        }];
    }];

    expectation = [self expectationWithDescription:@""];
    [realm refresh];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testDeletingObjectWithNotificationsRegistered {
    [managed.intObj addEntriesFromDictionary:@{@"a": @10, @"b": @20}];
    [realm commitWriteTransaction];

    __block bool first = true;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssertNil(error);
        if (first) {
            XCTAssertNil(change);
            first = false;
        }
        else {
            XCTAssertEqualObjects(change.deletions, (@[@0, @1]));
        }
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [realm beginWriteTransaction];
    [realm deleteObject:managed];
    [realm commitWriteTransaction];

    expectation = [self expectationWithDescription:@""];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

#pragma mark - Queries

#define RLMAssertCount(cls, expectedCount, ...) \
    XCTAssertEqual(expectedCount, ([cls objectsInRealm:realm where:__VA_ARGS__].count))

- (void)createObject {
    id boolObj = @{@"key1": @NO};
    id intObj = @{@"key1": @2};
    id stringObj = @{@"key1": @"bar"};
    id dateObj = @{@"key1": date(1)};
    
    id obj = [AllPrimitiveDictionaries createInRealm:realm withValue: @{
        @"boolObj": boolObj,
        @"intObj": intObj,
        @"stringObj": stringObj,
        @"dateObj": dateObj,
    }];
    [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
    obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"boolObj": boolObj,
        @"intObj": intObj,
        @"stringObj": stringObj,
        @"dateObj": dateObj,
    }];
    [LinkToAllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
}

- (void)testQueryBasicOperators {
    [realm deleteAllObjects];

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj = %@", @"bar");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj = %@", @"bar");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj != %@", @"bar");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj != %@", @"bar");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj <= %@", date(1));

    [self createObject];

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj = %@", @YES);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj = %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj = %@", @"foo");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj = %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY stringObj = %@", @"bar");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY stringObj = %@", @"bar");
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj != %@", @"bar");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj != %@", @"bar");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY boolObj != %@", @YES);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY boolObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj != %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY stringObj != %@", @"foo");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY stringObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj != %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj < %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj <= %@", date(1));

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY stringObj > %@", @"bar"]),
                              @"Operator '>' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY stringObj > %@", @"bar"]),
                              @"Operator '>' not supported for type 'string'");
}

- (void)testQueryBetween {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY boolObj BETWEEN %@", @[@NO, @YES]]),
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY boolObj BETWEEN %@", @[@NO, NSNull.null]]),
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY stringObj BETWEEN %@", @[@"bar", @"foo"]]),
                              @"Operator 'BETWEEN' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY stringObj BETWEEN %@", @[@"bar", NSNull.null]]),
                              @"Operator 'BETWEEN' not supported for type 'string'");

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[@2, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[date(1), NSNull.null]);

    [self createObject];

    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[@2, NSNull.null]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[date(1), NSNull.null]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[NSNull.null, NSNull.null]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[NSNull.null, NSNull.null]);
}

- (void)testQueryIn {
    [realm deleteAllObjects];

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj IN %@", @[@NO, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj IN %@", @[@2, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj IN %@", @[@"bar", @"foo"]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj IN %@", @[@"bar", NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj IN %@", @[date(1), NSNull.null]);

    [self createObject];

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj IN %@", @[@YES]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj IN %@", @[NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj IN %@", @[@3]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj IN %@", @[NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj IN %@", @[@"foo"]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj IN %@", @[NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj IN %@", @[date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj IN %@", @[NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY boolObj IN %@", @[@NO, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj IN %@", @[@2, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY stringObj IN %@", @[@"bar", @"foo"]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY stringObj IN %@", @[@"bar", NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj IN %@", @[date(1), NSNull.null]);
}

- (void)testQueryCount {
    [realm deleteAllObjects];

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"boolObj": @{ @"key1": @NO, @"key2": @YES },
        @"intObj": @{ @"key1": @2, @"key2": @3 },
        @"stringObj": @{ @"key1": @"bar", @"key2": @"foo" },
        @"dateObj": @{ @"key1": date(1), @"key2": date(2) },
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"boolObj": @{ @"key1": @NO, @"key2": NSNull.null },
        @"intObj": @{ @"key1": @2, @"key2": NSNull.null },
        @"stringObj": @{ @"key1": @"bar", @"key2": NSNull.null },
        @"dateObj": @{ @"key1": date(1), @"key2": NSNull.null },
    }];

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"boolObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"boolObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"stringObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"stringObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"boolObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"boolObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"stringObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"stringObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"boolObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"boolObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"intObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"intObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"stringObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"stringObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"dateObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"dateObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"boolObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"boolObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"intObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"intObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"stringObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"stringObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"dateObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"dateObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"boolObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"boolObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"intObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"intObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"stringObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"stringObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"dateObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"dateObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"boolObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"boolObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"intObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"intObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"stringObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"stringObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"dateObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"dateObj.@count <= %@", @(2));
}

- (void)testQuerySum {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@sum = %@", @NO]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@sum = %@", @NO]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@sum = %@", @"bar"]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@sum = %@", @"bar"]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]),
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]),
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]),
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]),
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type int cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type int cannot be compared with '<null>'");

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @[],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @[],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": @3 },
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": NSNull.null },
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": @3 },
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": NSNull.null },
    }];
//
//    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@sum == %@", @0);
//    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@sum != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@sum != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 2U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@sum < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 2U, @"intObj.@sum < %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@sum <= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 2U, @"intObj.@sum <= %@", NSNull.null);
}

- (void)testQueryAverage {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@avg = %@", @NO]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@avg = %@", @NO]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@avg = %@", @"bar"]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@avg = %@", @"bar"]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]),
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]),
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]),
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]),
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @[],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @[],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": @3 },
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": NSNull.null },
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @3},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": NSNull.null},
    }];

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@avg == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@avg == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@avg != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@avg != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@avg >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@avg >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 2U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@avg < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 2U, @"intObj.@avg < %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@avg <= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@avg <= %@", NSNull.null);
}

- (void)testQueryMin {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@min = %@", @NO]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@min = %@", @NO]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@min = %@", @"bar"]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@min = %@", @"bar"]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min = %@", @"a"]),
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min = %@", @"a"]),
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]),
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]),
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(1));

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty dictionarys, so count is zero
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == %@", NSNull.null);

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == %@", NSNull.null);

    [self createObject];

    // One object where v0 is min and zero with v1
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@min == %@", NSNull.null);
}

- (void)testQueryMax {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@max = %@", @NO]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@max = %@", @NO]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@max = %@", @"bar"]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@max = %@", @"bar"]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max = %@", @"a"]),
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max = %@", @"a"]),
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]),
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]),
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(1));

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty dictionarys, so count is zero
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@max == %@", NSNull.null);

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@max == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@max == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@max == %@", NSNull.null);

    [self createObject];

    // One object where v0 is min and zero with v1
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@max == %@", NSNull.null);
}

- (void)testQueryBasicOperatorsOverLink {
    [realm deleteAllObjects];

    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.stringObj = %@", @"bar");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.stringObj = %@", @"bar");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.stringObj != %@", @"bar");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.stringObj != %@", @"bar");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj <= %@", date(1));

    [self createObject];

    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.boolObj = %@", @YES);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.boolObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj = %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.stringObj = %@", @"foo");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.stringObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj = %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.stringObj = %@", @"bar");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.stringObj = %@", @"bar");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.stringObj != %@", @"bar");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.stringObj != %@", @"bar");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.boolObj != %@", @YES);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.boolObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj != %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.intObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.stringObj != %@", @"foo");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.stringObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj != %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.dateObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj < %@", @3);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj < %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.dateObj <= %@", date(1));

    RLMAssertThrowsWithReason(([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.stringObj > %@", @"bar"]),
                              @"Operator '>' not supported for type 'string'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.stringObj > %@", @"bar"]),
                              @"Operator '>' not supported for type 'string'");
}

- (void)testSubstringQueries {
    [realm deleteAllObjects];
    NSArray *values = @[
        @"",

        @"á", @"ó", @"ú",

        @"áá", @"áó", @"áú",
        @"óá", @"óó", @"óú",
        @"úá", @"úó", @"úú",

        @"ááá", @"ááó", @"ááú", @"áóá", @"áóó", @"áóú", @"áúá", @"áúó", @"áúú",
        @"óáá", @"óáó", @"óáú", @"óóá", @"óóó", @"óóú", @"óúá", @"óúó", @"óúú",
        @"úáá", @"úáó", @"úáú", @"úóá", @"úóó", @"úóú", @"úúá", @"úúó", @"úúú",
    ];

    void (^create)(NSString *) = ^(NSString *value) {
        id obj = [AllPrimitiveDictionaries createInRealm:realm withValue:@{
            @"stringObj": @{@"key": value},
            @"dataObj": @{@"key": [value dataUsingEncoding:NSUTF8StringEncoding]}
        }];
        [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
        obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
            @"stringObj": @{@"key": value},
            @"dataObj": @{@"key": [value dataUsingEncoding:NSUTF8StringEncoding]}
        }];
        [LinkToAllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
    };

    for (NSString *value in values) {
        create(value);
        create(value.uppercaseString);
        create([value stringByApplyingTransform:NSStringTransformStripDiacritics reverse:NO]);
        create([value.uppercaseString stringByApplyingTransform:NSStringTransformStripDiacritics reverse:NO]);
    }

    void (^test)(NSString *, id, NSUInteger) = ^(NSString *operator, NSString *value, NSUInteger count) {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];

        NSString *query = [NSString stringWithFormat:@"ANY stringObj %@ %%@", operator];
//        RLMAssertCount(AllPrimitiveDictionaries, count, query, value);
//        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, value);
//        query = [NSString stringWithFormat:@"ANY link.stringObj %@ %%@", operator];
//        RLMAssertCount(LinkToAllPrimitiveDictionaries, count, query, value);
//        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, value);

        query = [NSString stringWithFormat:@"ANY dataObj %@ %%@", operator];
        RLMAssertCount(AllPrimitiveDictionaries, count, query, data);
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, data);
        query = [NSString stringWithFormat:@"ANY link.dataObj %@ %%@", operator];
        RLMAssertCount(LinkToAllPrimitiveDictionaries, count, query, data);
        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, data);
    };
    void (^testNull)(NSString *, NSUInteger) = ^(NSString *operator, NSUInteger count) {
        NSString *query = [NSString stringWithFormat:@"ANY stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Expected object of type string for property 'stringObj' on object of type 'AllPrimitiveDictionaries', but received: (null)");
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, NSNull.null);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Expected object of type string for property 'link.stringObj' on object of type 'LinkToAllPrimitiveDictionaries', but received: (null)");
        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Expected object of type data for property 'dataObj' on object of type 'AllPrimitiveDictionaries', but received: (null)");
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY link.dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Expected object of type data for property 'link.dataObj' on object of type 'LinkToAllPrimitiveDictionaries', but received: (null)");
        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, NSNull.null);
    };

    // Core's implementation of case-insensitive comparisons only works for
    // unaccented a-z, so the diacritic-sensitive, case-insensitive queries
    // match half as many as they should. Many of the below tests will start
    // failing if this is fixed.

    testNull(@"==", 0);
    test(@"==", @"", 4);
    test(@"==", @"a", 1);
    test(@"==", @"á", 1);
    test(@"==[c]", @"a", 2);
    test(@"==[c]", @"á", 1);
    test(@"==", @"A", 1);
    test(@"==", @"Á", 1);
    test(@"==[c]", @"A", 2);
    test(@"==[c]", @"Á", 1);
    test(@"==[d]", @"a", 2);
    test(@"==[d]", @"á", 2);
    test(@"==[cd]", @"a", 4);
    test(@"==[cd]", @"á", 4);
    test(@"==[d]", @"A", 2);
    test(@"==[d]", @"Á", 2);
    test(@"==[cd]", @"A", 4);
    test(@"==[cd]", @"Á", 4);

    testNull(@"!=", 160);
    test(@"!=", @"", 156);
    test(@"!=", @"a", 159);
    test(@"!=", @"á", 159);
    test(@"!=[c]", @"a", 158);
    test(@"!=[c]", @"á", 159);
    test(@"!=", @"A", 159);
    test(@"!=", @"Á", 159);
    test(@"!=[c]", @"A", 158);
    test(@"!=[c]", @"Á", 159);
    test(@"!=[d]", @"a", 158);
    test(@"!=[d]", @"á", 158);
    test(@"!=[cd]", @"a", 156);
    test(@"!=[cd]", @"á", 156);
    test(@"!=[d]", @"A", 158);
    test(@"!=[d]", @"Á", 158);
    test(@"!=[cd]", @"A", 156);
    test(@"!=[cd]", @"Á", 156);

    testNull(@"CONTAINS", 0);
    testNull(@"CONTAINS[c]", 0);
    testNull(@"CONTAINS[d]", 0);
    testNull(@"CONTAINS[cd]", 0);
    test(@"CONTAINS", @"a", 25);
    test(@"CONTAINS", @"á", 25);
    test(@"CONTAINS[c]", @"a", 50);
    test(@"CONTAINS[c]", @"á", 25);
    test(@"CONTAINS", @"A", 25);
    test(@"CONTAINS", @"Á", 25);
    test(@"CONTAINS[c]", @"A", 50);
    test(@"CONTAINS[c]", @"Á", 25);
    test(@"CONTAINS[d]", @"a", 50);
    test(@"CONTAINS[d]", @"á", 50);
    test(@"CONTAINS[cd]", @"a", 100);
    test(@"CONTAINS[cd]", @"á", 100);
    test(@"CONTAINS[d]", @"A", 50);
    test(@"CONTAINS[d]", @"Á", 50);
    test(@"CONTAINS[cd]", @"A", 100);
    test(@"CONTAINS[cd]", @"Á", 100);

    test(@"BEGINSWITH", @"a", 13);
    test(@"BEGINSWITH", @"á", 13);
    test(@"BEGINSWITH[c]", @"a", 26);
    test(@"BEGINSWITH[c]", @"á", 13);
    test(@"BEGINSWITH", @"A", 13);
    test(@"BEGINSWITH", @"Á", 13);
    test(@"BEGINSWITH[c]", @"A", 26);
    test(@"BEGINSWITH[c]", @"Á", 13);
    test(@"BEGINSWITH[d]", @"a", 26);
    test(@"BEGINSWITH[d]", @"á", 26);
    test(@"BEGINSWITH[cd]", @"a", 52);
    test(@"BEGINSWITH[cd]", @"á", 52);
    test(@"BEGINSWITH[d]", @"A", 26);
    test(@"BEGINSWITH[d]", @"Á", 26);
    test(@"BEGINSWITH[cd]", @"A", 52);
    test(@"BEGINSWITH[cd]", @"Á", 52);

    test(@"ENDSWITH", @"a", 13);
    test(@"ENDSWITH", @"á", 13);
    test(@"ENDSWITH[c]", @"a", 26);
    test(@"ENDSWITH[c]", @"á", 13);
    test(@"ENDSWITH", @"A", 13);
    test(@"ENDSWITH", @"Á", 13);
    test(@"ENDSWITH[c]", @"A", 26);
    test(@"ENDSWITH[c]", @"Á", 13);
    test(@"ENDSWITH[d]", @"a", 26);
    test(@"ENDSWITH[d]", @"á", 26);
    test(@"ENDSWITH[cd]", @"a", 52);
    test(@"ENDSWITH[cd]", @"á", 52);
    test(@"ENDSWITH[d]", @"A", 26);
    test(@"ENDSWITH[d]", @"Á", 26);
    test(@"ENDSWITH[cd]", @"A", 52);
    test(@"ENDSWITH[cd]", @"Á", 52);
}

@end
