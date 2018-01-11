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
    let userIDColumn = 0
    let episodeIDColumn = 1
    let eventClient = EventClient(accessKey: "")
    let numberOfConcurrentRequests = 4 // Same as Apple's HTTPMaximumConnectionsPerHost default value for iOS
    var globalLikeIndex = 0
    var finishingCounter = 0
    
    @IBAction func importDataButtonAction(_ sender: UIButton) {
        self.readCSVDataAndImport()
    }
    
    private func readCSVDataAndImport() {
        
        // MARK: - episodes data
        let episodeData = CSVData(fileName: "episode_list")
        
        print("Found \(episodeData.rows.count) unique episode")
        print("Sending episodes data...")
        
        for row in episodeData.rows {
            let properties: [String: Any] = [
                "title": row[1],
                "categories": convertCategories(row[2]),
                "imageURLs": convertImageURLs(row[4]),
            ]
            eventClient.setItem(itemID: row[0], properties: properties) { data, error in
                // Only report if an error occurs
                if let error = error {
                    print("Resonse \(String(describing: data))")
                    print("Sending episode: \(row[0]) has error \(error)")
                }
            }
        }
        
        print("Done with episodes!")
        
        // MARK: - users data
        
        let likesData = CSVData(fileName: "user_list")
        let userIDs = likesData.uniqueEntries(column: userIDColumn)
        
        print("Found \(userIDs.count) unique user IDs")
        print("Sending users data...")
        
        for userID in userIDs {
            eventClient.setUser(userID: userID, properties: [:]) { data, error in
                // Only report if an error occurs
                if let error = error {
                    print("Resonse \(String(describing: data))")
                    print("Sending user: \(userID) has error \(error)")
                }
            }
        }
        
        print("Done with users!")
        
        // MARK: - likes data
        
        print("Sending likes data...")
        
        let startTime = Date()
        print("Start time = \(startTime)")

        globalLikeIndex = numberOfConcurrentRequests
        for i in 0..<numberOfConcurrentRequests {
            sendLikeData(likesData, rowIndex: i)
        }
        
    }
    
    private func convertCategories(_ categories: String) -> [String] {
        return categories.components(separatedBy: CharacterSet(charactersIn: ","))
    }
    
    private func convertImageURLs(_ imageURLs: String) -> [String] {
        return imageURLs.components(separatedBy: CharacterSet(charactersIn: ";"))
    }
    
    private func sendLikeData(_ likesData: CSVData, rowIndex: Int) {
        let row = likesData.rows[rowIndex]
        eventClient.recordAction("like", byUserID: row[0], onItemID: row[1]) { _, error in
            if let error = error {
                print("Sending like for user \(row[0]) and item \(row[1]) has error \(error)")
            }

            if self.globalLikeIndex < likesData.rows.count {
                self.sendLikeData(likesData, rowIndex: self.globalLikeIndex)
                self.globalLikeIndex += 1
            } else if self.globalLikeIndex == likesData.rows.count {
                self.finishingCounter += 1
                if self.finishingCounter == self.numberOfConcurrentRequests {
                    let endTime = Date()
                    print("End time = \(endTime)")
                }
            }
        }
    }
}
