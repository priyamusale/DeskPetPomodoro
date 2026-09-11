import SwiftUI

struct PetOverlayView: View {
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var petPreferences: PetPreferencesStore
    @EnvironmentObject var pomodoroVM: PomodoroViewModel
    @EnvironmentObject var coworkingVM: CoworkingViewModel
    @Environment(\.openWindow) var openWindow
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            
            PetCanvasView(
                variant: petPreferences.selectedVariant,
                frameIndex: petVM.walkFrame,
                facingRight: true,
                isSleeping: petVM.isSleeping
            )
            .frame(width: 72, height: 72)
            .scaleEffect(pulseScale)
            .onChange(of: petVM.showTreat) { newValue in
                if newValue {
                    // Scale up
                    withAnimation(.easeOut(duration: 0.15)) {
                        pulseScale = 1.3
                    }
                    // Scale back down explicitly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            pulseScale = 1.0
                        }
                    }
                }
            }
            .background(Color.white.opacity(0.001))
            .contentShape(Rectangle())
            .onTapGesture {
                openWindow(id: "PomodoroWindow")
                NSApp.activate(ignoringOtherApps: true)
                NotificationCenter.default.post(name: Notification.Name("showPomodoroTimer"), object: nil)
                // If sleeping, tapping also wakes it up (handled if timer starts, but we can immediately wake it)
                if petVM.isSleeping {
                    petVM.isSleeping = false
                    petVM.showSpeech("Hi Priya!")
                }
            }
            
            if petVM.showTreat {
                TreatParticleView()
                    .frame(width: 100, height: 100)
                    .offset(y: -40)
            }
            
            if let message = petVM.speechMessage {
                SpeechBubbleView(text: message)
                    .offset(y: -60) // Position above the pet
                    // Add a gentle pop-in animation
                    .transition(AnyTransition.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: petVM.speechMessage)
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
        .frame(width: 140, height: 140)
    }
}
import SwiftUI

struct SpeechBubbleView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                SpeechBubbleShape()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            )
            // Padding so the shadow and tail don't get clipped
            .padding(.bottom, 12)
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
