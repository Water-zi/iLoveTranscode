//
//  CustomExtensions.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/2/1.
//

import Foundation

extension Date {
    var formattedComplete: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd - hh:mm:ss"
        return formatter.string(from: self)
    }
}
