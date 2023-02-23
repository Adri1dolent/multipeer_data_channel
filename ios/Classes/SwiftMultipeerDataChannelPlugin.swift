import Flutter
import UIKit

public class SwiftMultipeerDataChannelPlugin: NSObject, FlutterPlugin {
    

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "multipeer_data_channel", binaryMessenger: registrar.messenger())
      let instance = SwiftMultipeerDataChannelPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
    
    var sender:MCSender?
    
    var receiver:MCReceiver?
    
    var methodChannel:FlutterMethodChannel?
    
    
    public init(channel:FlutterMethodChannel) {
            self.methodChannel = channel
            super.init()
    }
    

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      
    switch call.method {

                case "createSender":
                    sender = MCSender(methodChannel: self.methodChannel!)

                case "createReceiver":
                    receiver = MCReceiver(methodChannel: self.methodChannel!)

                case "sendChunk":
                    let args = call.arguments as! [String: Any]
                    
        
                    let id = args["id"] as! Int
                    let uintInt8List =  args["data"] as! FlutterStandardTypedData
                    let data = [UInt8](uintInt8List.data)
        
                    let fc = FileChunk(id: id, data: data)
                    
                    sender!.send(filechunk: fc)

                default:
                    return
                }
  }
}
