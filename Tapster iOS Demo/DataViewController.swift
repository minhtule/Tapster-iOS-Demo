//
//  DataViewController.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/23/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import UIKit
import PredictionIOSDK

class DataViewController: UIViewController {
    let userIDColumn = 0
    let episodeIDColumn = 1
    let eventClient = EventClient(accessKey: "")
    let numberOfConcurrentRequests = 4 // Same as Apple's HTTPMaximumConnectionsPerHost default value for iOS
    var globalLikeIndex = 0
    var finishingCounter = 0
    
    @IBAction func importDataButtonAction(sender: UIButton) {
        self.readCSVDataAndImport()
    }
    
    private func readCSVDataAndImport() {
        
        // MARK: - episodes data
        let episodeData = CSVData(fileName: "episode_list")
        
        println("Found \(episodeData.rows.count) unique episode")
        println("Sending episodes data...")
        
        for row in episodeData.rows {
            eventClient.setItem(row[0],
                properties: [
                    "title": row[1],
                    "categories": convertCategories(row[2]),
                    "imageURLs": convertImageURLs(row[4]),
                ],
                completionHandler: { (_, _, data, error) -> Void in

                    // Only report if an error occurs
                    if error != nil {
                        println(data)
                        println("Sending episode: \(row[0]) has error \(error)")
                    }
                }
            )
        }
        
        println("Done with episodes!")
        
        // MARK: - users data
        
        let readStartTime = NSDate()
        let likesData = CSVData(fileName: "user_list")
        let userIDs = likesData.uniqueEntries(userIDColumn)
        
        println("Found \(userIDs.count) unique user IDs")
        println("Sending users data...")
        
        for userID in userIDs {
            eventClient.setUser(userID,
                properties: [:],
                completionHandler: { (_, _, data, error) -> Void in
                    // Only report if an error occurs
                    if error != nil {
                        println(data)
                        println("Sending user: \(userID) has error \(error)")
                    }
                }
            )
        }
        
        println("Done with users!")
        
        // MARK: - likes data
        
        println("Sending likes data...")
        
        let startTime = NSDate()
        println("Start time = \(startTime)")

        globalLikeIndex = numberOfConcurrentRequests
        for i in 0..<numberOfConcurrentRequests {
            sendLikeData(likesData, rowIndex: i)
        }
        
    }
    
    private func convertCategories(categories: String) -> [String] {
        return categories.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: ","))
    }
    
    private func convertImageURLs(imageURLs: String) -> [String] {
        return imageURLs.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: ";"))
    }
    
    private func sendLikeData(likesData: CSVData, rowIndex: Int) {
        let row = likesData.rows[rowIndex]
        eventClient.recordAction("like",
            byUserID: row[0],
            itemID: row[1],
            properties: [:],
            completionHandler: { (_, _, _, error) in
                if error != nil {
                    println("Sending like for user \(row[0]) and item \(row[1]) has error \(error)")
                }
                
                if self.globalLikeIndex < likesData.rows.count {
                    self.sendLikeData(likesData, rowIndex: self.globalLikeIndex)
                    ++self.globalLikeIndex
                } else if self.globalLikeIndex == likesData.rows.count {
                    ++self.finishingCounter
                    if self.finishingCounter == self.numberOfConcurrentRequests {
                        let endTime = NSDate()
                        println("End time = \(endTime)")
                    }
                }
            }
        )
    }
}
