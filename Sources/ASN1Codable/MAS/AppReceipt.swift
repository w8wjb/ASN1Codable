//
//  MASReceipt.swift
//  Mac ASN1Codable
//
//  Created by Weston Bustraan on 1/3/25.
//

import Foundation

public struct AppReceipt: Decodable, DERTagAware {
    
    public static var tag: DERTagOptions? = .SET
    
    public static var childTagStrategy: (any DERTagStrategy)? = TagStrategy()
    
    var attributes: Array<ReceiptAttribute>

    /// Bundle Identifier
    /// The app’s bundle identifier.
    ///
    /// This corresponds to the value of CFBundleIdentifier in the Info.plist file. Use this value to validate if the receipt was indeed generated for your app
    public var bundleId: String?
    
    /// The bundleId, but as Data
    public var bundleIdData: Data?
    
    /// App Version
    /// The app’s version number.
    ///
    /// This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist.
    public var applicationVersion: String?
    
    /// An opaque value used, with other data, to compute the SHA-1 hash during validation.
    public var opaqueValue: Data?
    
    /// A SHA-1 hash, used to validate the receipt.
    public var sha1Digest: Data?

    /// The receipts for an in-app purchase.
    ///
    /// Note: An empty array is a valid receipt.
    ///
    /// The in-app purchase receipt for a consumable product is added to the receipt when the purchase is made. It is kept in the receipt until your app finishes that transaction.
    /// After that point, it is removed from the receipt the next time the receipt is updated - for example, when the user makes another purchase or if your app explicitly refreshes the receipt.
    ///
    /// The in-app purchase receipt for a non-consumable product, auto-renewable subscription, non-renewing subscription, or free subscription remains in the receipt indefinitely.
    public var inAppPurchaseReceipts = [InAppPurchaseReceipt]()
    
    /// The version of the app that was originally purchased.
    ///
    /// This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
    ///
    /// In the sandbox environment, the value of this field is always “1.0”.
    public var originalApplicationVersion: String?
    
    /// The date when the app receipt was created.
    ///
    /// When validating a receipt, use this date to validate the receipt’s signature.
    public var receiptCreationDate: Date?
    
    /// The date that the app receipt expires.
    ///
    /// This key is present only for apps purchased through the Volume Purchase Program. If this key is not present, the receipt does not expire.
    ///
    /// When validating a receipt, compare this date to the current date to determine whether the receipt is expired.
    /// Do not try to use this date to calculate any other information, such as the time remaining before expiration.
    public var expirationDate: Date?
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        attributes = try container.decode(Array<ReceiptAttribute>.self)
        
        let formatter = ISO8601DateFormatter()
        let valueDecoder = DERDecoder()
        valueDecoder.tagStrategy = Self.childTagStrategy!

        for attribute in attributes {
            switch attribute.type {
            case 2:
                bundleId = attribute.stringValue
                bundleIdData = attribute.data
            case 3:
                applicationVersion = attribute.stringValue
            case 4:
                opaqueValue = attribute.data
            case 5:
                sha1Digest = attribute.data
            case 12:
                if let dateString = attribute.stringValue {
                    receiptCreationDate = formatter.date(from: dateString)
                }
                
            case 17:
                let purchaseData = attribute.data
                let iapReceipt = try valueDecoder.decode(InAppPurchaseReceipt.self, from: purchaseData)
                inAppPurchaseReceipts.append(iapReceipt)
                
            case 19:
                originalApplicationVersion = attribute.stringValue
                
            case 21:
                if let dateString = attribute.stringValue {
                    expirationDate = formatter.date(from: dateString)
                }

            default:
                continue
            }
            
        }
        
        
    }
    
    private class TagStrategy : DefaultDERTagStrategy {
        
        public override func tag(forType type: Decodable.Type, atPath codingPath: [CodingKey]) -> DERTagOptions {
            if type is Array<ReceiptAttribute>.Type {
                return .SET
            }
 
            return super.tag(forType: type, atPath: codingPath)
        }

    }
    
}
