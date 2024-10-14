import UIKit
import Flutter
import UserNotifications
import GoogleMaps


let observer = NSNotification.Name(rawValue: "notification_handler")
let googleAPIKey = "AIzaSyBaGopDKUIczvSeuFIYyrVxHghc667FDT4"

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        registerNotification()
        loadContent()
        addObserver()
        application.registerForRemoteNotifications()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func addObserver() {
        NotificationCenter.default.removeObserver(self, name: observer, object: nil)
        NotificationCenter.default.addObserver(forName: observer, object: nil, queue: nil) { notification in
            print("Observer Called")
            self.receivedNotification(data: [:])
        }
    }
    
    private func receivedNotification(data: [String:Any]) {
        let methodChannel = FlutterMethodChannel(name: "remote_notification", binaryMessenger: self)
        methodChannel.invokeMethod("updateDeliveryStatus", arguments: [:]) { result in
            print("Result: ", result ?? "N/A")
        }
    }
    
    private func registerNotification() {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
    }
    
    private func loadContent() {
        GMSServices.provideAPIKey(googleAPIKey)
    }
}
extension AppDelegate: FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {
        
    }
    
    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply? = nil) {
        
    }
    
    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil) -> FlutterBinaryMessengerConnection {
        return FlutterBinaryMessengerConnection()
    }
    
    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
        
    }
}
