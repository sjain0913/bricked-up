import CoreNFC
import Foundation

@Observable
final class NFCService: NSObject {
    var scannedTagId: String?
    var errorMessage: String?
    var isScanning = false

    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<String, Error>?

    // NDEF writing
    private var ndefSession: NFCNDEFReaderSession?
    private var ndefContinuation: CheckedContinuation<Void, Error>?
    private var pendingMessage: NFCNDEFMessage?

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

    /// Writes a `brickedup://toggle` NDEF URL to the chip so iOS can read it in the background.
    func writeToggleURL() async throws {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCError.notAvailable
        }
        guard let url = URL(string: "brickedup://toggle"),
              let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else {
            throw NFCError.readFailed("Could not create NDEF payload")
        }
        pendingMessage = NFCNDEFMessage(records: [payload])

        return try await withCheckedThrowingContinuation { continuation in
            self.ndefContinuation = continuation
            let session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: false)
            session.alertMessage = "Hold your phone near the NFC chip to program it."
            session.begin()
            self.ndefSession = session
            self.isScanning = true
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension NFCService: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error) {
        isScanning = false
        guard let continuation = continuation else { return }
        self.continuation = nil
        if let nfcError = error as? NFCReaderError,
           nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            continuation.resume(throwing: NFCError.cancelled)
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
            let cont = self?.continuation
            self?.continuation = nil
            session.invalidate()
            cont?.resume(returning: tagId)
        }
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCService: NFCNDEFReaderSessionDelegate {
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        isScanning = false
        guard let continuation = ndefContinuation else { return }
        ndefContinuation = nil
        if let nfcError = error as? NFCReaderError,
           nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            continuation.resume(throwing: NFCError.cancelled)
        } else {
            continuation.resume(throwing: NFCError.readFailed(error.localizedDescription))
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used — writing happens via didDetect
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first, let message = pendingMessage else {
            session.invalidate(errorMessage: "No tag found.")
            return
        }

        session.connect(to: tag) { [weak self] error in
            if let error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }

            tag.queryNDEFStatus { status, _, error in
                if let error {
                    session.invalidate(errorMessage: "Could not query tag: \(error.localizedDescription)")
                    return
                }
                guard status == .readWrite else {
                    session.invalidate(errorMessage: "This chip is read-only and cannot be programmed.")
                    self?.ndefContinuation?.resume(throwing: NFCError.readFailed("Tag is read-only"))
                    self?.ndefContinuation = nil
                    return
                }

                tag.writeNDEF(message) { error in
                    self?.isScanning = false
                    let cont = self?.ndefContinuation
                    self?.ndefContinuation = nil
                    self?.pendingMessage = nil

                    if let error {
                        session.invalidate(errorMessage: "Write failed.")
                        cont?.resume(throwing: NFCError.readFailed(error.localizedDescription))
                    } else {
                        session.alertMessage = "Chip programmed! Tap it anytime to brick/unbrick."
                        session.invalidate()
                        cont?.resume()
                    }
                }
            }
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
