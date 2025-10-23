//
//  HealthBanner.swift
//  Unhooked
//
//  Health status banner component
//

import SwiftUI

struct HealthBanner: View {
    let healthState: HealthState
    let consecutiveUnfedDays: Int
    let isFragile: Bool
    let onFeed: () -> Void
    let onCure: () -> Void
    let onRevive: () -> Void
    let onRestart: () -> Void
    
    var body: some View {
        Group {
            if healthState == .sick {
                sickBanner
            } else if healthState == .dead {
                deadBanner
            } else if isFragile {
                fragileBanner
            }
        }
    }
    
    // MARK: - Fragile Banner
    
    private var fragileBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "bandage.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text("Recovery Period")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
            }
            
            Text("Your friend is still fragile. Extra care and feeding will help them recover fully.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                onFeed()
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Feed Extra Carefully")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RetroGradients.green)
                .foregroundColor(.white)
                .retroBorder(width: 2, cornerRadius: 10)
                .retroShadow(offset: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .retroBorder(width: 3, color: .orange)
        .retroShadow()
        .padding(.horizontal)
    }
    
    // MARK: - Sick Banner
    
    private var sickBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your friend is sick")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("\(consecutiveUnfedDays) days unfed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("Feed twice in 3 days to recover naturally, or visit the Vet now.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                Button {
                    onFeed()
                } label: {
                    HStack {
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        Text("Feed")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RetroGradients.green)
                    .foregroundColor(.white)
                    .retroBorder(width: 2, cornerRadius: 10)
                    .retroShadow(offset: 2)
                }
                .buttonStyle(.plain)
                
                Button {
                    onCure()
                } label: {
                    VStack(spacing: 2) {
                        HStack {
                            Image(systemName: "cross.fill")
                            Text("Vet")
                        }
                        Text("120 Gems")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(.orange)
                    .foregroundColor(.white)
                    .retroBorder(width: 2, cornerRadius: 10)
                    .retroShadow(offset: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.15))
        .retroBorder(width: 3, color: .orange)
        .retroShadow()
        .padding(.horizontal)
    }
    
    // MARK: - Dead Banner
    
    private var deadBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 50))
                .foregroundStyle(.gray)
            
            VStack(spacing: 6) {
                Text("Your friend has passed away")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Unfed for \(consecutiveUnfedDays) days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("You can revive them or start fresh with a new friend.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button {
                    onRevive()
                } label: {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Revive")
                        }
                        .font(.system(size: 16, weight: .bold))
                        
                        Text("400 Gems")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RetroGradients.purple)
                    .foregroundColor(.white)
                    .retroBorder(width: 2, cornerRadius: 10)
                    .retroShadow(offset: 2)
                }
                .buttonStyle(.plain)
                
                Button {
                    onRestart()
                } label: {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Start Over")
                        }
                        .font(.system(size: 16, weight: .bold))
                        
                        Text("200 Gems")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.gray)
                    .foregroundColor(.white)
                    .retroBorder(width: 2, cornerRadius: 10)
                    .retroShadow(offset: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .retroBorder(width: 3, color: .gray)
        .retroShadow()
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 20) {
        HealthBanner(
            healthState: .healthy,
            consecutiveUnfedDays: 0,
            isFragile: true,
            onFeed: {},
            onCure: {},
            onRevive: {},
            onRestart: {}
        )
        
        HealthBanner(
            healthState: .sick,
            consecutiveUnfedDays: 2,
            isFragile: false,
            onFeed: {},
            onCure: {},
            onRevive: {},
            onRestart: {}
        )
        
        HealthBanner(
            healthState: .dead,
            consecutiveUnfedDays: 4,
            isFragile: false,
            onFeed: {},
            onCure: {},
            onRevive: {},
            onRestart: {}
        )
    }
    .padding()
    .background(RetroGradients.background)
}

