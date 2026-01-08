//
//  LessIsMoreWidgetBundle.swift
//  LessIsMoreWidget
//
//  Created by Angel Geoffroy on 08/01/2026.
//

import WidgetKit
import SwiftUI

@main
struct LessIsMoreWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        StreakWidget()          // Small - Streak only
        TimeWidget()            // Small - Time only
        ComboWidget()           // Medium - Both
        
        // Lock Screen Widgets
        LockScreenStreakWidget()        // Circular - Streak
        LockScreenTimeWidget()          // Circular - Time with gauge
        LockScreenRectangularWidget()   // Rectangular - Both
        LockScreenInlineWidget()        // Inline - Text status
    }
}
