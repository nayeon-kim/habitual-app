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
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 61/255, green: 12/255, blue: 102/255), Color(red: 120/255, green: 53/255, blue: 150/255)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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
                    .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: Theme.padding) {
                        if !routineStore.routines.isEmpty {
                            WeeklyStreakCard(routines: routineStore.routines)
                        }
                        
                        LazyVStack(spacing: Theme.padding) {
                            ForEach(routineStore.routines) { routine in
                                if selectedRoutine?.id != routine.id || !showDetail {
                                    RoutineCard(routine: routine)
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
                    .background(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.5)]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(Theme.cornerRadius)
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
            
            // Full screen detail view with matched geometry effect
            if let routine = selectedRoutine, showDetail {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                ZStack(alignment: .topLeading) {
                    RoutineDetailView(
                        routine: routine,
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.smallPadding) {
            HStack {
                Text(routine.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(routine.formattedTotalDuration)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack {
                Label("\(routine.streak) day streak", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(Theme.accent)
                
                Spacer()
                
                Text("\(routine.tasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.5)]),
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
        )
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.smallPadding) {
            Text("Weekly Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
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
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    routine.wasCompletedOn(weekDates[index]) ? Color.white.opacity(0.5) : Color.white.opacity(0.05),
                                                    routine.wasCompletedOn(weekDates[index]) ? Color.white.opacity(0.8) : Color.white.opacity(0.1)
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
        .background(
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.5)]),
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
        )
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RoutineStore())
    }
}
