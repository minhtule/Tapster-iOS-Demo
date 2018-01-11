//
//  DataViewController.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/23/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import UIKit
import PredictionIO

class DataViewController: UIViewController {
    let eventClient = EventClient(accessKey: "")

    @IBAction func importDataButtonAction(_ sender: UIButton) {
        self.readCSVDataAndImport()
    }
    
    private func readCSVDataAndImport() {
        
        // MARK: - episodes data
        let episodeData = CSVData(fileName: "episode_list")
        
        print("Found \(episodeData.rows.count) unique episode")
        print("Sending episodes data...")

        processRows(episodeData.rows, messagePrefix: "Sending episode") { row in
            let properties: [String: Any] = [
                "title": row[1],
                "categories": convertCategories(row[2]),
                "imageURLs": convertImageURLs(row[4]),
                ]
            return Event(event: Event.setEvent, entityType: Event.itemEntityType, entityID: row[0], properties: properties)
        }

        // MARK: - users data
        
        let likesData = CSVData(fileName: "user_list")
        let userIDs = likesData.uniqueEntries(column: 0)
        
        print("Found \(userIDs.count) unique user IDs")
        print("Sending users data...")

        let userIDRows = userIDs.map { [$0] }
        processRows(userIDRows, messagePrefix: "Sending user") { row in
            return Event(event: Event.setEvent, entityType: Event.userEntityType, entityID: row[0])
        }

        // MARK: - likes data
        
        print("Sending likes data...")

        processRows(likesData.rows, messagePrefix: "Sending likes") { row in
            return Event(event: "like", entityType: Event.userEntityType, entityID: row[0], targetEntity: (Event.itemEntityType, row[1]))
        }
    }
    
    private func convertCategories(_ categories: String) -> [String] {
        return categories.components(separatedBy: CharacterSet(charactersIn: ","))
    }
    
    private func convertImageURLs(_ imageURLs: String) -> [String] {
        return imageURLs.components(separatedBy: CharacterSet(charactersIn: ";"))
    }

    private func processRows(_ rows: [[String]], messagePrefix: String, transformRow: ([String]) -> Event) {
        let batchSize = 50
        let total = rows.count
        var currentOffset = 0
        var nextOffset = 0

        while currentOffset < total {
            nextOffset = min(currentOffset + batchSize, total)

            let events = rows[currentOffset..<nextOffset].map(transformRow)
            eventClient.createBatchEvents(events) { [numProcessed = nextOffset] statuses, error in
                if let error = error {
                    print("Cannot create event due to \(error)")
                }

                if let statuses = statuses {
                    for case let .failed(message) in statuses {
                        print("Cannot create event due to error \(message)")
                    }
                }

                if numProcessed % 500 == 0 || numProcessed == total {
                    print("\(messagePrefix) - Sent \(numProcessed)/\(total) events.")
                }
            }

            currentOffset = nextOffset
        }
    }
}
