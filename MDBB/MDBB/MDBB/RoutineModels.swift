import Foundation
import SwiftUI

struct Task: Identifiable, Codable {
    var id = UUID()
    var name: String
    var duration: TimeInterval
    var icon: String
    var color: String
    var order: Int
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Routine: Identifiable, Codable {
    var id = UUID()
    var name: String
    var tasks: [Task]
    var streak: Int
    var lastCompleted: Date?
    var createdAt: Date
    var isActive: Bool
    
    var totalDuration: TimeInterval {
        tasks.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class RoutineStore: ObservableObject {
    @Published var routines: [Routine] = []
    
    func addRoutine(_ routine: Routine) {
        print("[DEBUG] Adding routine: \(routine.name), tasks: \(routine.tasks.count)")
        routines.append(routine)
        print("[DEBUG] Current routines: \(routines.map { $0.name })")
        saveRoutines()
    }
    
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            print("[DEBUG] Updating routine: \(routine.name)")
            routines[index] = routine
            saveRoutines()
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        print("[DEBUG] Deleting routine: \(routine.name)")
        routines.removeAll { $0.id == routine.id }
        saveRoutines()
    }
    
    private func saveRoutines() {
        // TODO: Implement persistence
    }
    
    private func loadRoutines() {
        // TODO: Implement loading from persistence
    }
}

struct RoutineDetailView: View {
    @State var routine: Routine
    @ObservedObject var routineStore: RoutineStore
    @State private var showingAddTask = false
    @State private var isRunning = false
    @State private var currentTaskIndex = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer? = nil
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemBackground)
                .opacity(0.01)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Header with back button and title
                HStack(spacing: 12) {
                    if let onBack = onBack {
                        Button(action: onBack) {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    Text(routine.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Spacer()
                }
                .padding(.top, 44)
                .padding(.horizontal)
                
                // Tasks List (List)
                List {
                    ForEach(routine.tasks) { task in
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                            Text(task.name)
                                .foregroundColor(.white)
                        }
                    }
                    // Add New Task Button
                    Button(action: { showingAddTask = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.white)
                            Text("Add New Task")
                                .foregroundColor(.white)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .background(Color.clear)
                .listRowBackground(Color.clear)
                
                // Show current task and timer if running
                if isRunning, let currentTask = routine.tasks[safe: currentTaskIndex] {
                    VStack(spacing: 8) {
                        Text("Current Task: \(currentTask.name)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            
            // Floating Start Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if !isRunning {
                            startRoutine()
                        }
                    }) {
                        Text(isRunning ? "Running..." : "Start")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(width: 180)
                            .background(isRunning ? Color.gray : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 32)
                    .padding(.trailing, 24)
                    .disabled(isRunning)
                }
            }
        }
        .onAppear {
            UITableView.appearance().backgroundColor = .clear
        }
        .onDisappear {
            UITableView.appearance().backgroundColor = nil
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startRoutine() {
        guard !routine.tasks.isEmpty else { return }
        isRunning = true
        currentTaskIndex = 0
        timeRemaining = routine.tasks[0].duration
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                nextTaskOrFinish()
            }
        }
    }
    
    private func nextTaskOrFinish() {
        if currentTaskIndex < routine.tasks.count - 1 {
            currentTaskIndex += 1
            timeRemaining = routine.tasks[currentTaskIndex].duration
        } else {
            timer?.invalidate()
            timer = nil
            isRunning = false
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Safe subscript for arrays
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 
