//
//  Selector.swift
//  OPDS-Client
//
//  Created by Bastian Inuk Christensen on 2022-03-07.
//

import SwiftUI

struct Selector <
    SelectionValue
> : View
where SelectionValue: StringIterable,
      SelectionValue.AllCases: RandomAccessCollection,
      SelectionValue: Identifiable,
      SelectionValue: Hashable
{
    private let label: LocalizedStringKey
    private var selection: Binding<SelectionValue>
    
    init(_ key: LocalizedStringKey, selection: Binding<SelectionValue>) {
        self.label = key
        self.selection = selection
    }
    
    var body: some View {
        Picker(self.label, selection: selection) {
            ForEach(SelectionValue.allCases) { value in
                Text( LocalizedStringKey( value.rawValue.capitalized ) )
            }
        }
    }
}

protocol StringIterable : CaseIterable {
    var rawValue: String { get }
}

fileprivate struct SelectorTest : View {
    @State private var selected: Animal = .dog
    
    var body: some View {
        NavigationView {
            List {
                Section("Animal") {
                    Text(selected.rawValue.capitalized)
                    Text(selected.rawValue.capitalized)
                    Selector("Animal", selection: $selected)
                        .pickerStyle(.automatic)
                    Text(selected.rawValue.capitalized)
                }
            }
            .navigationTitle("Title")
        }
    }
}

extension SelectorTest {
    enum Animal : String, StringIterable, Identifiable {
        case dog, cat, snake, hest
        var id: Self {self}
    }
}

struct Selector_Previews: PreviewProvider {
    static var previews: some View {
        SelectorTest()
    }
}
