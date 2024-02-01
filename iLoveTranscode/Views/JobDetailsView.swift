//
//  JobDetailsView.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/2/1.
//

import SwiftUI

struct JobDetailsView: View {
    
    var jobId: String
    @EnvironmentObject var viewModel: ProjectDetailView.ViewModel
    @State var showRetryButton: Bool = false
    @State var enableRetryButton: Bool = false
    @State var currentJob: JobBasicInfo = JobBasicInfo(jobId: "Missing...", jobName: "Missing...", timelineName: "Missing...", jobStatus: .unknown, jobProgress: 0, estimatedTime: 0, timeTaken: 0, order: 0)
    let timer = Timer.publish(every: 3, on: .main, in: .common)
    
    var body: some View {
        NavigationStack {
            if let jobDetails = viewModel.jobDetails {
                List {
                    Section("项目概览") {
                        HStack {
                            Text("任务ID")
                            Spacer(minLength: 10)
                            Text(jobDetails.jobId)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.2)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("时间线")
                            Spacer(minLength: 10)
                            Text(currentJob.timelineName)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.2)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("渲染模式")
                            Spacer(minLength: 10)
                            Text(jobDetails.renderMode)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.2)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("渲染预设")
                            Spacer(minLength: 10)
                            Text(jobDetails.presetName)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.2)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("目标路径")
                            Spacer(minLength: 10)
                            Text(jobDetails.targetDir)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.2)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("输出文件")
                            Spacer(minLength: 10)
                            Text(jobDetails.outputFileName)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.2)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("帧速率")
                            Spacer(minLength: 10)
                            Text(jobDetails.frameRate)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.2)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    if jobDetails.isExportVideo {
                        Section("视频输出") {
                            HStack {
                                Text("视频格式")
                                Spacer(minLength: 10)
                                Text(jobDetails.videoFormat)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.2)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("视频编码")
                                Spacer(minLength: 10)
                                Text(jobDetails.videoCodec)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.2)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("分辨率")
                                Spacer(minLength: 10)
                                Text("\(jobDetails.formatWidth) x \(jobDetails.formatHeight)")
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.2)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("像素宽高比")
                                Spacer(minLength: 10)
                                Text("\(jobDetails.pixelAspectRatio)")
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.2)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    if jobDetails.isExportAudio {
                        Section("音频输出") {
                            HStack {
                                Text("音频编码")
                                Spacer(minLength: 10)
                                Text(jobDetails.audioCodec)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.2)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("音频采样率")
                                Spacer(minLength: 10)
                                Text("\(jobDetails.audioSampleRate)")
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.2)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("比特位深")
                                Spacer(minLength: 10)
                                Text("\(jobDetails.audioBitDepth)")
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.2)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                .toolbar(content: {
                    ToolbarItem(id: "refresh", placement: .topBarTrailing) {
                        Button(action: {
                            viewModel.jobDetails = nil
                            viewModel.requestForDetails(of: jobId)
                            enableRetryButton = false
                            Task { @MainActor in
                                try await Task.sleep(for: .seconds(3))
                                enableRetryButton = true
                            }
                        }, label: {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("重新加载")
                        })
                    }
                })
                .navigationTitle(viewModel.jobList[jobId]?.jobName ?? "")
            } else {
                ZStack {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("正在加载任务详情...")
                    }
                    if showRetryButton {
                        Button(action: {
                            viewModel.requestForDetails(of: jobId)
                            enableRetryButton = false
                            Task { @MainActor in
                                try await Task.sleep(for: .seconds(3))
                                enableRetryButton = true
                            }
                        }, label: {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("重试")
                                .padding(3)
                        })
                        .padding(.top, 80)
                        .disabled(!enableRetryButton)
                    }
                }
            }
        }
        .task {
            if let currentJob = viewModel.jobList[jobId] {
                self.currentJob = currentJob
            }
            viewModel.requestForDetails(of: jobId)
            Task { @MainActor in
                try await Task.sleep(for: .seconds(3))
                showRetryButton = true
                enableRetryButton = true
            }
        }
    }
}

#Preview {
    JobDetailsView(jobId: "")
        .environmentObject(ProjectDetailView.ViewModel())
}
