import MultipeerConnectivity
import os


class MCSender: NSObject, ObservableObject {
    private var serviceType = "exmulti"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    private let methodChannel:FlutterMethodChannel
    
    @Published var connectedPeer:MCPeerID?
    
    
    init(methodChannel:FlutterMethodChannel) {
        self.methodChannel = methodChannel
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceBrowser.delegate = self
        
        serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func send(filechunk: FileChunk) {
        if !session.connectedPeers.isEmpty {
            do {
                //Convert FileChunk Struct to Json
                let jsonData = try JSONEncoder().encode(filechunk)
                
                //Send Json to connected peer
                try session.send(jsonData, toPeers: session.connectedPeers, with: .reliable)
                print("data sent " , filechunk.id)
            } catch {
                print("error sending file chunk")
            }
        }
    }
}
    

extension MCSender: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if(self.connectedPeer == nil ){
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }

}

extension MCSender: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
            DispatchQueue.main.async {
                self.connectedPeer = session.connectedPeers.first
                if(state == MCSessionState.connected){
                    print("Peer Connected")
                    self.methodChannel.invokeMethod("onPeerConnected", arguments: nil)
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}
