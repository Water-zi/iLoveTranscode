//
//  ProjectInfoModel.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/2/1.
//

import Foundation

struct ProjectInfoFromMQTT: Codable {
    var id: UUID = UUID()
    
    var readyJobNumber: Int
    var failedJobNumber: Int
    var finishJobNumber: Int
    var currentJobId: String
    var isRendering: Bool
    
    enum CodingKeys: String, CodingKey {
        case readyJobNumber = "rjn"
        case failedJobNumber = "fjn"
        case finishJobNumber = "fnjn"
        case currentJobId = "cj"
        case isRendering = "ir"
    }
}

struct ProjectInfoToWidget: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    
    var readyJobNumber: Int
    var failedJobNumber: Int
    var finishJobNumber: Int
    var isRendering: Bool
    
    var lastUpdate: Date?
    
    var currentJobId: String
    var currentJobName: String
    var currentTimelineName: String
    var currentJobStatus: JobStatus = .ready
    var currentJobProgress: Int
    var currentJobDurationString: String
}
