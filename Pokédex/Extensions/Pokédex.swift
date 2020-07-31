import Foundation
import struct ObjectLibrary.Pokédex

extension Pokédex.Entry {
    
    @objc public var collationString: String {
        return displayText
    }
    
}
