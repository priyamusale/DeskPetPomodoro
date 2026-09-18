import Foundation
import Cocoa

class DistractionMonitor: ObservableObject {
    static let shared = DistractionMonitor()
    
    @Published var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    
    private var timer: Timer?
    @Published var consecutiveDistractedSeconds = 0
    
    private let blacklistedDomains = ["youtube.com", "instagram.com", "tiktok.com", "facebook.com"]
    
    let warningThresholdSeconds = 10
    let punishmentThresholdSeconds = 20
    
    private var hasWarned = false
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        stopMonitoring()
        consecutiveDistractedSeconds = 0
        hasWarned = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkActiveTab()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkActiveTab() {
        let scriptSource = """
        if application "Google Chrome" is running then
            tell application "Google Chrome"
                set allText to ""
                try
                    repeat with w in windows
                        try
                            set allText to allText & (name of w) & "|||"
                        end try
                        try
                            repeat with t in tabs of w
                                try
                                    set allText to allText & (URL of t) & "|||"
                                end try
                            end repeat
                        end try
                    end repeat
                end try
                return allText
            end tell
        else
            return ""
        end if
        """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let result = script.executeAndReturnError(&error)
            if let resultString = result.stringValue {
                handleResult(resultString)
            } else {
                if let error = error {
                    print("AppleScript Error: \(error)")
                }
                resetCounter()
            }
        } else {
            resetCounter()
        }
    }
    
    private func handleResult(_ resultString: String) {
        if resultString.isEmpty {
            resetCounter()
            return
        }
        
        let isDistracted = blacklistedDomains.contains { domain in
            let keyword = domain.replacingOccurrences(of: ".com", with: "")
            return resultString.lowercased().contains(domain.lowercased()) || resultString.lowercased().contains(keyword.lowercased())
        }
        
        print("Tough Love Check -> isDistracted: \(isDistracted) | Consecutive: \(consecutiveDistractedSeconds)")
        
        if isDistracted {
            consecutiveDistractedSeconds += 5
            
            if consecutiveDistractedSeconds >= punishmentThresholdSeconds {
                print("Tough Love -> Punishing!")
                punishAndCloseTab()
            } else if consecutiveDistractedSeconds >= warningThresholdSeconds && !hasWarned {
                print("Tough Love -> Warning!")
                warnUser()
            }
        } else {
            resetCounter()
        }
    }
    
    private func resetCounter() {
        consecutiveDistractedSeconds = 0
        hasWarned = false
    }
    
    private func warnUser() {
        hasWarned = true
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("showDistractionWarning"), object: nil)
        }
    }
    
    private func punishAndCloseTab() {
        let condition = blacklistedDomains.map { domain in
            let keyword = domain.replacingOccurrences(of: ".com", with: "")
            return "tURL contains \"\\(domain)\" or tURL contains \"\\(keyword)\" or tTitle contains \"\\(domain)\" or tTitle contains \"\\(keyword)\""
        }.joined(separator: " or ")
        
        let scriptSource = """
        if application "Google Chrome" is running then
            tell application "Google Chrome"
                try
                    repeat with w in windows
                        try
                            repeat with t in tabs of w
                                try
                                    set tURL to URL of t
                                    set tTitle to title of t
                                    if \(condition) then
                                        close t
                                    end if
                                end try
                            end repeat
                        end try
                    end repeat
                end try
            end tell
        end if
        """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            script.executeAndReturnError(&error)
        }
        
        resetCounter()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("showDistractionPunishment"), object: nil)
        }
    }
}
