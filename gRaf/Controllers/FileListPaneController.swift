//
// Created by Andrey Vokin on 22/09/15.
// Copyright (c) 2015 Andrey Vokin. All rights reserved.
//

import Cocoa
import Foundation

class FileListPaneController : PaneController, NSTableViewDataSource, NSTableViewDelegate {
    var model = PaneModel()
    var tableView: NSTableView!

    let COLUMN_TYPE_ID = "Type"
    let COLUMN_NAME_ID = "Name"
    let COLUMN_SIZE_ID = "Size"
    let COLUMN_DATE_MODIFIED_ID = "Date modified"

    init?(root: File, from: File?) {
        super.init(nibName: nil, bundle: nil)

        model.setRoot(root)
        if from != nil {
            model.selectChild(from!.name)
        }

        createTable()
        view = tableView
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        tableView.selectRowIndexes(NSIndexSet(index: model.selectedIndex), byExtendingSelection: false)
        tableView.scrollRowToVisible(model.selectedIndex)
    }

    override func focus() {
        super.focus()
        window!.makeFirstResponder(tableView)
    }

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return model.getItems().count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        var file: File = model.getItems()[row]
        if (equal(tableColumn!.identifier, COLUMN_TYPE_ID)) {
            return nil
        } else if (equal(tableColumn!.identifier, COLUMN_NAME_ID)) {
            return file.name
        } else if (equal(tableColumn!.identifier, COLUMN_SIZE_ID)) {
            if file.isDirectory {
                return ""
            }
            return TextUtil.getSizeText(file.size)
        } else {
            if let modificationDate = file.dateModified {
                return TextUtil.getDateText(modificationDate)
            } else {
                return ""
            }
        }
    }

    func tableView(tableView: NSTableView, dataCellForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if tableColumn != nil && equal(tableColumn!.identifier, COLUMN_TYPE_ID) {
            var file: File = model.getItems()[row]
            var image = NSImage(named: "file")
            if file.isDirectory {
                image = NSImage(named: "folder")
            }
            return NSCell(imageCell: image)
        } else {
            return nil
        }
    }

    func tableView(tableView: NSTableView, shouldEditTableColumn tableColumn: NSTableColumn?, row: Int) -> Bool {
        return tableColumn != nil && equal(tableColumn!.identifier, COLUMN_NAME_ID)
    }

    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        if let newName = object {
            var file = model.getItems()[row]
            FSUtil.rename(file, newName: "\(object!)")
            model.clearCaches()
            model.selectChild("\(object!)")
            tableView.reloadData()
            tableView.selectRowIndexes(NSIndexSet(index: model.selectedIndex), byExtendingSelection: false)
            tableView.scrollRowToVisible(model.selectedIndex)
        }
    }

    override func keyDown(theEvent: NSEvent) {
        if theEvent.keyCode == 99 {
            var file = model.getItems()[tableView.selectedRow]
            appDelegate.createFileViewController(self, file: file)
        } else if theEvent.keyCode == 36 {
            let tableView: NSTableView = view as! NSTableView
            var file : File = model.getItems()[tableView.selectedRow]

            if theEvent.modifierFlags & NSEventModifierFlags.ShiftKeyMask != nil {
                let showFolder = NSTask()
                if file.isDirectory {
                    showFolder.launchPath = "/usr/bin/open"
                    showFolder.arguments = [file.path]
                    showFolder.launch()
                } else {
                    NSWorkspace.sharedWorkspace().openFile(file.path)
                }

                return
            }

            if (equal("..", file.name)) {
                var previousRoot = model.getRoot()
                var newRoot = previousRoot.getParent()
                model.setRoot(newRoot!)
                model.selectChild(previousRoot.name)
            } else {
                // ToDo: use model.selectedIndex
                var selectedFile = model.getItems()[tableView.selectedRow]
                model.selectedIndex = 0
                model.setRoot(selectedFile)
            }

            tableView.reloadData()
            tableView.selectRowIndexes(NSIndexSet(index: model.selectedIndex), byExtendingSelection: false)
            tableView.scrollRowToVisible(model.selectedIndex)
        } else if theEvent.keyCode == 48 {
            otherPaneController.focus()
        } else if theEvent.keyCode == 96 {
            // ToDo: use model.selectedIndex
            if let fileListController = otherPaneController as? FileListPaneController {
                var from = model.getItems()[tableView.selectedRow]
                var to = fileListController.model.getRoot();

                FileActions.copyFileAction(from, to: to)
                refresh()
            }
        } else if theEvent.keyCode == 97 {
            if let fileListController = otherPaneController as? FileListPaneController {
                var from = model.getItems()[tableView.selectedRow]
                var to = fileListController.model.getRoot();

                FileActions.moveFileAction(from, to: to)
                refresh()
            }
        } else if theEvent.keyCode == 100 {
            var file = model.getItems()[tableView.selectedRow]
            FileActions.deleteFileAction(file)
            refresh()
        } else if theEvent.keyCode == 116 {
            if theEvent.modifierFlags & NSEventModifierFlags.FunctionKeyMask != nil {
                model.selectedIndex = 0
                tableView.selectRowIndexes(NSIndexSet(index: model.selectedIndex), byExtendingSelection: false)
                tableView.scrollRowToVisible(model.selectedIndex)
            }
        } else {
            super.keyDown(theEvent)
        }
    }

    func refresh() {
        focus()
        model.clearCaches()
        tableView.reloadData()

        if let fileListController = otherPaneController as? FileListPaneController {
            fileListController.model.clearCaches()
            fileListController.tableView.reloadData()
        }
    }

    func createColumn(name: String) -> NSTableColumn {
        var column = NSTableColumn(identifier: name)
        var headerCell = NSTableHeaderCell()
        headerCell.objectValue = name
        column.headerCell = headerCell

        column.sortDescriptorPrototype = NSSortDescriptor(key: name, ascending: true)
        return column
    }

    func createTable() {
        tableView = FileTableView()
        var typeColumn = createColumn(COLUMN_TYPE_ID)
        typeColumn.width = 30
        tableView.addTableColumn(typeColumn)

        var nameColumn = createColumn(COLUMN_NAME_ID)
        nameColumn.width = 300
        tableView.addTableColumn(nameColumn)

        var sizeColumn = createColumn(COLUMN_SIZE_ID)
        sizeColumn.width = 80
        tableView.addTableColumn(sizeColumn)

        tableView.addTableColumn(createColumn(COLUMN_DATE_MODIFIED_ID))

        tableView.focusRingType = NSFocusRingType.None

        tableView.setDataSource(self);
        tableView.setDelegate(self)
    }

    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [AnyObject]) {
        var descriptors = tableView.sortDescriptors
        if let first = descriptors[0] as? NSSortDescriptor {
            model.setSortDescriptor(first)
            tableView.reloadData()
        }
    }
}