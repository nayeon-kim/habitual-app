import SwiftUI

struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var routineStore: RoutineStore
    
    @State private var routineName = ""
    @State private var tasks: [Task] = []
    @State private var showingAddTask = false
    @FocusState private var nameFieldIsFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.padding) {
                        // Routine Name
                        TextField("Routine Name", text: $routineName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .focused($nameFieldIsFocused)
                        
                        // Tasks List
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, task in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 4)
                                TaskRow(task: task)
                            }
                        }
                        .onMove { indices, newOffset in
                            tasks.move(fromOffsets: indices, toOffset: newOffset)
                        }
                        
                        // Add Task Button
                        Button(action: { showingAddTask = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Task")
                            }
                            .foregroundColor(Theme.accent)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadius)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                    Button("Save") {
                        saveRoutine()
                    }
                    .disabled(routineName.isEmpty || tasks.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView { task in
                    tasks.append(task)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    nameFieldIsFocused = true
                }
            }
        }
    }
    
    private func saveRoutine() {
        let routine = Routine(
            name: routineName,
            tasks: tasks,
            streak: 0,
            lastCompleted: nil,
            createdAt: Date(),
            isActive: true
        )
        routineStore.addRoutine(routine)
        dismiss()
    }
}

struct TaskRow: View {
    let task: Task
    
    var body: some View {
        HStack {
            Image(systemName: task.icon)
                .foregroundColor(Color(task.color))
                .frame(width: 30)
            
            Text(task.name)
                .foregroundColor(Theme.text)
            
            Spacer()
            
            Text(task.formattedDuration)
                .foregroundColor(Theme.textSecondary)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
        .padding(.horizontal)
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Task) -> Void
    
    @State private var taskName = ""
    @State private var duration: TimeInterval = 300 // 5 minutes
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "blue"
    @FocusState private var taskNameFieldIsFocused: Bool
    
    let icons = ["star.fill", "heart.fill", "moon.fill", "sun.max.fill", "cloud.fill", "leaf.fill"]
    let colors = ["blue", "red", "green", "purple", "orange", "pink"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName)
                        .focused($taskNameFieldIsFocused)
                    
                    Stepper("Duration: \(Int(duration/60)) minutes", value: $duration, in: 60...3600, step: 60)
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))]) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title)
                                .foregroundColor(selectedIcon == icon ? Color(selectedColor) : .gray)
                                .padding()
                                .background(selectedIcon == icon ? Color(selectedColor).opacity(0.2) : Color.clear)
                                .cornerRadius(Theme.cornerRadius)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))]) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let task = Task(
                            name: taskName,
                            duration: duration,
                            icon: selectedIcon,
                            color: selectedColor,
                            order: 0
                        )
                        onSave(task)
                        dismiss()
                    }
                    .disabled(taskName.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    taskNameFieldIsFocused = true
                }
            }
        }
    }
}

struct AddRoutineView_Previews: PreviewProvider {
    static var previews: some View {
        AddRoutineView(routineStore: RoutineStore())
    }
} 