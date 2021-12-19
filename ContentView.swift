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
        ServerBar(onSearch: search, onSave: save)
            .padding(10)
    }
    
    func save(address: String) {
        
    }
    
    func search(address: String) {
        print(address)
    }
}

struct ServerBar : View {
    /// Called when the user presses the search button
    let onSearch: (String) -> ()
    /// Called when the user presses the save button
    let onSave: (String) -> ()
    
    @State
    var address: String = ""
    
    var body: some View {
        HStack {
            TextField("Server", text: $address)
            Button("Search") {
                onSearch("Searched")
            }
            
            Button("Add") {
                onSave("Saved")
            }
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
