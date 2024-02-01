//
//  WidgetJobsCircleProgressView.swift
//  iLoveTranscodeWidgetExtension
//
//  Created by 唐梓皓 on 2024/2/1.
//

import SwiftUI
import WidgetKit

struct WidgetJobsCircleProgressView: View {
    var readyJobsCount: Int
    var failedJobsCount: Int
    var finishJobsCount: Int
    var strokeWidth: CGFloat
    
    @State var blueStart: CGFloat = 0
    @State var blueEnd: CGFloat = 0.33
    @State var redStart: CGFloat = 0.33
    @State var redEnd: CGFloat = 0.66
    @State var greenStart: CGFloat = 0.66
    @State var greenEnd: CGFloat = 1
    @State var hasJob: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            Circle()
                .trim(from: blueStart, to: blueEnd)
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                .foregroundStyle(.blue)
            
            Circle()
                .trim(from: redStart, to: redEnd)
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                .foregroundStyle(.red)
            
            Circle()
                .trim(from: greenStart, to: greenEnd)
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                .foregroundStyle(.green)
            
        }
        .rotationEffect(.degrees(-90))
        .onAppear(perform: {
            anaStartEnd()
        })
    }
    
    func anaStartEnd() {
        let readyJobsCount = CGFloat(readyJobsCount)
        let failedJobsCount = CGFloat(failedJobsCount)
        let finishJobsCount = CGFloat(finishJobsCount)
        let total = readyJobsCount + failedJobsCount + finishJobsCount
        guard total > 0 else {
            hasJob = false
            return
        }
        hasJob = true
        blueStart = 0
        if readyJobsCount > 0 {
            blueEnd = readyJobsCount / total
        } else {
            blueEnd = blueStart
        }
        redStart = blueEnd
        if failedJobsCount > 0 {
            redEnd = redStart + failedJobsCount / total
        } else {
            redEnd = redStart
        }
        greenStart = redEnd
        greenEnd = 1
    }
}

#Preview {
    WidgetJobsCircleProgressView(readyJobsCount: 1, failedJobsCount: 1, finishJobsCount: 0, strokeWidth: 20)
}
