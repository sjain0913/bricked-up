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
        // Only resume if didDetect hasn't already consumed the continuation
        guard let continuation = continuation else { return }
        self.continuation = nil
        if let nfcError = error as? NFCReaderError,
           nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            continuation.resume(throwing: NFCError.cancelled)
        } else if let nfcError = error as? NFCReaderError,
                  nfcError.code == .readerSessionInvalidationErrorFirstNDEFTagRead ||
                  nfcError.code == .readerSessionInvalidationErrorSessionTerminatedUnexpectedly {
            continuation.resume(throwing: NFCError.readFailed(error.localizedDescription))
        } else {
            continuation.resume(throwing: NFCError.readFailed(error.localizedDescription))
        }
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
            // Consume continuation before invalidate — invalidate triggers didInvalidateWithError
            let cont = self?.continuation
            self?.continuation = nil
            session.invalidate()
            cont?.resume(returning: tagId)
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
