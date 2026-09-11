import SwiftUI

struct ParticleState: Identifiable {
    let id = UUID()
    var xOffset: CGFloat
    var yOffset: CGFloat
    var scale: CGFloat
    var opacity: Double
    let symbol: String
}

struct TreatParticleView: View {
    @State private var particles: [ParticleState] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.symbol)
                    .font(.system(size: 20))
                    .scaleEffect(p.scale)
                    .opacity(p.opacity)
                    .offset(x: p.xOffset, y: p.yOffset)
            }
        }
        .onAppear {
            setupParticles()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animateParticles()
            }
        }
    }
    
    private func setupParticles() {
        let symbols = ["❤️", "⭐", "✨"]
        particles = (0..<6).map { _ in
            ParticleState(
                xOffset: .random(in: -10...10),
                yOffset: 0,
                scale: 0.2,
                opacity: 1.0,
                symbol: symbols.randomElement()!
            )
        }
    }
    
    private func animateParticles() {
        for i in 0..<particles.count {
            let delay = Double.random(in: 0...0.2)
            withAnimation(.easeOut(duration: 1.2).delay(delay)) {
                particles[i].xOffset += CGFloat.random(in: -30...30)
                particles[i].yOffset -= CGFloat.random(in: 40...80)
                particles[i].scale = CGFloat.random(in: 0.8...1.5)
                particles[i].opacity = 0
            }
        }
    }
}
