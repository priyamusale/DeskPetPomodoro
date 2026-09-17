import SwiftUI

enum PlannerTab: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case goals = "Goals"
}

struct MainWindowView: View {
    @State private var showingSettings = false
    @State private var selectedTab: PlannerTab = .daily
    @EnvironmentObject var pomodoroVM: PomodoroViewModel
    
    var body: some View {
        ZStack {
            if let img = NSImage(named: "desk_background.jpg") ?? NSImage(named: "desk_background") {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color(hex: "#C68E58").ignoresSafeArea() // Fallback
            }
            
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                
                let todoWidth = min(300, w * 0.25)
                let todoHeight = min(500, h * 0.75)
                
                let plannerWidth = min(460, w * 0.40)
                let plannerHeight = min(710, h * 0.95)
                
                let timerSize = min(320, min(w * 0.28, h * 0.5))
                
                HStack(alignment: .center, spacing: w * 0.02) {
                    Spacer(minLength: w * 0.02)
                    
                    TodoPanelView()
                        .frame(width: todoWidth, height: todoHeight)
                        .rotationEffect(.degrees(-1.5))
                        .offset(y: h * 0.05)
                    
                    ZStack {
                        // Notebook Content
                        ZStack {
                            switch selectedTab {
                            case .daily:
                                DailyPlannerView()
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            case .weekly:
                                WeeklyPlannerView()
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            case .monthly:
                                MonthlyPlannerView()
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            case .goals:
                                GoalsPanelView()
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.4), value: selectedTab)
                        .clipShape(RoundedRectangle(cornerRadius: 12)) // So sliding doesn't spill out
                        
                        // Tabs on the right edge
                        VStack(spacing: 8) {
                            ForEach(PlannerTab.allCases, id: \.self) { tab in
                                Button(action: {
                                    withAnimation {
                                        selectedTab = tab
                                    }
                                }) {
                                    Text(tab.rawValue)
                                        .font(.dawning(size: 16))
                                        .foregroundColor(.black)
                                        .frame(width: 80, height: 30)
                                        .background(selectedTab == tab ? Color(hex: "#FFED99") : Color.white)
                                        .border(Color.black.opacity(0.1), width: 1)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 2, y: 2)
                                }
                                .buttonStyle(.plain)
                                .offset(x: selectedTab == tab ? 5 : 0) // slightly stick out if selected
                            }
                        }
                        .offset(x: plannerWidth / 2 + 40, y: -plannerHeight / 4)
                        .zIndex(-1) // Behind the main notebook so they look like tabs sticking out
                    }
                    .frame(width: plannerWidth, height: plannerHeight)
                    .rotationEffect(.degrees(0.5))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 2, y: 4)
                    .padding(.trailing, 80) // Increased to give more space for sticky tabs
                    
                    VStack {
                        TimerPanelView()
                            .frame(width: timerSize, height: timerSize)
                            .rotationEffect(.degrees(1.0))
                            .padding(.top, 24)
                            .offset(y: h * 0.05)
                        
                        Spacer()
                        
                        ProgressWidgetView()
                            .frame(width: timerSize, height: timerSize * 0.6)
                            .rotationEffect(.degrees(-0.5))
                    }
                    .frame(height: plannerHeight)
                    .padding(.leading, 15)
                    
                    Spacer(minLength: w * 0.02)
                }
                .frame(width: w, height: h)
            }
        }
        .environment(\.colorScheme, .light)
        .sheet(isPresented: $showingSettings) {
            PetPickerView()
                .environmentObject(pomodoroVM)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowSettings"))) { _ in
            showingSettings = true
        }
    }
}

struct DeskBackgroundView: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            
            // Base warm wood color
            context.fill(Path(rect), with: .color(Color(hex: "#C68E58")))
            
            // Subtle grain lines
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                
                var x: CGFloat = 0
                while x < size.width {
                    x += CGFloat.random(in: 40...100)
                    let yOffset = CGFloat.random(in: -2...2)
                    path.addLine(to: CGPoint(x: x, y: y + yOffset))
                }
                
                context.stroke(path, with: .color(Color(hex: "#B07946").opacity(0.4)), lineWidth: 1)
                y += CGFloat.random(in: 4...12)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ProgressWidgetView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROGRESS TRACKER")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A"))
            
            if goalsVM.longTermGoals.isEmpty {
                Text("No long-term goals yet.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(goalsVM.longTermGoals, id: \.id) { goal in
                            HStack(spacing: 12) {
                                Text(goal.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#4A4A4A"))
                                    .lineLimit(1)
                                    .frame(width: 100, alignment: .leading)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.black.opacity(0.1))
                                        
                                        // Red if falling behind, otherwise Green
                                        let isBehind = (goal.expectedProgressPercentage - goal.progressPercentage) > 0.05
                                        let barColor: Color = isBehind ? .red : .green
                                        
                                        Capsule().fill(
                                            LinearGradient(gradient: Gradient(colors: [barColor.opacity(0.7), barColor]), startPoint: .leading, endPoint: .trailing)
                                        )
                                        .frame(width: max(0, geo.size.width * CGFloat(goal.progressPercentage)))
                                    }
                                }
                                .frame(height: 10)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        // Pastel Yellow widget background
        .background(Color(hex: "#FFFACD")) 
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 2, y: 3)
    }
}

struct CoworkingPanelView: View {
    @EnvironmentObject var coworkingVM: CoworkingViewModel
    @State private var roomCodeInput: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Text("COWORKING")
                    .font(.kristi(size: 48))
                    .foregroundColor(Color(hex: "#2A2A2A"))
                    .padding(.top, 24)
                Spacer()
            }
            .padding(.bottom, 16)
            
            if coworkingVM.isConnected {
                VStack(spacing: 16) {
                    Text("You are connected to room:")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Text(coworkingVM.roomCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Text(coworkingVM.isCoworkerActive ? "Someone is working right now!" : "Nobody is currently working.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(coworkingVM.isCoworkerActive ? .green : .orange)
                        .padding(.top, 8)
                    
                    Button(action: {
                        coworkingVM.leaveRoom()
                    }) {
                        Text("LEAVE ROOM")
                            .font(.kristi(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 140, height: 40)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                }
            } else {
                VStack(spacing: 16) {
                    Text("Enter a room code to connect with your husband.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("Room Code (e.g., HOUSE)", text: $roomCodeInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(width: 200)
                    
                    Button(action: {
                        coworkingVM.joinRoom(roomCodeInput)
                    }) {
                        Text("JOIN ROOM")
                            .font(.kristi(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 44)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#FAFAFA"))
    }
}

