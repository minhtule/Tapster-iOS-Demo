//
//  Models.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/24/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import Foundation
import ObjectMapper

struct Result: Mappable {
    var comics: [Comic]!
    
    init() {
    }
    
    mutating func mapping(map: Map) {
        comics <= map["itemScores"]
    }
}

struct Comic: Mappable {
    var ID: String!
    var title: String!
    var imageURLs: [String]!
    var score: Double!
    
    init() {
    }
    
    init(ID: String, title: String, imageURLs: [String], score: Double) {
        self.ID = ID
        self.title = title
        self.imageURLs = imageURLs
        self.score = score
    }
    
    mutating func mapping(map: Map) {
        ID <= map["itemID"]
        title <= map["title"]
        imageURLs <= map["imageURLs"]
        score <= map["score"]
    }
}
