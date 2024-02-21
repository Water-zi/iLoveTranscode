//
//  iLoveTranscodeWidgetLiveActivity.swift
//  iLoveTranscodeWidget
//
//  Created by 唐梓皓 on 2024/1/31.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct iLoveTranscodeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: iLoveTranscodeWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                HStack {
                    Text(context.attributes.projectName)
                        .bold()
                    Spacer()
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                    //                    Text("\(context.state.wrappedRenderJob().intervalSinceLastUpdate())")
                    //                        .font(.system(size: 12))
                }
                Divider()
                    .padding(.bottom, 5)
                HStack {
                    ZStack {
                        WidgetJobsCircleProgressView(readyJobsCount: context.state.readyJobNumber, failedJobsCount: context.state.failedJobNumber, finishJobsCount: context.state.finishJobNumber, strokeWidth: 12)
                            .padding(10)
                        Image(systemName: context.state.isRendering ? "heat.waves" : "moon.zzz")
                            .bold()
                            .font(.system(size: 25))
                    }
                    
                    Divider()
                    
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "briefcase")
                            Text(context.state.currentJobName)
                            Spacer()
                            Image(systemName: "filemenu.and.selection")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(context.state.currentTimelineName)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("\(context.state.currentJobStatus == .rendering ? "剩余时间" : "任务耗时")：\(context.state.currentJobDurationString)")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.system(size: 15, weight: .light))
                        HStack(spacing: 10) {
                            Text(context.state.currentJobStatus.string)
                                .foregroundStyle(context.state.currentJobStatus.color)
                            RenderJobProgressView(progress: CGFloat(context.state.currentJobProgress) / 100, height: 12, color: context.state.currentJobStatus.color)
                                .animation(.easeInOut, value: context.state.currentJobProgress)
                            Text("\(context.state.currentJobProgress)%")
                                .foregroundStyle(context.state.currentJobStatus.color)
                                .frame(minWidth: 50, alignment: .trailing)
                        }
                        
                    }
                }
            }
            .padding()
            .activityBackgroundTint(nil)
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    ZStack {
                        WidgetJobsCircleProgressView(readyJobsCount: context.state.readyJobNumber, failedJobsCount: context.state.failedJobNumber, finishJobsCount: context.state.finishJobNumber, strokeWidth: 10)
                        Image(systemName: context.state.isRendering ? "heat.waves" : "moon.zzz")
                            .bold()
                            .font(.system(size: 25))
                    }
                    .frame(maxHeight: 60)
                    .padding(5)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "timer")
                        .padding(5)
                }
                DynamicIslandExpandedRegion(.center) {
                    Grid(horizontalSpacing: 5, verticalSpacing: 5) {
                        GridRow {
                            Image(systemName: "briefcase")
                            Text(context.state.currentJobName)
                        }
                        GridRow {
                            Image(systemName: "filemenu.and.selection")
                            Text(context.state.currentTimelineName)
                        }
                        Text("\(context.state.currentJobStatus == .rendering ? "剩余时间" : "任务耗时")：\(context.state.currentJobDurationString)")
                            .font(.system(size: 15, weight: .light))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        Text(context.state.currentJobStatus.string)
                            .foregroundStyle(context.state.currentJobStatus.color)
                        RenderJobProgressView(progress: CGFloat(context.state.currentJobProgress) / 100, height: 12, color: context.state.currentJobStatus.color)
                            .animation(.easeInOut, value: context.state.currentJobProgress)
                        Text("\(context.state.currentJobProgress)%")
                            .foregroundStyle(context.state.currentJobStatus.color)
                            .frame(minWidth: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
            } compactLeading: {
                ZStack {
                    Image(systemName: context.state.isRendering ? "heat.waves" : "moon.zzz")
                        .bold()
                        .font(.system(size: 12))
//                        .padding(4)
//                        .padding(.leading, 3)
                    WidgetJobsCircleProgressView(readyJobsCount: context.state.readyJobNumber, failedJobsCount: context.state.failedJobNumber, finishJobsCount: context.state.finishJobNumber, strokeWidth: 2)
//                        .padding(2)
                }
                .padding(.trailing, 3)
            } compactTrailing: {
                Text(context.state.currentJobDurationString)
            } minimal: {
                ZStack {
                    WidgetJobsCircleProgressView(readyJobsCount: context.state.readyJobNumber, failedJobsCount: context.state.failedJobNumber, finishJobsCount: context.state.finishJobNumber, strokeWidth: 5)
                    Image(systemName: context.state.isRendering ? "heat.waves" : "moon.zzz")
                        .bold()
                        .font(.system(size: 10))
                }
                .padding(2)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension iLoveTranscodeWidgetAttributes {
    fileprivate static var preview: iLoveTranscodeWidgetAttributes {
        iLoveTranscodeWidgetAttributes(projectName: "Preview Project")
    }
}

extension iLoveTranscodeWidgetAttributes.ContentState {
    fileprivate static var first: iLoveTranscodeWidgetAttributes.ContentState {
        iLoveTranscodeWidgetAttributes.ContentState(readyJobNumber: 5, failedJobNumber: 0, finishJobNumber: 0, isRendering: false, lastUpdate: Date(), currentJobId: UUID().uuidString, currentJobName: "Preview Job 1", currentTimelineName: "PT1", currentJobStatus: .ready, currentJobProgress: 0, currentJobDurationString: "未知...")
    }
    
    fileprivate static var second: iLoveTranscodeWidgetAttributes.ContentState {
        iLoveTranscodeWidgetAttributes.ContentState(readyJobNumber: 2, failedJobNumber: 1, finishJobNumber: 2, isRendering: false, lastUpdate: Date(), currentJobId: UUID().uuidString, currentJobName: "Preview Job 2", currentTimelineName: "PT1", currentJobStatus: .ready, currentJobProgress: 80, currentJobDurationString: "5s")
    }
}

#Preview("Notification", as: .content, using: iLoveTranscodeWidgetAttributes.preview) {
    iLoveTranscodeWidgetLiveActivity()
} contentStates: {
    iLoveTranscodeWidgetAttributes.ContentState.first
    iLoveTranscodeWidgetAttributes.ContentState.second
}
