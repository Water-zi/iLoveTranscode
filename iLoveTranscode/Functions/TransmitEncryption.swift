//
//  TransmitEncryption.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/2/13.
//

import Foundation
import CryptoKit

class TransmitEncryption {
    static public var privateKey: String = "iLoveTranscodeAndTranscodeHurtsMe"
    
    static func encryptStringWithKey(_ input: String, privateKey: String = privateKey) -> String? {
        guard let inputData = input.data(using: .utf8) else { return nil }
        let privateKeyData = hashStringUsingSHA256(privateKey)
        
        do {
            let symmetricKey = SymmetricKey(data: privateKeyData)
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(inputData, using: symmetricKey, nonce: nonce)
            let encryptedData = sealedBox.combined
            return encryptedData?.base64EncodedString()
        } catch {
            print("Encryption error:", error.localizedDescription)
            return nil
        }
    }

    static func decryptStringWithKey(_ encryptedString: String, privateKey: String = privateKey) -> String? {
        guard let encryptedData = Data(base64Encoded: encryptedString) else { return nil }
        let privateKeyData = hashStringUsingSHA256(privateKey)
        
        do {
            let symmetricKey = SymmetricKey(data: privateKeyData)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption error:", error.localizedDescription)
            return nil
        }
    }
    
    static private func hashStringUsingSHA256(_ input: String) -> Data {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return Data(hashedData)
    }
    
    
    
}

extension String {
    func encrypt() -> String {
        return TransmitEncryption.encryptStringWithKey(self) ?? ""
    }
    
    func decrypt() -> String {
        return TransmitEncryption.decryptStringWithKey(self) ?? ""
    }
}
