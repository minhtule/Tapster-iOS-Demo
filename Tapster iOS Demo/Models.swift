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
}
