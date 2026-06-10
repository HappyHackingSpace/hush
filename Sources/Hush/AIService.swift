import Foundation
import Observation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device script editing via Apple's Foundation Models. Nothing leaves the Mac, and there is
/// no API key. Unavailable on macOS versions or hardware without Apple Intelligence.
@MainActor
@Observable
final class AIService {
    enum AIError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            "On-device AI is unavailable. It needs macOS 26+ with Apple Intelligence enabled."
        }
    }

    private(set) var isWorking = false

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    func transform(_ text: String, instruction: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return text }
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), isAvailable {
            isWorking = true
            defer { isWorking = false }
            let session = LanguageModelSession(instructions: Self.systemInstructions)
            let response = try await session.respond(to: "\(instruction)\n\nScript:\n\(text)")
            return response.content
        }
        #endif
        throw AIError.unavailable
    }

    private static let systemInstructions = """
    You edit spoken scripts and teleprompter copy. Return only the revised script text, with no \
    preamble, commentary, or surrounding quotation marks. Keep it natural to say aloud.
    """
}
