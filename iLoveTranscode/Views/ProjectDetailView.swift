//
//  ProjectDetailView.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/31.
//

import ActivityKit
import SwiftUI
import CodeScanner

struct ProjectDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ViewModel()
    
    var project: Project
    
    var body: some View {
        ZStack {
            List(viewModel.jobList.values.sorted(by: { $0.order < $1.order }), id: \.jobId) { job in
                Section {
                    VStack {
                        HStack {
                            Image(systemName: "briefcase")
                            Text(job.jobName)
                            Spacer()
                            Image(systemName: "filemenu.and.selection")
                                .foregroundStyle(.secondary)
                            Text(job.timelineName)
                                .foregroundStyle(.secondary)
                        }
                        Divider()
                        Text("\(job.jobStatus == .rendering ? "剩余时间" : "任务耗时")：\(job.formatedJobDuration(rendering: job.jobStatus == .rendering))")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 3)
                            .font(.system(size: 15, weight: .light))
                        HStack(spacing: 10) {
                            Text(job.jobStatus.string)
                                .foregroundStyle(job.jobStatus.color)
                            RenderJobProgressView(progress: CGFloat(job.jobProgress) / 100, height: 12, color: job.jobStatus.color)
                                .animation(.easeInOut, value: job.jobProgress)
                            Text("\(job.jobProgress)%")
                                .foregroundStyle(job.jobStatus.color)
                                .frame(minWidth: 50, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 5)
                } header: {
                    HStack {
                        Text(job.jobId)
                        Spacer()
                        Button(action: {
                            viewModel.selectedJobDetailId = job.jobId
                            viewModel.showJobDetailView.toggle()
                        }, label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 15))
                        })
                    }
                }
            }
            .task {
                viewModel.connectTo(project: project)
            }
            .toolbar(content: {
                ToolbarItem(id: "Back", placement: .topBarLeading) {
                    Button(action: {
                        viewModel.disconnect()
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("断开")
                        Image(systemName: "circle.slash")
                    })
                    .tint(.red)
                    .buttonStyle(BorderedButtonStyle())
                }
                ToolbarItem(id: "Subscribe", placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.start()
                    }, label: {
                        Image(systemName: "bell.badge")
                            .bold()
                        Text("订阅通知")
                            .bold()
                    })
                    .buttonStyle(BorderedProminentButtonStyle())
                    .disabled(viewModel.activity?.activityState == ActivityState.active || !viewModel.didReceiveMessageFromMQTT)
                }
            })
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $viewModel.showJobDetailView, content: {
                JobDetailsView(jobId: viewModel.selectedJobDetailId)
                    .environmentObject(viewModel)
            })
            
            if !viewModel.didReceiveMessageFromMQTT {
                VStack(spacing: 10) {
                    ProgressView()
                    Text(viewModel.didConnectToMQTT ? "正在等待服务器消息..." : "正在连接服务器...")
                }
                .padding()
                .background(.bar)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if viewModel.unknownMessageCount > 3 {
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("收到的消息不能解析\n如已更新发射端密钥，请扫描二维码以更新项目")
                            .lineSpacing(5)
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                        Button(action: {
                            viewModel.showScannerView = true
                        }, label: {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 15))
                            Text("扫描二维码")
                                .font(.system(size: 15))
                        })
                        .sheet(isPresented: $viewModel.showScannerView, content: {
                            CodeScannerView(codeTypes: [.qr], completion: { result in
                                Task {
                                    await viewModel.handleQRScan(result: result)
                                }
                            })
                            .ignoresSafeArea()
                        })
                    }
                    .padding()
                    .background(.bar)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

#Preview {
    ProjectDetailView(project: Project(context: PersistenceController.preview.container.viewContext))
}
