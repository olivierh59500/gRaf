//
// Created by Andrey Vokin on 26/06/15.
// Copyright (c) 2015 Andrey Vokin. All rights reserved.
//

import gRaf
import Foundation
import Cocoa
import XCTest

class FSUtilTest : XCTestCase {
    func testExample() {
        let users = TestUtil.findFileInRoot("Users")

        XCTAssertNotNil(users)
    }

    func testDirectoryCheck() {
        let v  = TestUtil.findFileInRoot("var")
        XCTAssertNotNil(v)
        XCTAssert(v!.isDirectory)
    }

    func testCopyFile() {
        let from = TestUtil.findFileInRoot(".DS_Store")
        XCTAssertNotNil(from)

        let to = TestUtil.findFileInRoot("tmp")
        XCTAssertNotNil(to)

        let newFilePath = FSUtil.getDestinationFileName(from!, to: to!)
        var err: NSError?
        do {
            try NSFileManager.defaultManager().removeItemAtPath(newFilePath)
        } catch let error as NSError {
            err = error
        };

        XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(newFilePath))

        FSUtil.copyFile(from!.path, to: newFilePath)
        XCTAssert(NSFileManager.defaultManager().fileExistsAtPath(newFilePath))
    }

    func testDeleteFile() {
        let from = TestUtil.findFileInRoot(".DS_Store")
        XCTAssertNotNil(from)

        let to = TestUtil.findFileInRoot("tmp")
        XCTAssertNotNil(to)

        let newFilePath = FSUtil.getDestinationFileName(from!, to: to!)

        FSUtil.copyFile(from!.path, to: newFilePath)
        XCTAssert(NSFileManager.defaultManager().fileExistsAtPath(newFilePath))

        FSUtil.deleteFile(newFilePath)

        XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(newFilePath))
    }
}
