import Foundation
import AppKit

class PetViewModel: ObservableObject {
    @Published var walkFrame: Int = 0
    @Published var showTreat: Bool = false
    @Published var isActive: Bool = false
    @Published var isSleeping: Bool = false
    @Published var speechMessage: String? = nil
    @Published var facingRight: Bool = true
    @Published var walkRotation: Double = 0  // 0=normal, -90=walking up, 90=walking down
    
    private var frameTimer: Timer?
    private var sleepTimer: Timer?
    
    init() {
        setupNotifications()
        startSleepTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(onShowDistractionWarning), name: NSNotification.Name("showDistractionWarning"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onShowDistractionPunishment), name: NSNotification.Name("showDistractionPunishment"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTimers()
        sleepTimer?.invalidate()
    }
    
    var userFirstName: String {
        let fullName = NSFullUserName()
        return fullName.components(separatedBy: " ").first ?? "Friend"
    }
    
    // MARK: Walk Control
    
    func startWalking() {
        sleepTimer?.invalidate()
        let wasSleeping = isSleeping
        isSleeping = false
        
        if wasSleeping || !isActive {
            showSpeech("Hi \(userFirstName)!")
        }
        
        guard !isActive else { return }
        isActive = true
        startFrameTimer()
    }
    
    func stopWalking() {
        isActive = false
        stopTimers()
        startSleepTimer()
    }
    
    // MARK: Treat
    
    func triggerTreat() {
        guard !showTreat else { return }
        let wasActive = isActive
        if wasActive { stopTimers() }
        showTreat = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.showTreat = false
            if wasActive && self.isActive { self.startFrameTimer() }
        }
    }
    
    // MARK: Timers
    
    private func startFrameTimer() {
        frameTimer?.invalidate()
        // slightly slower walk cycle since the pet moves very slowly now
        frameTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async { self.walkFrame = (self.walkFrame + 1) % 10000 }
        }
    }
    
    private func stopTimers() {
        frameTimer?.invalidate(); frameTimer = nil
    }
    
    private func startSleepTimer() {
        sleepTimer?.invalidate()
        // Sleep after 2 minutes of inactivity (120 seconds)
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.isSleeping = true }
        }
    }
    
    // MARK: Speech
    
    func showSpeech(_ message: String) {
        speechMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.speechMessage == message {
                self?.speechMessage = nil
            }
        }
    }
    
    // MARK: Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(onSessionStarted),
            name: .pomodoroSessionStarted, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(onSessionPaused),
            name: .pomodoroSessionPaused, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(onTaskCompleted),
            name: .taskCompleted, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(onWagerCompleted),
            name: Notification.Name("wagerCompleted"), object: nil)
    }
    
    @objc private func onSessionStarted() {
        DispatchQueue.main.async { self.startWalking() }
    }
    
    @objc private func onSessionPaused() {
        DispatchQueue.main.async { self.stopWalking() }
    }
    
    @objc private func onTaskCompleted() {
        DispatchQueue.main.async {
            self.triggerTreat()
        }
    }
    
    @objc private func onWagerCompleted() {
        DispatchQueue.main.async {
            self.showSpeech("Good job, \(self.userFirstName)!")
        }
    }
    
    @objc private func onShowDistractionWarning(_ note: Notification) {
        let msg = note.object as? String ?? "Get back to work!"
        DispatchQueue.main.async {
            self.isSleeping = false
            self.showSpeech(msg)
        }
    }
    
    @objc private func onShowDistractionPunishment() {
        DispatchQueue.main.async {
            self.isSleeping = false
            self.showSpeech("I warned you! I closed that tab!")
        }
    }
}

class CoworkingViewModel: ObservableObject {
    @Published var roomCode: String = UserDefaults.standard.string(forKey: "coworkingRoomCode") ?? ""
    @Published var isConnected: Bool = false
    @Published var isCoworkerActive: Bool = false
    
    let baseURL = "https://deskpetpomodoro-default-rtdb.firebaseio.com/rooms"
    
    let myDeviceId: String = {
        if let id = UserDefaults.standard.string(forKey: "coworkingDeviceId") {
            return id
        } else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: "coworkingDeviceId")
            return id
        }
    }()
    
    private var updateTimer: Timer?
    private var pollTimer: Timer?
    
    @Published var amIWorking: Bool = false {
        didSet {
            if isConnected {
                pushMyStatus()
            }
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onSessionStarted), name: .pomodoroSessionStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onSessionPaused), name: .pomodoroSessionPaused, object: nil)
        
        if !roomCode.isEmpty {
            joinRoom(roomCode)
        }
    }
    
    @objc private func onSessionStarted() {
        DispatchQueue.main.async { self.amIWorking = true }
    }
    
    @objc private func onSessionPaused() {
        DispatchQueue.main.async { self.amIWorking = false }
    }
    
    func joinRoom(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return }
        
        self.roomCode = trimmed
        UserDefaults.standard.set(trimmed, forKey: "coworkingRoomCode")
        self.isConnected = true
        
        pushMyStatus()
        startPolling()
    }
    
    func leaveRoom() {
        if isConnected {
            deleteMyStatus()
        }
        
        self.roomCode = ""
        UserDefaults.standard.removeObject(forKey: "coworkingRoomCode")
        self.isConnected = false
        self.isCoworkerActive = false
        stopPolling()
    }
    
    private func pushMyStatus() {
        guard isConnected, !roomCode.isEmpty else { return }
        let urlString = "\(baseURL)/\(roomCode)/\(myDeviceId).json"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let payload: [String: Any] = [
            "isWorking": amIWorking,
            "lastUpdated": Date().timeIntervalSince1970
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    private func deleteMyStatus() {
        guard !roomCode.isEmpty else { return }
        let urlString = "\(baseURL)/\(roomCode)/\(myDeviceId).json"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.pollRoomStatus()
        }
        pollRoomStatus()
    }
    
    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
    
    private func pollRoomStatus() {
        guard isConnected, !roomCode.isEmpty else { return }
        let urlString = "\(baseURL)/\(roomCode).json"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var foundActiveCoworker = false
                let now = Date().timeIntervalSince1970
                
                for (deviceId, value) in json {
                    if deviceId == self.myDeviceId { continue }
                    
                    if let dict = value as? [String: Any],
                       let isWorking = dict["isWorking"] as? Bool,
                       let lastUpdated = dict["lastUpdated"] as? Double {
                        
                        if isWorking && (now - lastUpdated) < 86400 {
                            foundActiveCoworker = true
                            break
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.isCoworkerActive = foundActiveCoworker
                }
            } else {
                DispatchQueue.main.async {
                    self.isCoworkerActive = false
                }
            }
        }.resume()
    }
    
    func cleanup() {
        deleteMyStatus()
    }
}

