//
//  Models.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/24/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import Foundation

struct RecommendationResponse: Decodable {
    let comics: [Comic]

    enum CodingKeys: String, CodingKey {
        case comics = "itemScores"
    }
//    init() {
//    }
//
//    mutating func mapping(map: Map) {
//        comics <= map["itemScores"]
//    }
}

struct Comic: Decodable {
    let id: String
    let title: String
    let imageURLs: [String]
    let score: Double

    enum CodingKeys: String, CodingKey {
        case id = "itemID"
        case title
        case imageURLs
        case score
    }

//    init() {
//    }
//
//    init(ID: String, title: String, imageURLs: [String], score: Double) {
//        self.ID = ID
//        self.title = title
//        self.imageURLs = imageURLs
//        self.score = score
//    }
//
//    mutating func mapping(map: Map) {
//        ID <= map["itemID"]
//        title <= map["title"]
//        imageURLs <= map["imageURLs"]
//        score <= map["score"]
//    }
}
