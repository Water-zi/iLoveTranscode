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
import CodeScanner
import NotificationBannerSwift

extension ProjectDetailView {
    
    @MainActor
    class ViewModel: ObservableObject {
        
        let viewContent = PersistenceController.shared.container.viewContext
        
        var project: Project?
        var mqtt5: CocoaMQTT5?
        var activity: Activity<iLoveTranscodeWidgetAttributes>?
        //        @Published var canSubscribe: Bool = false
        
        @Published private(set) var jobList: [String : JobBasicInfo] = [:]
        @Published private(set) var projectInfo: ProjectInfoFromMQTT = ProjectInfoFromMQTT(readyJobNumber: 0, failedJobNumber: 0, finishJobNumber: 0, currentJobId: UUID().uuidString, isRendering: false)
        @Published private(set) var str: String = "Hello?"
        @Published var showJobDetailView: Bool = false
        @Published var jobDetails: JobDetails?
        var selectedJobDetailId: String = ""
        
        @Published var didConnectToMQTT: Bool = false
        @Published var didReceiveMessageFromMQTT: Bool = false
        @Published var unknownMessageCount: Int = 0
        
        @Published var showScannerView: Bool = false
        
        func connectTo(project: Project) {
            self.project = project
            
            if let privateKey = project.privateKey {
                TransmitEncryption.privateKey = privateKey
            }
            
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
            
            mqtt5.keepAlive = 60
            
            mqtt5.autoReconnect = true
            mqtt5.backgroundOnSocket = true
            
            mqtt5.didSubscribeTopics = { mqtt, dict, topics, ack in
                print("did sub \(dict.allKeys)")
                self.didConnectToMQTT = true
                self.sendDeviceToken()
                let publishProperties = MqttPublishProperties()
                publishProperties.contentType = "String"
                #if DEBUG
                mqtt5.publish("\(project.topicAddress ?? "unknown")/inverse", withString: "env@debug".encrypt(), properties: publishProperties)
                #else
                mqtt5.publish("\(project.topicAddress ?? "unknown")/inverse", withString: "env@release".encrypt(), properties: publishProperties)
                #endif
            }
            
            mqtt5.didConnectAck = { mqtt, reason, ack in
                print("============Connected============")
                mqtt5.subscribe([MqttSubscription(topic: topicAddress)])
            }
            
            mqtt5.didDisconnect = { mqtt, error in
                self.didConnectToMQTT = false
                self.didReceiveMessageFromMQTT = false
            }
            
            mqtt5.didReceiveMessage = { mqtt, message, id, publish in
                if !self.didReceiveMessageFromMQTT {
                    self.didReceiveMessageFromMQTT = true
                }
                let decoder = JSONDecoder()
                guard let decryptedData = String(data: Data(message.payload), encoding: .utf8)?.decrypt().data(using: .utf8) else { return }
                if var jobBasicInfo = try? decoder.decode(JobBasicInfo.self, from: decryptedData) {
                    self.unknownMessageCount = 0
                    jobBasicInfo.lastUpdate = Date()
                    self.jobList.updateValue(jobBasicInfo, forKey: jobBasicInfo.jobId)
                    //                    DispatchQueue.main.async {
                    //                        self.jobList.updateValue(jobBasicInfo, forKey: jobBasicInfo.jobId)
                    //                    }
                } else if let projectInfo = try? decoder.decode(ProjectInfoFromMQTT.self, from: decryptedData) {
                    // App should not receive this type of message
                    self.unknownMessageCount = 0
                    print("Receive ProjectInfo, will not do anything.")
                    /*
                     //                    DispatchQueue.main.async {
                     //                        self.projectInfo = projectInfo
                     //                    }
                     //                    guard let activity = self.activity else { return }
                     //                    let currentJob = self.jobList[projectInfo.currentJobId] ?? JobBasicInfo(jobId: UUID().uuidString, jobName: "No Job in List", timelineName: "Empty", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
                     //                    let projectInfoToWidget = ProjectInfoToWidget(readyJobNumber: projectInfo.readyJobNumber, failedJobNumber: projectInfo.failedJobNumber, finishJobNumber: projectInfo.finishJobNumber, isRendering: projectInfo.isRendering, lastUpdate: Date(), currentJobId: currentJob.jobId, currentJobName: currentJob.jobName, currentTimelineName: currentJob.timelineName, currentJobStatus: currentJob.jobStatus, currentJobProgress: currentJob.jobProgress, currentJobDurationString: currentJob.formatedJobDuration(rendering: projectInfo.isRendering))
                     //                    if activity.content.state.isRendering == true && projectInfoToWidget.isRendering == false {
                     //                        Task {
                     //                            let content = UNMutableNotificationContent()
                     //                            content.title = "\(project.name ?? "Unknown Project") 已结束渲染！"
                     //                            content.subtitle = "点击查看详情"
                     //                            content.sound = .default
                     //                            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                     //
                     //                            try? await UNUserNotificationCenter.current().add(request)
                     //
                     //                            await activity.end(
                     //                                ActivityContent<iLoveTranscodeWidgetAttributes.ContentState>(
                     //                                    state: projectInfoToWidget,
                     //                                    staleDate: nil
                     //                                )
                     //                            )
                     //                        }
                     //                    } else {
                     //                        var alertConfig: AlertConfiguration? = nil
                     //
                     //                        if activity.content.state.currentJobId != projectInfoToWidget.currentJobId {
                     //                            alertConfig = AlertConfiguration(
                     //                                title: "\(project.name ?? "Unknown Project") 已开始渲染下一个任务",
                     //                                body: "当前任务：\(projectInfoToWidget.currentJobName)",
                     //                                sound: .default
                     //                            )
                     //                        }
                     //
                     //                        Task {
                     //                            await activity.update(
                     //                                ActivityContent<iLoveTranscodeWidgetAttributes.ContentState>(
                     //                                    state: projectInfoToWidget,
                     //                                    staleDate: nil
                     //                                ),
                     //                                alertConfiguration: alertConfig
                     //                            )
                     //                        }
                     //                    }
                     */
                } else if let removeJob = try? decoder.decode(RemoveJobInfo.self, from: decryptedData) {
                    self.jobList.removeValue(forKey: removeJob.removedJobId)
                } else if let jobDetails = try? decoder.decode(JobDetails.self, from: decryptedData) {
                    self.unknownMessageCount = 0
                    guard jobDetails.jobId == self.selectedJobDetailId.suffix(4) else {
                        return
                    }
                    self.jobDetails = jobDetails
                } else {
                    self.unknownMessageCount += 1
                }
            }
            
            _ = mqtt5.connect()
        }
        
