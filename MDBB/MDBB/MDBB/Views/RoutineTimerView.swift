import SwiftUI

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
                    VStack(spacing: 24) {
                        Text(currentTask.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 16)
                                .frame(width: 200, height: 200)
                            Circle()
                                .trim(from: 0, to: CGFloat(timeRemaining / max(currentTask.duration, 1)))
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 200, height: 200)
                                .animation(didAppear ? .linear(duration: 1) : nil, value: timeRemaining)
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            markTaskDoneAndNext()
                        }) {
                            HStack {
                                Image(systemName: completedTaskIndices.contains(currentTaskIndex) ? "checkmark.circle.fill" : "circle")
                                    .font(.title)
                                    .foregroundColor(completedTaskIndices.contains(currentTaskIndex) ? .green : .gray)
                                Text(completedTaskIndices.contains(currentTaskIndex) ? "Done" : "Mark as Done")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(20)
                        }
                    }
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
    }
    
    private func markTaskDoneAndNext() {
        completedTaskIndices.insert(currentTaskIndex)
        nextTaskOrFinish()
    }
    
    private func startTask() {
        guard let currentTask = routine.tasks[safe: currentTaskIndex] else { return }
        timeRemaining = currentTask.duration
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
            startTask()
        } else {
            isComplete = true
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