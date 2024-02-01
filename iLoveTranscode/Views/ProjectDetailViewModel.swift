//
//  ProjectDetailViewModel.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/31.
//

import Foundation
import CocoaMQTT
import SwiftUI
import ActivityKit
import UserNotifications

extension ProjectDetailView {
    
    @MainActor
    class ViewModel: ObservableObject {
        
        var project: Project?
        var mqtt5: CocoaMQTT5?
        var activity: Activity<iLoveTranscodeWidgetAttributes>?
        
        @Published private(set) var jobList: [String : JobBasicInfo] = [:]
        @Published private(set) var projectInfo: ProjectInfoFromMQTT = ProjectInfoFromMQTT(readyJobNumber: 0, failedJobNumber: 0, finishJobNumber: 0, currentJobId: UUID().uuidString, isRendering: false)
        @Published private(set) var str: String = "Hello?"
        @Published var showJobDetailView: Bool = false
        @Published var jobDetails: JobDetails?
        var selectedJobDetailId: String = ""
        
        func connectTo(project: Project) {
            self.project = project
            guard let brokerAddress = project.brokerAddress,
                  !brokerAddress.isEmpty,
                  let topicAddress = project.topicAddress,
                  !topicAddress.isEmpty
            else {
                return
            }
            
            let brokerPort = UInt16(project.brokerPort)
            
            let clientID = "CocoaMQTT-" + UUID().uuidString
            mqtt5 = CocoaMQTT5(clientID: clientID, host: brokerAddress, port: brokerPort)
            
            guard let mqtt5 = mqtt5 else { return }
            
            let connectProperties = MqttConnectProperties()
            connectProperties.topicAliasMaximum = 0
            connectProperties.sessionExpiryInterval = 0
            connectProperties.receiveMaximum = 100
            connectProperties.maximumPacketSize = 500
            mqtt5.username = ""
            mqtt5.password = ""
            mqtt5.connectProperties = connectProperties
            
            mqtt5.keepAlive = 6
            mqtt5.subscribe([MqttSubscription(topic: topicAddress)])
            
            mqtt5.didSubscribeTopics = { mqtt, dict, topics, ack in
                print("did sub \(topics)")
            }
            
            mqtt5.didConnectAck = { mqtt, reason, ack in
                print("============Connected============")
                mqtt5.subscribe([MqttSubscription(topic: topicAddress)])
                
                mqtt5.didSubscribeTopics = { mqtt, dict, topics, ack in
                    print("did sub \(topics)")
                }
            }
            
            mqtt5.didReceiveMessage = { mqtt, message, id, publish in
                let decoder = JSONDecoder()
                if var jobBasicInfo = try? decoder.decode(JobBasicInfo.self, from: Data(message.payload)) {
                    jobBasicInfo.lastUpdate = Date()
                    DispatchQueue.main.async {
                        self.jobList.updateValue(jobBasicInfo, forKey: jobBasicInfo.jobId)
                    }
                } else if let projectInfo = try? decoder.decode(ProjectInfoFromMQTT.self, from: Data(message.payload)) {
                    DispatchQueue.main.async {
                        self.projectInfo = projectInfo
                    }
                    guard let activity = self.activity else { return }
                    let currentJob = self.jobList[projectInfo.currentJobId] ?? JobBasicInfo(jobId: UUID().uuidString, jobName: "No Job in List", timelineName: "Empty", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
                    let projectInfoToWidget = ProjectInfoToWidget(readyJobNumber: projectInfo.readyJobNumber, failedJobNumber: projectInfo.failedJobNumber, finishJobNumber: projectInfo.finishJobNumber, isRendering: projectInfo.isRendering, lastUpdate: Date(), currentJobId: currentJob.jobId, currentJobName: currentJob.jobName, currentTimelineName: currentJob.timelineName, currentJobStatus: currentJob.jobStatus, currentJobProgress: currentJob.jobProgress, currentJobDurationString: currentJob.formatedJobDuration())
                    if activity.content.state.isRendering == true && projectInfoToWidget.isRendering == false {
                        Task {
                            
                            let content = UNMutableNotificationContent()
                            content.title = "\(project.name ?? "Unknown Project") 已结束渲染！"
                            content.subtitle = "点击查看详情"
                            content.sound = .default
                            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                            
                            try? await UNUserNotificationCenter.current().add(request)
                            
                            await activity.end(
                                ActivityContent<iLoveTranscodeWidgetAttributes.ContentState>(
                                    state: projectInfoToWidget,
                                    staleDate: nil
                                )
                            )
                        }
                    } else {
                        var alertConfig: AlertConfiguration? = nil
                        
                        if activity.content.state.currentJobId != projectInfoToWidget.currentJobId {
                            alertConfig = AlertConfiguration(
                                title: "\(project.name ?? "Unknown Project") 已开始渲染下一个任务",
                                body: "当前任务：\(projectInfoToWidget.currentJobName)",
                                sound: .default
                            )
                        }
                        
                        Task {
                            await activity.update(
                                ActivityContent<iLoveTranscodeWidgetAttributes.ContentState>(
                                    state: projectInfoToWidget,
                                    staleDate: nil
                                ),
                                alertConfiguration: alertConfig
                            )
                        }
                    }
                } else if let jobDetails = try? decoder.decode(JobDetails.self, from: Data(message.payload)) {
                    guard jobDetails.jobId == self.selectedJobDetailId else {
                        return
                    }
                    DispatchQueue.main.async {
                        withAnimation {
                            self.jobDetails = jobDetails
                        }
                    }
                }
            }
            _ = mqtt5.connect()
        }
        
        func requestForDetails(of jobId: String) {
            guard let mqtt5 = mqtt5 else { return }
            jobDetails = nil
            let publishProperties = MqttPublishProperties()
            publishProperties.contentType = "String"
            mqtt5.publish("\(project?.topicAddress ?? "unknown")/inverse", withString: "req@\(jobId)", properties: publishProperties)
        }
        
        func start() {
            if let activity = activity {
                let currentJob = self.jobList[projectInfo.currentJobId] ?? JobBasicInfo(jobId: UUID().uuidString, jobName: "No Job in List", timelineName: "Empty", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
                let attributes = iLoveTranscodeWidgetAttributes.ContentState(readyJobNumber: projectInfo.readyJobNumber, failedJobNumber: projectInfo.failedJobNumber, finishJobNumber: projectInfo.finishJobNumber, isRendering: projectInfo.isRendering, lastUpdate: Date(), currentJobId: currentJob.jobId, currentJobName: currentJob.jobName, currentTimelineName: currentJob.timelineName, currentJobStatus: currentJob.jobStatus, currentJobProgress: currentJob.jobProgress, currentJobDurationString: currentJob.formatedJobDuration())
                Task {
                    await activity.end(
                        ActivityContent<iLoveTranscodeWidgetAttributes.ContentState>(
                            state: attributes,
                            staleDate: nil
                        ),
                        dismissalPolicy: .immediate
                    )
                }
            }
            if ActivityAuthorizationInfo().areActivitiesEnabled {
                do {
                    let projectAttr = iLoveTranscodeWidgetAttributes(projectName: project?.name ?? "Unknown Project")
                    let currentJob = jobList[projectInfo.currentJobId] ?? JobBasicInfo(jobId: UUID().uuidString, jobName: "No Job in List", timelineName: "Empty", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
                    let initialState = ProjectInfoToWidget(readyJobNumber: self.projectInfo.readyJobNumber, failedJobNumber: self.projectInfo.failedJobNumber, finishJobNumber: self.projectInfo.finishJobNumber, isRendering: self.projectInfo.isRendering, lastUpdate: Date(), currentJobId: self.projectInfo.currentJobId, currentJobName: currentJob.jobName, currentTimelineName: currentJob.timelineName, currentJobStatus: currentJob.jobStatus, currentJobProgress: currentJob.jobProgress, currentJobDurationString: currentJob.formatedJobDuration())
                    
                    let activity = try Activity.request(
                        attributes: projectAttr,
                        content: .init(state: initialState, staleDate: nil),
                        pushType: .token
                    )
                    
                    self.activity = activity
                    
                } catch {
                    fatalError()
                }
            }
        }
        
        func disconnect() {
            if let mqtt5 = mqtt5 {
                mqtt5.disconnect()
            }
            if let activity = activity {
                let currentJob = self.jobList[projectInfo.currentJobId] ?? JobBasicInfo(jobId: UUID().uuidString, jobName: "No Job in List", timelineName: "Empty", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
                let attributes = iLoveTranscodeWidgetAttributes.ContentState(readyJobNumber: projectInfo.readyJobNumber, failedJobNumber: projectInfo.failedJobNumber, finishJobNumber: projectInfo.finishJobNumber, isRendering: projectInfo.isRendering, lastUpdate: Date(), currentJobId: currentJob.jobId, currentJobName: currentJob.jobName, currentTimelineName: currentJob.timelineName, currentJobStatus: currentJob.jobStatus, currentJobProgress: currentJob.jobProgress, currentJobDurationString: currentJob.formatedJobDuration())
                Task {
                    await activity.end(
                        ActivityContent<iLoveTranscodeWidgetAttributes.ContentState>(
                            state: attributes,
                            staleDate: nil
                        ),
                        dismissalPolicy: .immediate
                    )
                }
            }
        }
        
        func addPreview() {
            let jobId = UUID().uuidString
            jobList.updateValue(JobBasicInfo(jobId: jobId, jobName: "Job 1", timelineName: "Timeline 1", jobStatus: .finish, jobProgress: 80, estimatedTime: 0, timeTaken: 4389, order: 0), forKey: jobId)
        }
        
    }
    
}
