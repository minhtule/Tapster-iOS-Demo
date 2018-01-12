//
//  CGPoint+Extra.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/30/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import UIKit

extension CGPoint {
    func translate(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }
}
