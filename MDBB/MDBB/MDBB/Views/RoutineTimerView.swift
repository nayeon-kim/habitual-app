import SwiftUI
import UIKit

struct RoutineTimerView: View {
    let routine: Routine
    @Binding var completedTaskIndices: Set<Int>
    var onClose: () -> Void
    var onComplete: (() -> Void)? = nil
    @State private var currentTaskIndex: Int = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var isComplete: Bool = false
    @State private var didAppear = false
    @State private var autoDismissWorkItem: DispatchWorkItem? = nil
    @State private var completionRingProgress: CGFloat = 0.0
    @State private var didCallOnComplete = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var backgroundEnteredAt: Date? = nil
    
    private var nextTask: Task? {
        routine.tasks[safe: currentTaskIndex + 1]
    }
    
    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea() // TEMP: Should see a red background
            LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        print("[DEBUG] Close button tapped. isComplete=\(isComplete), didCallOnComplete=\(didCallOnComplete)")
                        if isComplete && !didCallOnComplete {
                            print("[DEBUG] Calling onComplete from close button")
                            didCallOnComplete = true
                            onComplete?()
                        }
                        print("[DEBUG] Calling onClose from close button")
                        onClose()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 44)
                .padding(.horizontal)
                
                Spacer()
                
                if isComplete {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 10)
                                .frame(width: 110, height: 110)
                            Circle()
                                .trim(from: 0, to: completionRingProgress)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 110, height: 110)
                                .animation(.easeInOut(duration: 1), value: completionRingProgress)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        }
                        Text("Routine Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if let currentTask = routine.tasks[safe: currentTaskIndex] {
                    VStack(spacing: 8) {
                        Spacer(minLength: 0)
                        Text(currentTask.name)
                            .font(.system(size: 32, weight: .bold))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        if let nextTask = nextTask {
                            HStack(spacing: 8) {
                                Text("Up Next: \(nextTask.name)")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(nextTask.formattedDuration)
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        Spacer().frame(height: 24)
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 16)
                                .frame(width: 200, height: 200)
                            Circle()
                                .trim(from: 0, to: CGFloat(timeRemaining / max(currentTask.duration, 1)))
                                .stroke(Color(hex: "#C2FF5D"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 200, height: 200)
                                .animation(didAppear ? .linear(duration: 1) : nil, value: timeRemaining)
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        Spacer().frame(height: 24)
                        HStack(spacing: 0) {
                            Button(action: {
                                markTaskDoneAndNext()
                            }) {
                                HStack {
                                    Image(systemName: completedTaskIndices.contains(currentTaskIndex) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 28))
                                        .foregroundColor(completedTaskIndices.contains(currentTaskIndex) ? Color(hex: "#C2FF5D") : .white.opacity(0.7))
                                    Text(completedTaskIndices.contains(currentTaskIndex) ? "Done" : "Mark as done")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .frame(maxWidth: .infinity, minHeight: 56)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxHeight: .infinity)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startTask()
            DispatchQueue.main.async {
                didAppear = true
            }
            autoDismissWorkItem?.cancel()
            if isComplete {
                completionRingProgress = 0.0
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 1)) {
                        completionRingProgress = 1.0
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            autoDismissWorkItem?.cancel()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                backgroundEnteredAt = Date()
                timer?.invalidate()
            } else if newPhase == .active, let backgroundDate = backgroundEnteredAt {
                let elapsed = Date().timeIntervalSince(backgroundDate)
                backgroundEnteredAt = nil
                timeRemaining = max(0, timeRemaining - elapsed)
                if !isComplete, routine.tasks[safe: currentTaskIndex] != nil, timeRemaining > 0 {
                    startTask()
                } else if !isComplete, timeRemaining <= 0 {
                    nextTaskOrFinish()
                }
            }
        }
    }
    
    private func markTaskDoneAndNext() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        completedTaskIndices.insert(currentTaskIndex)
        nextTaskOrFinish()
    }
    
    private func startTask() {
        guard let currentTask = routine.tasks[safe: currentTaskIndex] else { return }
        if timeRemaining == 0 {
            timeRemaining = currentTask.duration
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                nextTaskOrFinish()
            }
        }
    }
    
    private func nextTaskOrFinish() {
        timer?.invalidate()
        if currentTaskIndex < routine.tasks.count - 1 {
            currentTaskIndex += 1
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            startTask()
        } else {
            isComplete = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            completionRingProgress = 0.0
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1)) {
                    completionRingProgress = 1.0
                }
            }
            let workItem = DispatchWorkItem {
                withAnimation(.easeInOut(duration: 0.4)) {
                    print("[DEBUG] Auto-dismiss workItem triggered. isComplete=\(isComplete), didCallOnComplete=\(didCallOnComplete)")
                    if !didCallOnComplete {
                        print("[DEBUG] Calling onComplete from auto-dismiss")
                        didCallOnComplete = true
                        onComplete?()
                    }
                    onClose()
                }
            }
            autoDismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
