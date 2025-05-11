import SwiftUI

struct RoutineTimerView: View {
    let routine: Routine
    @Binding var completedTaskIndices: Set<Int>
    var onClose: () -> Void
    @State private var currentTaskIndex: Int = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var isComplete: Bool = false
    @State private var didAppear = false
    
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
                    Button(action: onClose) {
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
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text("Routine Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
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
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
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
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
} 