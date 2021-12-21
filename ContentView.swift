import SwiftUI

struct ContentView: View {
    @State
    var servers: [Server] = []
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(servers, id: \.name) { server in
                    Text(server.name)
                }
            }
        }
        ServerBar(onSearch: search)
            .padding(10)
            .background(Color(uiColor: .secondarySystemBackground))
    }
    
    func search(address: String) {
        print(address)
    }
}

/// Simple search bar with callback to search and adding fields
struct ServerBar : View {
    /// Called when the user presses the search button
    let onSearch: (String) -> ()
    
    func action(fun : KeyPath<ServerBar,(String)->()>) -> () -> () {
        return { self[keyPath: fun](address) }
    }
    
    @State
    private var address: String = ""
    
    var body: some View {
        HStack {
            TextField("Server", text: $address)
                .onSubmit(of: /*@START_MENU_TOKEN@*/.text/*@END_MENU_TOKEN@*/, action(fun: \.onSearch) )
            Button("Search", action: action(fun: \.onSearch) )
        }
    }
}

struct Server {
    let name: String
    let server: String
}

extension Server {
    var id: String {
        name + server
    }
}
