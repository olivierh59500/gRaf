//
// Created by Andrey Vokin on 29/06/15.
// Copyright (c) 2015 Andrey Vokin. All rights reserved.
//

import Foundation

public class FSUtil {
    static func getFilesOfDirectory(path: String) -> [File] {
        let fileManager = NSFileManager.defaultManager()

        var files = [File]()

        var allFiles = fileManager.contentsOfDirectoryAtPath(path, error: nil)

        if !equal("/", path) {
            var linkToParent = File(name: "..", path: path, size: UInt64.max, dateModified: NSDate(), isDirectory: true)
            files.append(linkToParent)
        }

        if allFiles is [String] {
            var allSuperFiles = allFiles as! [String]
            for element: String in allSuperFiles {
                var size: UInt64 = 0
                var isDirectory = false
                var elementPath = path + "/" + element

                var i = 0
                while i < 3 {
                    i++
                    var attributes:NSDictionary? = fileManager.attributesOfItemAtPath(elementPath, error: nil)
                    if let _attr = attributes {
                        if let fileType1 = _attr.fileType() {
                            if (equal("NSFileTypeSymbolicLink", fileType1)) {
                                var newPathElement = fileManager.destinationOfSymbolicLinkAtPath(elementPath, error: nil)

                                if newPathElement != nil {
                                    elementPath = path + "/" + newPathElement!
                                } else {
                                    println("for: " + elementPath + ", found: nil")
                                    break;
                                }
                            } else {
                                if equal("NSFileTypeDirectory", fileType1) {
                                    isDirectory = true
                                    break;
                                }
                            }
                        }
                        size = _attr.fileSize()
                    } else {
                        break
                    }
                }

                var file = File(name: element, path: path + "/" + element, size: size, dateModified: NSDate(), isDirectory: isDirectory)

                files.append(file)
            }
        }

        return files
    }

    static func copyFile(from: String, to: String) {
        let fileManager = NSFileManager.defaultManager()
        fileManager.copyItemAtPath(from, toPath: to, error: nil)
    }

}