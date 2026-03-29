import CoreNFC
import Foundation

enum NFCScanPurpose {
    case register
    case authenticate
}

@Observable
final class NFCService: NSObject {
    var scannedTagId: String?
    var errorMessage: String?
    var isScanning = false

    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<String, Error>?

    func scan() async throws -> String {
        guard NFCTagReaderSession.readingAvailable else {
            throw NFCError.notAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.session = NFCTagReaderSession(
                pollingOption: [.iso14443],
                delegate: self,
                queue: .main
            )
            self.session?.alertMessage = "Hold your phone near your Brick chip."
            self.session?.begin()
            self.isScanning = true
        }
    }
}

extension NFCService: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error) {
        isScanning = false
        if let nfcError = error as? NFCReaderError,
           nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            continuation?.resume(throwing: NFCError.cancelled)
        } else {
            continuation?.resume(throwing: NFCError.readFailed(error.localizedDescription))
        }
        continuation = nil
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag found.")
            return
        }

        session.connect(to: tag) { [weak self] error in
            if let error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }

            let tagId: String
            switch tag {
            case .iso7816(let iso7816Tag):
                tagId = iso7816Tag.identifier.map { String(format: "%02x", $0) }.joined()
            case .miFare(let miFareTag):
                tagId = miFareTag.identifier.map { String(format: "%02x", $0) }.joined()
            case .iso15693(let iso15693Tag):
                tagId = iso15693Tag.identifier.map { String(format: "%02x", $0) }.joined()
            case .feliCa(let feliCaTag):
                tagId = feliCaTag.currentIDm.map { String(format: "%02x", $0) }.joined()
            @unknown default:
                session.invalidate(errorMessage: "Unsupported tag type.")
                return
            }

            self?.scannedTagId = tagId
            self?.isScanning = false
            session.alertMessage = "Chip recognized!"
            session.invalidate()
            self?.continuation?.resume(returning: tagId)
            self?.continuation = nil
        }
    }
}

enum NFCError: LocalizedError {
    case notAvailable
    case cancelled
    case readFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "NFC is not available on this device."
        case .cancelled:
            return "NFC scan was cancelled."
        case .readFailed(let message):
            return "Failed to read NFC tag: \(message)"
        }
    }
}
