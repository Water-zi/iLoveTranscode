//
//  ContentViewModel.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/31.
//

import Foundation
import CodeScanner
import CoreData
import NotificationBannerSwift

struct ProjectQRCodeInfo: Codable {
    var projectName: String
    var brokerAddress: String
    var brokerPort: Int64
    var topicAddress: String
    var privateKey: String
}

extension ContentView {
    
    @MainActor
    class ViewModel: ObservableObject {
        
        let viewContent = PersistenceController.shared.container.viewContext
        
        @Published var showScannerView: Bool = false
        
        func handleQRScan(result: Result<ScanResult, ScanError>) async {
            switch result {
            case .success(let result):
                let decoder = JSONDecoder()
                guard let info = try? decoder.decode(ProjectQRCodeInfo.self, from: result.string.data(using: .utf8) ?? Data())
                else {
                    return
                }
                await MainActor.run {
                    let projectCount = (try? viewContent.fetch(Project.fetchRequest()).count) ?? 0
                    let fetchRequest = NSFetchRequest<Project>(entityName: "Project")
                    fetchRequest.predicate = NSPredicate(format: "topicAddress == %@", info.topicAddress)
                    fetchRequest.fetchLimit = 1
                    var project = try? viewContent.fetch(fetchRequest).first
                    var newProject: Bool = false
                    if project == nil {
                        project = Project(context: viewContent)
                        newProject = true
                        project?.order = Int64(projectCount)
                    }
                    project?.name = info.projectName
                    project?.brokerAddress = info.brokerAddress
                    project?.brokerPort = info.brokerPort
                    project?.topicAddress = info.topicAddress
                    project?.privateKey = info.privateKey
                    project?.addedDate = Date()
                    viewContent.saveContext()
                    showScannerView = false
                    
                    let banner = FloatingNotificationBanner(title: "扫描成功", subtitle: newProject ? "已添加项目 \(info.projectName)" : "\(info.projectName) 项目信息已更新", style: .success)
                    banner.show(queuePosition: .front, queue: .default, cornerRadius: 15)
                }
            case .failure(let error):
                print("Scanning failed: \(error.localizedDescription)")
            }
           // more code to come
        }
        
        func removeProject(project: Project) {
            viewContent.delete(project)
            viewContent.saveContext()
        }
        
    }
    
}
