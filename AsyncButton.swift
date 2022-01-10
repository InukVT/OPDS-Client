import SwiftUI

/// A control that initialised an async action
struct AsyncButton <Label> : View where Label : View {
    /// The async task to run when button is hit
    let task: () async -> ()
    
    /// Label to show the user
    @ViewBuilder
    let label: () -> Label
    
    var body: some View {
        Button { Task { await self.task() }  } label: { self.label() }
    }
}
