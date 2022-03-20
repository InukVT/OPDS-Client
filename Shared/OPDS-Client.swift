import SwiftUI

@main
struct OPDSClient: App {
    @UIApplicationDelegateAdaptor
    var delegate: AppDelegate
    
    @StateObject
    var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
