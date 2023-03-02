import MultipeerConnectivity
import os


class MCSender: NSObject, ObservableObject {
    private var serviceType = "exmulti"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let session: MCSession
    private let methodChannel:FlutterMethodChannel
    
    @Published var connectedPeer:MCPeerID?
    
    
    init(methodChannel:FlutterMethodChannel) {
        self.methodChannel = methodChannel
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)

        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self

        serviceAdvertiser.startAdvertisingPeer()
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
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


extension MCSender: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
        self.serviceAdvertiser.stopAdvertisingPeer()
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
