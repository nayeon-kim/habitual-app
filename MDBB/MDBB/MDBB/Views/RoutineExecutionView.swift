import SwiftUI

struct RoutineExecutionView: View {
    let routine: Routine
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var routineStore: RoutineStore
    
    @State private var currentTaskIndex = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    
    var currentTask: Task? {
        guard currentTaskIndex < routine.tasks.count else { return nil }
        return routine.tasks[currentTaskIndex]
    }
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: Theme.padding) {
                // Progress
                ProgressView(value: Double(currentTaskIndex), total: Double(routine.tasks.count))
                    .tint(Theme.accent)
                    .padding()
                
                if let task = currentTask {
                    // Current Task
                    VStack(spacing: Theme.padding) {
                        Image(systemName: task.icon)
                            .font(.system(size: 60))
                            .foregroundColor(Color(task.color))
                        
                        Text(task.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.text)
                        
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(Theme.text)
                            .monospacedDigit()
                        
                        HStack(spacing: Theme.padding) {
                            Button(action: previousTask) {
                                Image(systemName: "backward.fill")
                                    .font(.title)
                            }
                            .disabled(currentTaskIndex == 0)
                            
                            Button(action: toggleTimer) {
                                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 60))
                            }
                            
                            Button(action: nextTask) {
                                Image(systemName: "forward.fill")
                                    .font(.title)
                            }
                            .disabled(currentTaskIndex == routine.tasks.count - 1)
                        }
                        .foregroundColor(Theme.accent)
                    }
                    .padding()
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadius)
                    .padding()
                } else {
                    // Completion View
                    VStack(spacing: Theme.padding) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.success)
                        
                        Text("Routine Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.text)
                        
                        Button("Done") {
                            completeRoutine()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                    }
                    .padding()
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadius)
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End") {
                    dismiss()
                }
            }
        }
        .onAppear {
            if let task = currentTask {
                timeRemaining = task.duration
            }
        }
    }
    
    private func toggleTimer() {
        isRunning.toggle()
        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    nextTask()
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func nextTask() {
        if currentTaskIndex < routine.tasks.count - 1 {
            currentTaskIndex += 1
            if let task = currentTask {
                timeRemaining = task.duration
            }
        } else {
            completeRoutine()
        }
    }
    
    private func previousTask() {
        if currentTaskIndex > 0 {
            currentTaskIndex -= 1
            if let task = currentTask {
                timeRemaining = task.duration
            }
        }
    }
    
    private func completeRoutine() {
        var updatedRoutine = routine
        updatedRoutine.streak += 1
        updatedRoutine.lastCompleted = Date()
        routineStore.updateRoutine(updatedRoutine)
        dismiss()
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct RoutineExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RoutineExecutionView(
                routine: Routine(
                    name: "Morning Routine",
                    tasks: [
                        Task(name: "Brush Teeth", duration: 120, icon: "tooth", color: "blue", order: 0),
                        Task(name: "Shower", duration: 300, icon: "shower", color: "green", order: 1)
                    ],
                    streak: 0,
                    lastCompleted: nil,
                    createdAt: Date(),
                    isActive: true
                ),
                routineStore: RoutineStore()
            )
        }
    }
} 