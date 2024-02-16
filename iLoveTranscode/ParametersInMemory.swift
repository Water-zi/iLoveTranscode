//
//  ParametersInMemory.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/2/14.
//

import Foundation

class ParametersInMemory {
    static let shared: ParametersInMemory = ParametersInMemory()
    private init() {}
    
    var pushNotificationToken: String?
}
