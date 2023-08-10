//
//  DifferentialGPSStation+DataSourceViewBuilder.swift
//  Marlin
//
//  Created by Daniel Barela on 9/17/22.
//

import Foundation
import SwiftUI

extension DifferentialGPSStation: DataSourceViewBuilder {    
    var itemTitle: String {
        return "\(self.name ?? "\(self.featureNumber)")"
    }
    
    var detailView: AnyView {
        AnyView(DifferentialGPSStationDetailView(differentialGPSStation: self))
    }
    
    var summary: some DataSourceSummaryView {
        DifferentialGPSStationSummaryView(differentialGPSStation: self)
    }
}
