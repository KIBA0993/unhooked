//
//  UnhookedWidgetsLiveActivity.swift
//  UnhookedWidgets
//
//  Created by Simon Chen on 10/23/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct UnhookedWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct UnhookedWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UnhookedWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension UnhookedWidgetsAttributes {
    fileprivate static var preview: UnhookedWidgetsAttributes {
        UnhookedWidgetsAttributes(name: "World")
    }
}

extension UnhookedWidgetsAttributes.ContentState {
    fileprivate static var smiley: UnhookedWidgetsAttributes.ContentState {
        UnhookedWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: UnhookedWidgetsAttributes.ContentState {
         UnhookedWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: UnhookedWidgetsAttributes.preview) {
   UnhookedWidgetsLiveActivity()
} contentStates: {
    UnhookedWidgetsAttributes.ContentState.smiley
    UnhookedWidgetsAttributes.ContentState.starEyes
}
