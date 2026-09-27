import Foundation
import UIKit

/// Global high-visibility crash and lifecycle logger for physical iOS devices.
/// Writes synchronous log entries and uncaught exceptions to the public Documents directory
/// accessible via the Files app ("On My iPhone" -> "Cave Ranger").
public final class CrashLogger: @unchecked Sendable {
    
    public static let shared = CrashLogger()
    
    private let logFileURL: URL
    private let crashFileURL: URL
    private let fileQueue = DispatchQueue(label: "com.caveranger.logger", qos: .utility)
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFileURL = docs.appendingPathComponent("app_launch_log.txt")
        self.crashFileURL = docs.appendingPathComponent("crash_log.txt")
        
        setupSignalAndExceptionHandlers()
        log("=== CAVE RANGER LAUNCH LOG INITIALIZED ===")
        log("Device: \(UIDevice.current.model), iOS: \(UIDevice.current.systemVersion)")
        log("Time: \(Date())")
    }
    
    public func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formatted = "[\(timestamp)] \(message)\n"
        print(formatted)
        
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            self.appendString(formatted, to: self.logFileURL)
        }
    }
    
    public func logSync(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formatted = "[\(timestamp)] \(message)\n"
        print(formatted)
        appendString(formatted, to: logFileURL)
    }
    
    private func appendString(_ string: String, to url: URL) {
        if let data = string.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                if let fileHandle = try? FileHandle(forWritingTo: url) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
    
    private func setupSignalAndExceptionHandlers() {
        NSSetUncaughtExceptionHandler { exception in
            let symbols = exception.callStackSymbols.joined(separator: "\n")
            let report = """
            ==================================================
            UNCAUGHT NS_EXCEPTION OCCURRED:
            Name: \(exception.name.rawValue)
            Reason: \(exception.reason ?? "Unknown")
            CallStack:
            \(symbols)
            ==================================================
            """
            CrashLogger.shared.logSync(report)
            CrashLogger.shared.appendString(report, to: CrashLogger.shared.crashFileURL)
        }
        
        signal(SIGABRT) { sig in CrashLogger.handleSignal(sig, name: "SIGABRT") }
        signal(SIGSEGV) { sig in CrashLogger.handleSignal(sig, name: "SIGSEGV") }
        signal(SIGBUS)  { sig in CrashLogger.handleSignal(sig, name: "SIGBUS") }
        signal(SIGILL)  { sig in CrashLogger.handleSignal(sig, name: "SIGILL") }
        signal(SIGTRAP) { sig in CrashLogger.handleSignal(sig, name: "SIGTRAP") }
        signal(SIGFPE)  { sig in CrashLogger.handleSignal(sig, name: "SIGFPE") }
    }
    
    private static func handleSignal(_ sig: Int32, name: String) {
        let symbols = Thread.callStackSymbols.joined(separator: "\n")
        let report = """
        ==================================================
        FATAL POSIX SIGNAL CAUGHT: \(name) (\(sig))
        CallStack:
        \(symbols)
        ==================================================
        """
        CrashLogger.shared.logSync(report)
        CrashLogger.shared.appendString(report, to: CrashLogger.shared.crashFileURL)
        exit(sig)
    }
}
