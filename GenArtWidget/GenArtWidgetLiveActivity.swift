//
//  GenArtWidgetLiveActivity.swift
//  GenArtWidget
//
//  Created by Pedro on 9/12/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GenArtWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GenArtWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GenArtWidgetAttributes.self) { context in
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

extension GenArtWidgetAttributes {
    fileprivate static var preview: GenArtWidgetAttributes {
        GenArtWidgetAttributes(name: "World")
    }
}

extension GenArtWidgetAttributes.ContentState {
    fileprivate static var smiley: GenArtWidgetAttributes.ContentState {
        GenArtWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GenArtWidgetAttributes.ContentState {
         GenArtWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GenArtWidgetAttributes.preview) {
   GenArtWidgetLiveActivity()
} contentStates: {
    GenArtWidgetAttributes.ContentState.smiley
    GenArtWidgetAttributes.ContentState.starEyes
}
