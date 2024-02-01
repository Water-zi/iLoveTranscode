//
//  ContentViewModel.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/31.
//

import Foundation
import CodeScanner

struct ProjectQRCodeInfo: Codable {
    var projectName: String
    var brokerAddress: String
    var brokerPort: Int64
    var topicAddress: String
}

extension ContentView {
    
    @MainActor
    class ViewModel: ObservableObject {
        
        let viewContent = PersistenceController.shared.container.viewContext
        
        @Published var showScannerView: Bool = false
        @Published var showProjectDetailView: Bool = false
        
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
                    let project = Project(context: viewContent)
                    project.name = info.projectName
                    project.brokerAddress = info.brokerAddress
                    project.brokerPort = info.brokerPort
                    project.topicAddress = info.topicAddress
                    project.addedDate = Date()
                    project.order = Int64(projectCount)
                    viewContent.saveContext()
                    showScannerView = false
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