        func sendDeviceToken() {
            //Send device token
            print(ParametersInMemory.shared.pushNotificationToken ?? "No Token")
            guard let mqtt5 = self.mqtt5,
                  let token = ParametersInMemory.shared.pushNotificationToken
            else { return }
            let publishProperties = MqttPublishProperties()
            publishProperties.contentType = "String"
            mqtt5.publish("\(self.project?.topicAddress ?? "unknown")/inverse", withString: "dtk@\(token)".encrypt(), properties: publishProperties)
        }
        
        func removeAllJobInList() {
            jobList.removeAll()
        }
        
        func requestForDetails(of jobId: String) {
            guard let mqtt5 = mqtt5 else { return }
            jobDetails = nil
            let publishProperties = MqttPublishProperties()
            publishProperties.contentType = "String"
            mqtt5.publish("\(project?.topicAddress ?? "unknown")/inverse", withString: "req@\(jobId)".encrypt(), properties: publishProperties)
        }
        
        func requestStartRender(for jobId: String) {
            guard let mqtt5 = mqtt5 else { return }
            let startRenderJob = StartJob(jobId: jobId, date: Date())
            guard let data = try? JSONEncoder().encode(startRenderJob),
                  let dataStr = String(data: data, encoding: .utf8)
            else { return }
            
            let publishProperties = MqttPublishProperties()
            publishProperties.contentType = "String"
            mqtt5.publish("\(project?.topicAddress ?? "unknown")/inverse", withString: dataStr.encrypt(), properties: publishProperties)
        }
        
