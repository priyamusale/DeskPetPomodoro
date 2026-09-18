import SwiftUI

struct PetOverlayView: View {
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var petPreferences: PetPreferencesStore
    @EnvironmentObject var pomodoroVM: PomodoroViewModel
    @EnvironmentObject var coworkingVM: CoworkingViewModel
    @ObservedObject var distractionMonitor = DistractionMonitor.shared
    @Environment(\.openWindow) var openWindow
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Speech bubble lives here — ABOVE the pet, in unconstrained space
            if let message = petVM.speechMessage {
                HStack {
                    SpeechBubbleView(text: message)
                        .transition(AnyTransition.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: petVM.speechMessage)
                    Spacer()
                }
                // 38 = 34px (off-screen window offset) + 4px margin
                .padding(.leading, 38)
            } else {
                Spacer().frame(height: 4)
            }
            
            // Timer badges
            let showDistractionTimer = distractionMonitor.consecutiveDistractedSeconds > 0
            if showDistractionTimer {
                let mins = distractionMonitor.consecutiveDistractedSeconds / 60
                let secs = distractionMonitor.consecutiveDistractedSeconds % 60
                let timerText = mins > 0 ? "\(mins)m \(String(format: "%02d", secs))s" : "\(secs)s"
                HStack {
                    Text(timerText)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(6)
                        .shadow(radius: 2)
                    Spacer()
                }
                .padding(.leading, 38)
            } else if pomodoroVM.isRunning {
                HStack {
                    Text(pomodoroVM.timePassedString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(pomodoroVM.phase == .work ? Color(hex: "#4A4A4A") : .blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(6)
                        .shadow(radius: 2)
                    Spacer()
                }
                .padding(.leading, 38)
            }
            
            // Pet canvas — fixed 140 width, 80 height to remove gap
            ZStack(alignment: .bottom) {
                
                PetCanvasView(
                    variant: petPreferences.selectedVariant,
                    frameIndex: petVM.walkFrame,
                    facingRight: petVM.facingRight,
                    isSleeping: petVM.isSleeping
                )
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(petVM.walkRotation))
                .animation(.easeInOut(duration: 3.0), value: petVM.walkRotation)
                .scaleEffect(pulseScale)
                .onChange(of: petVM.showTreat) { newValue in
                    if newValue {
                        withAnimation(.easeOut(duration: 0.15)) { pulseScale = 1.3 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { pulseScale = 1.0 }
                        }
                    }
                }
                .background(Color.white.opacity(0.001))
                .contentShape(Rectangle())
                .onTapGesture {
                    openWindow(id: "PomodoroWindow")
                    NSApp.activate(ignoringOtherApps: true)
                    NotificationCenter.default.post(name: Notification.Name("showPomodoroTimer"), object: nil)
                    if petVM.isSleeping {
                        petVM.isSleeping = false
                        petVM.showSpeech("Hi \(petVM.userFirstName)!")
                    }
                }
                
                if petVM.showTreat {
                    TreatParticleView()
                        .frame(width: 100, height: 100)
                        .offset(y: -40)
                }
                
                if coworkingVM.isCoworkerActive {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 18))
                        .offset(x: 0, y: -50)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: coworkingVM.isCoworkerActive)
                }
            }
            .frame(width: 140, height: 80)
        }
        .frame(width: 280, height: 200, alignment: .bottomLeading)
    }
}


struct SpeechBubbleView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.black)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                SpeechBubbleShape()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            )
            .padding(.bottom, 12)
            .fixedSize() // prevent parent from squishing it
    }
}

struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerRadius: CGFloat = 8
        let tailWidth: CGFloat = 10
        let tailHeight: CGFloat = 10
        let tailOffset: CGFloat = rect.width / 2 - (tailWidth / 2)
        
        // Define the main rectangle
        let bubbleRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        
        // Start drawing from top left
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        path.addLine(to: CGPoint(x: bubbleRect.width - cornerRadius, y: 0))
        path.addArc(center: CGPoint(x: bubbleRect.width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        
        path.addLine(to: CGPoint(x: bubbleRect.width, y: bubbleRect.height - cornerRadius))
        path.addArc(center: CGPoint(x: bubbleRect.width - cornerRadius, y: bubbleRect.height - cornerRadius), radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        // Bottom edge with tail
        path.addLine(to: CGPoint(x: tailOffset + tailWidth, y: bubbleRect.height))
        path.addLine(to: CGPoint(x: tailOffset + (tailWidth / 2), y: bubbleRect.height + tailHeight))
        path.addLine(to: CGPoint(x: tailOffset, y: bubbleRect.height))
        
        path.addLine(to: CGPoint(x: cornerRadius, y: bubbleRect.height))
        path.addArc(center: CGPoint(x: cornerRadius, y: bubbleRect.height - cornerRadius), radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        
        path.closeSubpath()
        return path
    }
}
