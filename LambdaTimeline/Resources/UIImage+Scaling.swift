//
//  UIImage+Scaling.swift
//  LambdaTimeline
//
//  Created by Nelson Gonzalez on 3/18/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit

extension UIImage {
    func imageByScaling(toSize size: CGSize) -> UIImage? {
        guard let data = pngData(),
            let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
                return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height) / 2.0,
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]
        
        return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary).flatMap { UIImage(cgImage: $0) }
    }
}