        func start() {
            if let activity = activity {
                let currentJob = self.jobList[projectInfo.currentJobId] ?? JobBasicInfo(jobId: UUID().uuidString, jobName: "No Job in List", timelineName: "Empty", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
                let attributes = iLoveTranscodeWidgetAttributes.ContentState(readyJobNumber: projectInfo.readyJobNumber, failedJobNumber: projectInfo.failedJobNumber, finishJobNumber: projectInfo.finishJobNumber, isRendering: projectInfo.isRendering, lastUpdate: Date(), currentJobId: currentJob.jobId, currentJobName: currentJob.jobName, currentTimelineName: currentJob.timelineName, currentJobStatus: currentJob.jobStatus, currentJobProgress: currentJob.jobProgress, currentJobDurationString: currentJob.formatedJobDuration(rendering: false))
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
                    let currentJob = jobList[projectInfo.currentJobId] ?? JobBasicInfo(jobId: UUID().uuidString, jobName: "正在加载...", timelineName: "请稍候", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
                    let initialState = ProjectInfoToWidget(readyJobNumber: self.projectInfo.readyJobNumber, failedJobNumber: self.projectInfo.failedJobNumber, finishJobNumber: self.projectInfo.finishJobNumber, isRendering: self.projectInfo.isRendering, lastUpdate: Date(), currentJobId: self.projectInfo.currentJobId, currentJobName: currentJob.jobName, currentTimelineName: currentJob.timelineName, currentJobStatus: currentJob.jobStatus, currentJobProgress: currentJob.jobProgress, currentJobDurationString: currentJob.formatedJobDuration(rendering: false))
                    
                    let activity = try Activity.request(
                        attributes: projectAttr,
                        content: .init(state: initialState, staleDate: nil),
                        pushType: .token
                    )
                    
                    self.activity = activity
                    
                    Task {
                        for await data in activity.pushTokenUpdates {
                            let myToken = data.map {String(format: "%02x", $0)}.joined()
                            //Send live activity token
                            print(ParametersInMemory.shared.pushNotificationToken ?? "No Token")
                            guard let mqtt5 = self.mqtt5,
                                  myToken.count > 0
                            else { return }
                            let publishProperties = MqttPublishProperties()
                            publishProperties.contentType = "String"
                            mqtt5.publish("\(self.project?.topicAddress ?? "unknown")/inverse", withString: "atk@\(myToken)".encrypt(), properties: publishProperties)
                        }
                    }
                    
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        func disconnect() {
            if let mqtt5 = mqtt5 {
                mqtt5.disconnect()
            }
            if let activity = activity {
                let currentJob = self.jobList[projectInfo.currentJobId] ?? JobBasicInfo(jobId: UUID().uuidString, jobName: "No Job in List", timelineName: "Empty", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
                let attributes = iLoveTranscodeWidgetAttributes.ContentState(readyJobNumber: projectInfo.readyJobNumber, failedJobNumber: projectInfo.failedJobNumber, finishJobNumber: projectInfo.finishJobNumber, isRendering: projectInfo.isRendering, lastUpdate: Date(), currentJobId: currentJob.jobId, currentJobName: currentJob.jobName, currentTimelineName: currentJob.timelineName, currentJobStatus: currentJob.jobStatus, currentJobProgress: currentJob.jobProgress, currentJobDurationString: currentJob.formatedJobDuration(rendering: false))
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
        
        func handleQRScan(result: Result<ScanResult, ScanError>) async {
            switch result {
            case .success(let result):
                let decoder = JSONDecoder()
                guard let info = try? decoder.decode(ProjectQRCodeInfo.self, from: result.string.data(using: .utf8) ?? Data())
                else {
                    return
                }
                await MainActor.run {
                    guard let project = project else { return }
                    guard info.topicAddress == project.topicAddress else {
                        NotificationBannerQueue.default.dismissAllForced()
                        let banner = FloatingNotificationBanner(title: "请仅扫描 \(project.name ?? "Unknown Project") 的二维码", subtitle: "其他项目二维码请前往APP主页扫描", style: .warning)
                        banner.show(queuePosition: .front, queue: .default, cornerRadius: 15)
                        return
                    }
                    
                    project.name = info.projectName
                    project.brokerAddress = info.brokerAddress
                    project.brokerPort = info.brokerPort
                    project.topicAddress = info.topicAddress
                    project.privateKey = info.privateKey
                    project.addedDate = Date()
                    viewContent.saveContext()
                    showScannerView = false
                    
                    TransmitEncryption.privateKey = info.privateKey
                    
                    NotificationBannerQueue.default.dismissAllForced()
                    let banner = FloatingNotificationBanner(title: "扫描成功", subtitle: "\(info.projectName) 项目信息已更新", style: .success)
                    banner.show(queuePosition: .front, queue: .default, cornerRadius: 15)
                }
            case .failure(let error):
                print("Scanning failed: \(error.localizedDescription)")
            }
            // more code to come
        }
        
    }
    
}
