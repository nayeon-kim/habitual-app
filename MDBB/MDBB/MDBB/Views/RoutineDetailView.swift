import SwiftUI
import UIKit

struct RoutineDetailView: View {
    let routineId: UUID
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
    @Environment(\.editMode) private var editMode
    var onBack: (() -> Void)? = nil
    
    private var routine: Routine? {
        routineStore.routines.first(where: { $0.id == routineId })
    }
    
    private var shouldResetCompletionState: Bool {
        guard let lastCompleted = routine?.lastCompleted else { return true }
        return !Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }
    
    private func loadCompletionState() {
        guard let routine = routine else { completedTaskIndices = []; return }
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
            if let routine = routine {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with back button and title
                    HStack(spacing: 12) {
                        if let onBack = onBack {
                            Button(action: onBack) {
                                Image(systemName: "arrow.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.2))
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
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                    // Tasks List (List)
                    List {
                        ForEach(Array(routine.tasks.enumerated()), id: \ .element.id) { index, task in
                            HStack {
                                Button(action: {
                                    toggleTaskCompletion(index: index)
                                }) {
                                    if completedTaskIndices.contains(index) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.habitualGreen)
                                            .font(.system(size: 28))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 28))
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
                            .padding(.vertical, 2)
                        }
                        // Add New Task Button
                        Button(action: { showingAddTask = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 28))
                                Text("Add new task")
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
            }
            // Floating Start Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        showingTimer = true
                    }) {
                        Text(isRunning ? "Running..." : "Start")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(width: 180)
                            .background(isRunning ? Color.gray : Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 32)
                    .padding(.trailing, 24)
                    .disabled(isRunning)
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            if let routine = routine {
                AddTaskView { task in
                    var updatedRoutine = routine
                    updatedRoutine.tasks.append(task)
                    routineStore.updateRoutine(updatedRoutine)
                }
            }
        }
        .fullScreenCover(isPresented: $showingTimer) {
            if let routine = routine {
                RoutineTimerView(
                    routine: routine,
                    completedTaskIndices: $completedTaskIndices,
                    onClose: {
                        showingTimer = false
                    },
                    onComplete: {
                        print("[DEBUG] onComplete called for routine: \(routine.name)")
                        // Dismiss detail view first
                        onBack?()
                        // Delay the update so the home screen is visible when the value changes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            var updatedRoutine = routine
                            let today = Date()
                            let calendar = Calendar.current
                            if !updatedRoutine.completionDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
                                print("[DEBUG] Appending today to completionDates for routine: \(routine.name)")
                                updatedRoutine.completionDates.append(today)
                                updatedRoutine.lastCompleted = today
                                updatedRoutine.streak += 1
                                print("[DEBUG] Before updateRoutine: completionDates=\(updatedRoutine.completionDates), lastCompleted=\(String(describing: updatedRoutine.lastCompleted))")
                                routineStore.updateRoutine(updatedRoutine)
                                print("[DEBUG] After updateRoutine: completionDates=\(updatedRoutine.completionDates), lastCompleted=\(String(describing: updatedRoutine.lastCompleted))")
                                completedTaskIndices = []
                            }
                            print("[DEBUG] onComplete finished for routine: \(routine.name)")
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingEditRoutine) {
            if let routine = routine {
                EditRoutineView(
                    routine: .constant(routine),
                    routineStore: routineStore,
                    onDelete: {
                        onBack?()
                    },
                    onSave: {
                        // No need to update local state, will re-fetch from store
                    },
                    isCreation: false
                )
            }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // No EditButton; drag handles are always visible
        }
    }
    
    private func toggleTaskCompletion(index: Int) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        guard let routine = routine else { return }
        var updatedIndices = completedTaskIndices
        if updatedIndices.contains(index) {
            updatedIndices.remove(index)
        } else {
            updatedIndices.insert(index)
            // Check if all tasks are completed
            if updatedIndices.count == routine.tasks.count {
                var updatedRoutine = routine
                updatedRoutine.streak += 1
                updatedRoutine.lastCompleted = Date()
                updatedRoutine.completionDates.append(Date())
                routineStore.updateRoutine(updatedRoutine)
            }
        }
        completedTaskIndices = updatedIndices
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
    @State private var showingAddTask = false
    @Environment(\.editMode) private var editMode
    var onDelete: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil
    var isCreation: Bool = false

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
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 4)
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
                    .onMove { indices, newOffset in
                        editedTasks.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    Button(action: { showingAddTask = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                            Text("Add New Task")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                if !isCreation {
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
            }
            .navigationTitle(isCreation ? "New Routine" : "Edit Routine")
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
                        // Reload from store to ensure parent sees changes
                        if let refreshed = routineStore.routines.first(where: { $0.id == routine.id }) {
                            routine = refreshed
                        }
                        onSave?()
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
            .sheet(isPresented: $showingAddTask) {
                AddTaskView { task in
                    editedTasks.append(task)
                    // Auto-save to routine and store
                    routine.name = editedName
                    routine.tasks = editedTasks
                    routineStore.updateRoutine(routine)
                    if let refreshed = routineStore.routines.first(where: { $0.id == routine.id }) {
                        routine = refreshed
                    }
                }
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Routine?"),
                    message: Text("Are you sure you want to delete \(routine.name)?"),
                    primaryButton: .destructive(Text("Delete")) {
                        routineStore.deleteRoutine(routine)
                        onDelete?()
                        dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
} 
