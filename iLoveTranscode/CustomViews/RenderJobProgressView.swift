//
//  RenderJobProgressView.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/31.
//

import SwiftUI

struct RenderJobProgressView: View {
    let progress: CGFloat
    let height: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .frame(width: geometry.size.width, height: height)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .frame(
                        width: min(progress * geometry.size.width,
                                   geometry.size.width),
                        height: height
                    )
                    .foregroundColor(color)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    RenderJobProgressView(progress: 0.8, height: 20, color: .blue)
}
