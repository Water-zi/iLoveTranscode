//
//  ContentView.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/30.
//

import SwiftUI
import CoreData
import CodeScanner

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    
    //    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.order, ascending: true)],
        animation: .easeInOut
    )
    private var projects: FetchedResults<Project>
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(projects) { project in
                        Section(project.addedDate?.formattedComplete ?? "No Date Info") {
                            NavigationLink {
                                ProjectDetailView(project: project)
                                    .navigationTitle(project.name ?? "Unknown Project")
                            } label: {
                                
                                VStack {
                                    Text(project.name ?? "Unknown Project")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .bold()
                                    Divider()
                                        .padding(.trailing)
                                        .padding(.bottom, 3)
                                    
                                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5) {
                                        GridRow {
                                            Text("服务器")
                                            Text(project.brokerAddress ?? "Undefined Host")
                                        }
                                        GridRow {
                                            Text("端口")
                                            Text(String(project.brokerPort))
                                        }
                                    }
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.removeProject(project: project)
                            } label: {
                                Text("删除")
                            }
                        }
                        .onTapGesture {
                            viewModel.showProjectDetailView.toggle()
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.showScannerView.toggle()
                        }, label: {
                            Image(systemName: "qrcode.viewfinder")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .padding()
                        })
                        .buttonStyle(BorderedProminentButtonStyle())
                        .clipShape(Circle())
                        .padding(25)
                        .sheet(isPresented: $viewModel.showScannerView, content: {
                            CodeScannerView(codeTypes: [.qr], completion: { result in
                                Task {
                                    await viewModel.handleQRScan(result: result)
                                }
                            })
                            .ignoresSafeArea()
                        })
                    }
                }
            }
            .navigationTitle("任务列表")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
