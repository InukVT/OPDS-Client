import UIKit

class AppDelegate : NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
      ) -> Bool {
        // ...
        return true
      }
    
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String) async {
            print("\(identifier) done downloading")
    }
}
