//
//  ContentView.swift
//  MDBB
//
//  Created by Nayeon Kim on 5/4/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var routineStore: RoutineStore
    @State private var showingAddRoutine = false
    @State private var currentGreeting: String = ""
    @State private var timer: Timer?
    @State private var selectedRoutine: Routine? = nil
    @State private var showDetail = false
    @Namespace private var cardAnimation
    @State private var showTimer = false
    @State private var timerRoutine: Routine? = nil
    @State private var timerCompletedTaskIndices: Set<Int> = []
    
    private func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<12:
            return "🌞Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "🌝 Good Night"
        }
    }
    
    var body: some View {
        ZStack {
            // First radial gradient (top right, bright purple)
            RadialGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.black.opacity(0.6)]),
                center: .topTrailing,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Second radial gradient (bottom left, deep blue/purple)
            RadialGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.black]),
                center: .bottomLeading,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Greeting
                Text(currentGreeting)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: Theme.padding) {
                        if !routineStore.routines.isEmpty {
                            WeeklyStreakCard(routines: routineStore.routines)
                                .padding(.horizontal, 16)
                        }
                        
                        LazyVStack(spacing: Theme.padding) {
                            ForEach(routineStore.routines) { routine in
                                RoutineCard(
                                    routine: routine,
                                    onPlay: {
                                        timerRoutine = routine
                                        timerCompletedTaskIndices = []
                                        DispatchQueue.main.async {
                                            showTimer = true
                                        }
                                    },
                                    onDetail: {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            selectedRoutine = routine
                                            showDetail = true
                                        }
                                    }
                                )
                                .matchedGeometryEffect(id: routine.id, in: cardAnimation)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                    }
                }
                
                // Large Add Button
                Button(action: { showingAddRoutine = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                        Text("Add New Routine")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Routines")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineView(routineStore: routineStore)
            }
            .onChange(of: showTimer) {}
            .onChange(of: timerRoutine) {}
            .fullScreenCover(isPresented: $showTimer) {
                if let routine = timerRoutine {
                    RoutineTimerView(
                        routine: routine,
                        completedTaskIndices: $timerCompletedTaskIndices,
                        onClose: { showTimer = false },
                        onComplete: {
                            // Mark routine as completed for today
                            let today = Date()
                            let calendar = Calendar.current
                            var updatedRoutine = routine
                            if !updatedRoutine.completionDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
                                updatedRoutine.completionDates.append(today)
                                updatedRoutine.lastCompleted = today
                                updatedRoutine.streak += 1
                                routineStore.updateRoutine(updatedRoutine)
                            }
                        }
                    )
                    .onAppear {
                        print("RoutineTimerView for \(routine.name)")
                    }
                }
            }
            if let routine = selectedRoutine, showDetail {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                ZStack(alignment: .topLeading) {
                    if let latestRoutine = routineStore.routines.first(where: { $0.id == routine.id }) {
                        RoutineDetailView(
                            routine: latestRoutine,
                            routineStore: routineStore,
                            onBack: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showDetail = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    selectedRoutine = nil
                                }
                            }
                        )
                        .matchedGeometryEffect(id: routine.id, in: cardAnimation)
                        .zIndex(2)
                    }
                }
                .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Set initial greeting
            currentGreeting = getTimeBasedGreeting()
            
            // Create timer to update greeting every minute
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentGreeting = getTimeBasedGreeting()
            }
            print("selectedRoutine: \(String(describing: selectedRoutine?.name)), showDetail: \(showDetail)")
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: selectedRoutine) { print("selectedRoutine changed to \(String(describing: $0?.name))") }
        .onChange(of: showDetail) { print("showDetail changed to \($0)") }
    }
}

struct RoutineCard: View {
    let routine: Routine
    var onPlay: (() -> Void)? = nil
    var onDetail: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let playButtonSize: CGFloat = 56
            let horizontalPadding: CGFloat = 16
            let playButtonFrame = CGRect(
                x: geo.size.width - playButtonSize - horizontalPadding,
                y: (geo.size.height - playButtonSize) / 2,
                width: playButtonSize,
                height: playButtonSize
            )

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("\(routine.tasks.count) task\(routine.tasks.count == 1 ? "" : "s") • \(routine.formattedTotalDuration)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: playButtonSize, height: playButtonSize)
                    Image(systemName: "play.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.black)
                        .offset(x: 2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let tapLocation = value.location
                        if playButtonFrame.contains(tapLocation) {
                            onPlay?()
                        } else {
                            onDetail?()
                        }
                    }
            )
        }
        .frame(height: 80)
    }
}

struct WeeklyStreakCard: View {
    let routines: [Routine]
    private let calendar = Calendar.current
    private let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
    private let circlesWidth: CGFloat = 7 * 18
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
    @State private var lastCompleted: [String: Date] = [:]
    @State private var showingSummary = false

    private var weekDates: [Date] {
        let today = Date()
        let startOfWeek = calendar.date(byAdding: .day, value: -((calendar.component(.weekday, from: today) + 5) % 7), to: today)!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }

    private var dateRangeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let startDate = weekDates.first!
        let endDate = weekDates.last!
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dateRangeString)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Button(action: { showingSummary = true }) {
                    HStack(spacing: 8) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text("Weekly progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Spacer()
                HStack(spacing: 3) {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 18)
                    }
                }
                .frame(width: circlesWidth + 18, alignment: .trailing)
            }
            ForEach(routines) { routine in
                HStack {
                    Text(routine.name)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 3) {
                        ForEach(0..<7) { index in
                            let completed = routine.wasCompletedOn(weekDates[index])
                            Circle()
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                                .opacity(completed ? 1.0 : 0.3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completed)
                                .onChange(of: completed) { newValue in
                                    if newValue && calendar.isDateInToday(weekDates[index]) {
                                        let key = "\(routine.id)-\(weekDates[index])"
                                        if lastCompleted[key] != weekDates[index] {
                                            lastCompleted[key] = weekDates[index]
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                        }
                                    }
                                }
                        }
                    }
                    .frame(width: circlesWidth + 18, alignment: .trailing)
                }
            }
        }
        .padding()
        .frame(width: cardWidth)
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingSummary) {
            SummaryView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RoutineStore())
    }
} 
