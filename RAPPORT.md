# Rapport de Projet de Fin d'Etude - Morel Adrien M2 E-services

## Introduction

Avec la montée en puissance d'internet depuis les 20 dernières années est né un besoin croissant en terme de partage de données, alors que 
ces temps si la mode est au cloud, aux systèmes centralisés, de nouvelles contraintes mettent à mal cette architecture. Des contraintes telles que 
la protection de la vie privée (et plus globalement la protection des données sensibles), l'écologie, des besoins économiques, des besoins techniques.

La protection de la vie privée et des données sensibles car actuellement les plus gros acteurs du partage de fichier par le cloud sont américains (Google, Dropbox etc) 
et doivent se conformer aux lois qui permettent au dit gouvernement américains d'accèder aux données stockées/partagées via ces plateformes. Il se peut 
également que la plateforme utilisée pour réaliser ces partages ai une origine douteuse ou un but malsain qui nous verrait nous exposer à une fuite d'informations.

L'écologie car vous n'êtes pas sans savoir qu'internet sous entends électricité, celle-ci etant encore trop produit au moyen de combustibles fossible résulant 
en un acroissement de l'effet de serre. Une cause dont l'importance est grandissante à notre époque.

L'économie, en effet la mise en place d'un service centralisé de partage de fichiers a un cout exorbitant, de la mise en place de serveurs au stockage 
de milliers de terabytes de données, sans oublier la mise à niveau nécessaire du réseau tout entier pour permettre un partage à des vitesse correctes.

Des besoins techniques, dans certaines régions du monde le réseau internet etant peu développé voir inexistant le partage de fichiers peu s'avérer être une tâche ardue.
Mais dans certains cas il n'est même pas nécessaire de se trouver dans ces régions pour rencontrer ce genre de problèmes, durant le confinement l'utilisation 
exhorbitante des plateformes de streaming en ligne a mené celles-ci à diminuer le débit auquels elles fournissaient les fichiers vidéos à leurs clients 
de façon à alléger la charge sur le réseau, signe que même dans nos pays "développés" nous pouvons rencontrer ce genre de contraintes techniques.

Une façon de faire face à toutes ces contraintes peut être de mettre directement en relation le fournisseur du fichier et le demandeur au moyen d'un 
réseau unique à ceux-ci. C'est ce que Venice D2D a pour but de mettre en place via une librairie mobile permettant aux développeur de facilement 
implémenter ce système.


## Fonctionnement

