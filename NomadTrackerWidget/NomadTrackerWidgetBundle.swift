/*
 NomadTrackerWidgetBundle - Widget extension entry point
 */

import WidgetKit
import SwiftUI

@main
struct NomadTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        CurrentStayWidget()
        YearSummaryWidget()
    }
}
