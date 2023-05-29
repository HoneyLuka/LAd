//
//  AdHelper.swift
//  SleepSentry
//
//  Created by Selina on 16/5/2023.
//

import Foundation
import GoogleMobileAds

public extension GADMediaContent {
    var reallyHasContent: Bool {
        return hasVideoContent || mainImage != nil
    }
    
    var realRatio: CGFloat {
        if hasVideoContent {
            let ratio = aspectRatio == 0 ? (16.0 / 9.0) : aspectRatio
            return ratio
        }
        
        if let image = mainImage {
            var ratio: CGFloat = 0
            if image.size.height == 0 {
                ratio = 16.0 / 9.0
            } else {
                ratio = image.size.width / image.size.height
            }
            
            if ratio == 0 {
                ratio = 16.0 / 9.0
            }
            
            return ratio
        }
        
        return 16.0 / 9.0
    }
    
    func height(forWidth width: CGFloat) -> CGFloat {
        let ratio = realRatio
        let mediaHeight = width / ratio
        return mediaHeight
    }
}
