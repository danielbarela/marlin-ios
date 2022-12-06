//
//  IntFilter.swift
//  Marlin
//
//  Created by Daniel Barela on 12/2/22.
//

import SwiftUI

struct IntFilter: View {
    @ObservedObject var filterViewModel: FilterViewModel
    @ObservedObject var viewModel: DataSourcePropertyFilterViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            FilterPropertyName(filterViewModel: filterViewModel, viewModel: viewModel)
            FilterComparison(dataSourcePropertyFilterViewModel: viewModel)
            VStack(alignment: .leading, spacing: 0) {
                TextField(viewModel.dataSourceProperty.name, value: $viewModel.valueInt, format: .number)
                    .keyboardType(.numberPad)
                    .underlineTextField()
                    .onTapGesture(perform: {
                        viewModel.startValidating = true
                    })
                if let validationText = viewModel.validationText {
                    Text(validationText)
                        .overline()
                        .padding(.leading, 8)
                }
            }
        }
    }
}