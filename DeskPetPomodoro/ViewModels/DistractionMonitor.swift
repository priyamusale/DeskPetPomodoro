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
    
    // 5 min warning, 10 min second warning, 15 min close
    let warningThresholdSeconds  = 300   // 5 minutes
    let warning2ThresholdSeconds = 600   // 10 minutes
    let punishmentThresholdSeconds = 900 // 15 minutes
    
    private var hasWarned = false
    private var hasWarned2 = false
    
    private init() {
        startMonitoring()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(executeClose),
            name: NSNotification.Name("executePunishment"),
            object: nil
        )
    }
    
    func startMonitoring() {
        stopMonitoring()
        consecutiveDistractedSeconds = 0
        hasWarned = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
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
            consecutiveDistractedSeconds += 30
            
            if consecutiveDistractedSeconds >= punishmentThresholdSeconds {
                print("Tough Love -> Punishing! (15 min)")
                punishAndCloseTab()
            } else if consecutiveDistractedSeconds >= warning2ThresholdSeconds && !hasWarned2 {
                print("Tough Love -> Second warning! (10 min)")
                hasWarned2 = true
                warnUser(message: "Still here? Focus up!")
            } else if consecutiveDistractedSeconds >= warningThresholdSeconds && !hasWarned {
                print("Tough Love -> Warning! (5 min)")
                warnUser(message: nil) // uses default "Get back to work!"
            }
        } else {
            resetCounter()
        }
    }
    
    private func resetCounter() {
        consecutiveDistractedSeconds = 0
        hasWarned = false
        hasWarned2 = false
    }
    
    private func warnUser(message: String?) {
        if !hasWarned { hasWarned = true }
        let msg = message ?? "Get back to work!"
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("showDistractionWarning"),
                object: msg
            )
        }
    }
    
    private func punishAndCloseTab() {
        resetCounter()
        // Trigger the walk animation; the actual tab close fires via executePunishment
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("walkToCloseTab"), object: nil)
        }
    }
    
    @objc private func executeClose() {
        let domainChecks = blacklistedDomains.map { domain in
            let keyword = domain.replacingOccurrences(of: ".com", with: "")
            return "tURL contains \"\(domain)\" or tURL contains \"\(keyword)\""
        }.joined(separator: " or ")
        
        let scriptSource = """
        if application "Google Chrome" is running then
            tell application "Google Chrome"
                try
                    set tabsToClose to {}
                    repeat with wIdx from 1 to count of windows
                        try
                            set w to window wIdx
                            repeat with tIdx from 1 to count of tabs of w
                                try
                                    set tURL to URL of tab tIdx of w
                                    if \(domainChecks) then
                                        set end of tabsToClose to {wIdx, tIdx}
                                    end if
                                end try
                            end repeat
                        end try
                    end repeat
                    repeat with i from (count of tabsToClose) to 1 by -1
                        try
                            set pair to item i of tabsToClose
                            set wIdx to item 1 of pair
                            set tIdx to item 2 of pair
                            close tab tIdx of window wIdx
                        end try
                    end repeat
                end try
            end tell
        end if
        """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            script.executeAndReturnError(&error)
            if let err = error { print("Close tab error: \(err)") }
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("showDistractionPunishment"), object: nil)
        }
    }
}
