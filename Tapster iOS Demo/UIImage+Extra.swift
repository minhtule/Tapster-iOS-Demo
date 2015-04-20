//
//  UIImage+Extra.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/28/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import UIKit

extension UIImage {
    var aspectRatio: CGFloat {
        return size.width / size.height
    }
}
