/*
 OnboardingView - First-time user onboarding experience
 Shows app features, requests permissions, and guides initial setup.
 */

import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var stayStore: StayStore
    @EnvironmentObject var alertManager: AlertManager
    
    @State private var currentPage = 0
    @State private var isOnboardingComplete = false
    @State private var requestingPermissions = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Track Your Visa Days",
            subtitle: "Never overstay again. Monitor your allowed days across countries and get alerts before deadlines.",
            icon: "globe.americas.fill",
            color: .nomadBlue
        ),
        OnboardingPage(
            title: "Smart Alerts",
            subtitle: "Get notified at 30, 15, 7, 3, and 1 days remaining so you can plan your next move.",
            icon: "bell.badge.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Photo Import",
            subtitle: "Auto-detect your stays from travel photos with GPS data. No manual entry needed.",
            icon: "photo.on.rectangle.angled",
            color: .purple
        ),
        OnboardingPage(
            title: "Year at a Glance",
            subtitle: "See your travel summary for the year with days spent and remaining per country.",
            icon: "calendar.badge.clock",
            color: .green
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.nomadBlue.opacity(0.1), Color.nomadBlue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        onboardingPage(pages[index])
                            .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .always))
                #endif
                .frame(maxHeight: 400)
                
                Spacer()
                
                // Get Started button
                Button(action: {
                    if currentPage == pages.count - 1 {
                        startOnboarding()
                    } else {
                        withAnimation {
                            currentPage = pages.count - 1
                        }
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            currentPage == pages.count - 1
                                ? Color.nomadBlue
                                : Color.nomadBlue.opacity(0.6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .disabled(requestingPermissions)
                
                if requestingPermissions {
                    ProgressView()
                        .padding(.bottom, 20)
                }
            }
        }
        .animation(.easeInOut, value: currentPage)
    }
    
    // MARK: - Onboarding Page
    
    private func onboardingPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color)
                .padding(.bottom, 8)
            
            // Title
            Text(page.title)
                .font(.title.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineLimit(4)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func startOnboarding() {
        requestingPermissions = true
        
        Task {
            // Request notification permission
            let granted = await alertManager.requestPermission()
            
            // Mark onboarding as complete
            UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
            UserDefaults.standard.set(Date(), forKey: "onboarding_completion_date")
            
            // Small delay for UX
            try? await Task.sleep(for: .milliseconds(500))
            
            requestingPermissions = false
            isOnboardingComplete = true
            
            // Sync initial data
            stayStore.syncToAppGroup()
            
            // Schedule alerts if permission granted
            if granted {
                alertManager.scheduleAllAlerts(for: stayStore.activeStays)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        UserDefaults.standard.set(Date(), forKey: "onboarding_completion_date")
        isOnboardingComplete = true
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(StayStore())
        .environmentObject(AlertManager())
}
