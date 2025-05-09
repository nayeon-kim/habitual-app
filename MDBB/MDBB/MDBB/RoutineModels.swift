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
    @Published var routines: [Routine] = [] {
        didSet {
            saveRoutines()
        }
    }
    
    private let routinesFile = "routines.json"
    
    init() {
        loadRoutines()
    }
    
    func addRoutine(_ routine: Routine) {
        print("[DEBUG] Adding routine: \(routine.name), tasks: \(routine.tasks.count)")
        routines.append(routine)
        print("[DEBUG] Current routines: \(routines.map { $0.name })")
        // saveRoutines() now handled by didSet
    }
    
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            print("[DEBUG] Updating routine: \(routine.name)")
            routines[index] = routine
            // saveRoutines() now handled by didSet
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        print("[DEBUG] Deleting routine: \(routine.name)")
        routines.removeAll { $0.id == routine.id }
        // saveRoutines() now handled by didSet
    }
    
    private func saveRoutines() {
        do {
            let data = try JSONEncoder().encode(routines)
            let url = getDocumentsDirectory().appendingPathComponent(routinesFile)
            try data.write(to: url)
            print("[DEBUG] Routines saved to \(url)")
        } catch {
            print("[ERROR] Failed to save routines: \(error)")
        }
    }
    
    private func loadRoutines() {
        let url = getDocumentsDirectory().appendingPathComponent(routinesFile)
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Routine].self, from: data)
            routines = decoded
            print("[DEBUG] Routines loaded from \(url)")
        } catch {
            print("[DEBUG] No routines file found or failed to load: \(error)")
            routines = []
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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
    @State private var showingTimer = false
    @State private var completedTaskIndices: Set<Int> = []
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
            AddTaskView { newTask in
                var updatedRoutine = routine
                updatedRoutine.tasks.append(newTask)
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
            completedTaskIndices = []
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
    
    private func toggleTaskCompletion(index: Int) {
        if completedTaskIndices.contains(index) {
            completedTaskIndices.remove(index)
        } else {
            completedTaskIndices.insert(index)
        }
    }
}

// Safe subscript for arrays
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// --- Full Screen Timer View ---
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
