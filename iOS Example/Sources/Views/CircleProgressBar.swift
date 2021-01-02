//
//  CircleProgressBar.swift
//  iOS Example
//
//  Created by Dao Duy Duong on 31/12/2020.
//  Copyright © 2020 Duong Dao. All rights reserved.
//

import SwiftUI

struct CircleProgressBar: View {
    @Binding var progress: Float
    
    let lineWidth: CGFloat = 4
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(Color.red)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)
        }
    }
}
