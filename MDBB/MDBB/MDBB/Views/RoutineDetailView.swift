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
    @State private var showingEditRoutine = false
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
            Theme.background
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
                    Button(action: { showingEditRoutine = true }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
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
                .scrollContentBackground(.hidden)
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
                            .background(isRunning ? Color.gray : Color(red: 70/255, green: 20/255, blue: 172/255))
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
        .sheet(isPresented: $showingEditRoutine) {
            EditRoutineView(routine: $routine, routineStore: routineStore)
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

struct EditRoutineView: View {
    @Binding var routine: Routine
    @ObservedObject var routineStore: RoutineStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFieldIsFocused: Bool
    @State private var editedName: String = ""
    @State private var editedTasks: [Task] = []
    @State private var editingTaskIndex: Int? = nil
    @State private var editingTaskName: String = ""
    @State private var editingTaskDuration: TimeInterval = 300
    @State private var showDeleteAlert = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Routine Name")) {
                    TextField("Routine Name", text: $editedName)
                        .focused($nameFieldIsFocused)
                }
                Section(header: Text("Tasks")) {
                    ForEach(Array(editedTasks.enumerated()), id: \.element.id) { idx, task in
                        if editingTaskIndex == idx {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Task Name", text: $editingTaskName)
                                Stepper("Duration: \(Int(editingTaskDuration/60)) min", value: $editingTaskDuration, in: 60...3600, step: 60)
                                HStack {
                                    Button("Save") {
                                        var updated = task
                                        updated.name = editingTaskName
                                        updated.duration = editingTaskDuration
                                        editedTasks[idx] = updated
                                        editingTaskIndex = nil
                                    }
                                    .buttonStyle(.borderedProminent)
                                    Button("Cancel") {
                                        editingTaskIndex = nil
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(task.name)
                                    Text("\(Int(task.duration/60)) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    editingTaskIndex = idx
                                    editingTaskName = task.name
                                    editingTaskDuration = task.duration
                                }) {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.plain)
                                Button(action: {
                                    editedTasks.remove(at: idx)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Routine")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        routine.name = editedName
                        routine.tasks = editedTasks
                        routineStore.updateRoutine(routine)
                        dismiss()
                    }
                    .disabled(editedName.isEmpty || editedTasks.isEmpty)
                }
            }
            .onAppear {
                editedName = routine.name
                editedTasks = routine.tasks
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    nameFieldIsFocused = true
                }
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Routine?"),
                    message: Text("Are you sure you want to delete \(routine.name)?"),
                    primaryButton: .destructive(Text("Delete")) {
                        routineStore.deleteRoutine(routine)
                        dismiss()
                        onDelete?()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
} 