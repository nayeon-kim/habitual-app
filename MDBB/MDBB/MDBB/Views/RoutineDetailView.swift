import SwiftUI

struct RoutineDetailView: View {
    @State var routine: Routine
    @ObservedObject var routineStore: RoutineStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTask = false
    @State private var isRunning = false
    @State private var currentTaskIndex = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var showingTimer = false
    @State private var completedTaskIndices: Set<Int> = []
    var onBack: (() -> Void)? = nil
    
    private var shouldResetCompletionState: Bool {
        guard let lastCompleted = routine.lastCompleted else { return true }
        return !Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }
    
    private func loadCompletionState() {
        // If the routine was completed today, mark all tasks as completed
        if let lastCompleted = routine.lastCompleted,
           Calendar.current.isDate(lastCompleted, inSameDayAs: Date()) {
            completedTaskIndices = Set(0..<routine.tasks.count)
        } else {
            completedTaskIndices = []
        }
    }
    
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
                    ForEach(Array(routine.tasks.enumerated()), id: \.offset) { index, task in
                        HStack {
                            Button(action: {
                                toggleTaskCompletion(index: index)
                            }) {
                                if completedTaskIndices.contains(index) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            Text(task.name)
                                .foregroundColor(.white)
                            Spacer()
                            Text(task.formattedDuration)
                                .foregroundColor(.white)
                                .font(.subheadline)
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
                        showingTimer = true
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
        .sheet(isPresented: $showingAddTask) {
            AddTaskView { task in
                var updatedRoutine = routine
                updatedRoutine.tasks.append(task)
                routine = updatedRoutine
                routineStore.updateRoutine(updatedRoutine)
            }
        }
        .fullScreenCover(isPresented: $showingTimer) {
            RoutineTimerView(
                routine: routine,
                completedTaskIndices: $completedTaskIndices,
                onClose: {
                    showingTimer = false
                }
            )
        }
        .onAppear {
            UITableView.appearance().backgroundColor = .clear
            loadCompletionState()
        }
        .onDisappear {
            UITableView.appearance().backgroundColor = nil
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func toggleTaskCompletion(index: Int) {
        if completedTaskIndices.contains(index) {
            completedTaskIndices.remove(index)
        } else {
            completedTaskIndices.insert(index)
            
            // Check if all tasks are completed
            if completedTaskIndices.count == routine.tasks.count {
                var updatedRoutine = routine
                updatedRoutine.streak += 1
                updatedRoutine.lastCompleted = Date()
                updatedRoutine.completionDates.append(Date())
                routineStore.updateRoutine(updatedRoutine)
                routine = updatedRoutine
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
} 