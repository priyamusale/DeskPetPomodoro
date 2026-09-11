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
