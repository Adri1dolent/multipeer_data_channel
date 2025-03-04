import MultipeerConnectivity
import os

class MCReceiver: NSObject, ObservableObject {
    private var serviceType = "exmulti"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    private let methodChannel:FlutterMethodChannel

    
    @Published var connectedPeer:MCPeerID?
    
    init(methodChannel:FlutterMethodChannel) {

        self.methodChannel = methodChannel
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        super.init()

        session.delegate = self
        serviceBrowser.delegate = self

        serviceBrowser.startBrowsingForPeers()
    }

    deinit {
        serviceBrowser.stopBrowsingForPeers()
    }
}

extension MCReceiver: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if(self.connectedPeer == nil ){
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }

}


extension MCReceiver: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeer = session.connectedPeers.first
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        do{
            //Try to decode json recieved form peer
            let decodedFileChunk = try JSONDecoder().decode(FileChunk.self, from: data)
            //Parse
            let backToFLutterType = FlutterStandardTypedData(bytes: Data(decodedFileChunk.data))
            let args = ["id": decodedFileChunk.id, "data": backToFLutterType]  as [String : Any]
            
            print("Chunk recieved, id : " , decodedFileChunk.id)
            
            DispatchQueue.main.async {
                        self.methodChannel.invokeMethod("chunkReceived", arguments: args)
                    }
        }
        catch{
            print("Error decoding data received or sending them through methodchannel")
        }
        
        
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
}
