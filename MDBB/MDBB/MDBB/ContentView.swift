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
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Good Night"
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
                                if selectedRoutine?.id != routine.id || !showDetail {
                                    RoutineCard(routine: routine, onPlay: {
                                        timerRoutine = routine
                                        timerCompletedTaskIndices = []
                                        DispatchQueue.main.async {
                                            showTimer = true
                                        }
                                    })
                                    .matchedGeometryEffect(id: routine.id, in: cardAnimation)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            selectedRoutine = routine
                                            showDetail = true
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding()
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
            .onChange(of: showTimer) { print("showTimer changed to \($0)") }
            .onChange(of: timerRoutine) { print("timerRoutine changed to \(String(describing: $0?.name))") }
            .fullScreenCover(isPresented: $showTimer) {
                if let routine = timerRoutine {
                    RoutineTimerView(
                        routine: routine,
                        completedTaskIndices: $timerCompletedTaskIndices,
                        onClose: { showTimer = false }
                    )
                    .onAppear {
                        print("RoutineTimerView for \(routine.name)")
                    }
                }
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
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
            timer = nil
        }
    }
}

struct RoutineCard: View {
    let routine: Routine
    var onPlay: (() -> Void)? = nil

    var body: some View {
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
            Button(action: { onPlay?() }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                    Image(systemName: "play.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.black)
                        .offset(x: 2)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
    }
}

struct WeeklyStreakCard: View {
    let routines: [Routine]
    private let calendar = Calendar.current
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var weekDates: [Date] {
        let today = Date()
        return (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: -6 + dayOffset, to: today)!
        }
    }
    
    private var dateRangeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let startDate = weekDates.first!
        let endDate = weekDates.last!
        
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.smallPadding) {
            HStack {
                Text("Weekly Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(dateRangeString)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(routines) { routine in
                    HStack(alignment: .center, spacing: 12) {
                        Text(routine.name)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<7) { index in
                                VStack(spacing: 4) {
                                    if routine.wasCompletedOn(weekDates[index]) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 24))
                                    } else {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.05),
                                                        Color.white.opacity(0.1)
                                                    ]),
                                                    center: .center,
                                                    startRadius: 0,
                                                    endRadius: 20
                                                )
                                            )
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                    
                                    Text(weekDays[index])
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RoutineStore())
    }
} 
