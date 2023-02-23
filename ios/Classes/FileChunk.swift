import Foundation

struct FileChunk : Encodable,Decodable {
        var id:Int
        var data:[UInt8]
    }