Le fonctionnement de cette librairie est simple, l'envoyeur du fichier (sender) sélectionne un fichier à envoyer au receveur (receiver).
Les informations du fichiers (taille, nom etc) ainsi que les informations du canal de données (nom du point s'accès et autres informations de connection)
seront transmise via un cannal Bootstrap (typiquement un qr code à scanner par le receiver). Le receveur se connecte au canal de données grace aux informations
transimisent par le sender, celui-ci commence l'envoi et le fichier se retrouve chez le receiver.

Résultat cette façon de transferer un fichier ne nécessite pas de serveur intermédiaire ni de réseau.

## Canaux de données

En ce qui concerne les téléphones mobiles de nombreuses possibilités s'offrent à nous en terme de canaux de données, en effet les téléphones récent 
possedant toujours plus de capteurs les possibilité de transfert de données n'ont jamais été aussi variées:

- Wifi : Grand rayon d'action, haut débit, connections multitples
- Bluetooth : Rayon d'action moyen, débit moyen, connections multiples
- NFC : Rayon d'action réduit, faible débit, connection unique, nécessite une interaction particulière de l'utilisateur
- Camera/Image/Qr code : Rayon d'action réduit, faible débit, connection unique, nécessite une interaction particulière de l'utilisateur
- Son/Microphone : Rayon d'action réduit, faible débit, "connection" multiple, nécessite le silence de l'utilisateur/environement
- Filaire : Rayon d'action variable, haut débit, connection unique, nécessite du matériel spécifique

En comparant tous ces facteurs il semble que le Wifi soit la méthode la plus propice à une utilisation par le grand public.

## Le canal Multipeer Connectivity

Dans le cas de partage de fichiers d'un système IOS à un autre Apple met à disposition un framework "Multipeer Connectivity" se basant sur une connection Wifi.

Apple restreignant fortement l'utilisation comme bon nous semble des capteurs du téléphone il nous a semblé que cette façon de faire nous permettrait de
rapidement obtenir un partage fonctionnel sur systèmes IOS d'ou le choix de ce canal de données.

### Implémentation

Etant donné que nous implémentons l'interface ***DataChannel*** (venice_core/lib/channels/abstractions/data_channel.dart) et que le framework Mulitpeer Connectivity
n'est disponible qu'en code natif IOS (swift) nous utiliserons un ***MethodChannel*** pour communiquer entre l'implementation de l'interface en Flutter et
le code natif en swift.

#### Création du sender

L'interface ***DataChannel*** requiere la création d'un sendeur:

>multipeer_data_channel.dart

````dart
@override
  Future<void> initSender(BootstrapChannel channel) async {
  ...
  methodChannel.invokeMethod('createSender');
  ...
}
````

Le MethodChannel va ici demander la création d'un objet ***MCSender*** du coté natif.

>MCSender.dart

```swift
class MCSender: NSObject, ObservableObject {
    private var serviceType = "exmulti"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let session: MCSession
    private let methodChannel:FlutterMethodChannel
}
```

- serviceType : Une string définissant le service utilisé, doit être le même entre le sender/receiver sous peine de ne pas pouvoir se connecter
- myPeerId : Nom du sender, défini dans les réglages du système
- serviceAdvertiser : Objet qui va publier le réseau créé
- session : Objet qui va permettre la communication sender/receiver
- methodChannel : Objet qui va permettre de notifier le coté flutter de la connection d'un reciever

```swift
extension MCSender: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
}
```

Va accepter la connection d'un receiver.

```swift
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
```

Qui va mémoriser le reciever connecté et utiliser le MethodChannel défini précédemment pour notifier le coté flutter de la connection du receiver.

L'implémentation de l'interface ***DataChannel*** requiere également la définiton de l'envoi d'une partie du fichier (file chunk):

>multipeer_data_channel.dart

```dart
 @override
  Future<void> sendChunk(FileChunk chunk) async {
    methodChannel.invokeMethod("sendChunk", <String,dynamic>{'id':chunk.identifier,'data': chunk.data});
    ...
  }
```


La classe ***MCSender*** contiendra donc également le code nécesssaire à l'envoi d'une partie du fichier, celui-ci etant découper 
pour facilité le transfert : 

>MCSender.swift

```swift
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
```

La partie du fichier (file chunk) est ici convertie en un objet (json) possible à envoyer par ce canal.

#### Création du receiver

Comme pour le sender, l'interface DataChannel nécessite la création du receiver.

>mulitpeer_data_channel.dart

```dart
  @override
  Future<void> initReceiver(ChannelMetadata data) async {
    
    methodChannel.invokeMethod("createReceiver");
    ...
  }
```
Le MethodChannel va ici demander la création d'un objet ***MCReceiver*** du coté natif.

>MCReceiver.swift

```swift
class MCReceiver: NSObject, ObservableObject {
    private var serviceType = "exmulti"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    private let methodChannel:FlutterMethodChannel
    ...
}
```

Et comme pour le sender le receiver contiendra globalement les mêmes champs à l'exception de :

- serviceBrowser : Qui servira à découvrir le réseau publié par le sender
- methodChannel : Qui cette fois servira à transmettre les données reçues au coté flutter

```swift
extension MCReceiver: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if(self.connectedPeer == nil ){
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }
}
```

Qui servira à demander une connection au sender, à laquelle il répondra positivement comme vu précédemment.

```swift
extension MCReceiver: MCSessionDelegate {

    ...
    
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
    
    ...
}
```

Qui sera l'endroit ou nous receverons les parties de fichier sous forme de json, que nous nous 
chargerons de transmettre au coté flutter via le MethodChannel décrit plus tot et que nous capterons ici:

>multipeer_data_channel.dart

````dart
  @override
  Future<void> initReceiver(ChannelMetadata data) async {
    ...
    methodChannel.setMethodCallHandler((call) => call.method == "chunkReceived"?onChunkRecieved(call.arguments):null);
  }

  onChunkRecieved(arguments) {
    int id = arguments["id"];
    Uint8List data = arguments["data"];
    FileChunk fc = FileChunk(identifier: id, data: data);
    on(DataChannelEvent.data, fc);
  }
````

Un évenement sera lancé contenant les données reçues, puis capté pour reconstiruer le fichier entier.

### Pistes d'amélioration

Comme vous avez pu vous en rendre compte, pour l'instant il n'y a pas d'authentification du sender/receiver : N'importe qui pourrait se faire passer pour un 
reciever et obtenir le fichier partagé à la place. Dans le futur il faudrait donc implémenter une authentification/vérification du destinataire avant de 
procéder à l'envoi pour garantir la sécurité des informations transmisent.

## Conclusion

Le choix de Multipeer Connectivity comme canal de données nous a permis d'obtenir rapidement une implémentation fonctionnelle sur systèmes IOS 
or c'est peut être bien la son seul avantage. En effet ce framework ayant été développé par Apple et pour Apple il n'a jamais eu pour but de permettre
la connection à autre chose qu'un appareil Apple ce qui restreint grandement la flexibilité qui était le but recherché initialement.