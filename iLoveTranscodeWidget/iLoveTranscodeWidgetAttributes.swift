//
//  iLoveTranscodeWidgetAttributes.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/31.
//

import ActivityKit
import Foundation

struct iLoveTranscodeWidgetAttributes: ActivityAttributes {
    
    typealias ContentState = ProjectInfoToWidget

    // Fixed non-changing properties about your activity go here!
    public var projectName: String
    
    init(projectName: String) {
        self.projectName = projectName
    }
}
