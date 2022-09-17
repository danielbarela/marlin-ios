//
//  DFRSSummaryView.swift
//  Marlin
//
//  Created by Daniel Barela on 8/30/22.
//

import SwiftUI

struct DFRSSummaryView: View {
    
    var dfrs: DFRS
    var showMoreDetails: Bool = false
    var showSectionHeader: Bool = false
    
    init(dfrs: DFRS, showMoreDetails: Bool = false, showSectionHeader: Bool = false) {
        self.dfrs = dfrs
        self.showMoreDetails = showMoreDetails
        self.showSectionHeader = showSectionHeader
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(dfrs.stationNumber ?? "")")
                .overline()
            Text("\(dfrs.stationName ?? "")")
                .primary()
            if showMoreDetails {
                Text(dfrs.areaName ?? "")
                    .secondary()
            }
            if showSectionHeader {
                Text(dfrs.areaName ?? "")
                    .secondary()
            }
            if let notes = dfrs.notes, notes != "" {
                Text(notes)
                    .primary()
            }
            if let remarks = dfrs.remarks, remarks != "" {
                Text(remarks)
                    .secondary()
            }
            DFRSActionBar(dfrs: dfrs, showMoreDetailsButton: showMoreDetails, showFocusButton: !showMoreDetails)
        }
    }
}