import SwiftUI

// MARK: - Score gauge (270° animated arc)

struct ScoreGauge: View {
    let score: Int
    let label: String
    var accent: Color = .white
    var track: Color = .white.opacity(0.25)
    var contentColor: Color = .white
    var size: CGFloat = 170

    @State private var animatedFraction: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(track, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0, to: 0.75 * animatedFraction)
                .stroke(
                    AngularGradient(
                        colors: [accent.opacity(0.55), accent],
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(405)
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(135))
            VStack(spacing: 2) {
                Text("\(Int(animatedFraction * CGFloat(score)))")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .opacity(0.9)
            }
            .foregroundStyle(contentColor)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) { animatedFraction = 1 }
        }
        .onChange(of: score) {
            animatedFraction = 0
            withAnimation(.easeOut(duration: 0.9)) { animatedFraction = 1 }
        }
    }
}

// MARK: - Budget progress ring

struct ProgressRing<Center: View>: View {
    let progress: Double
    var color: Color = Theme.riskGood
    var overColor: Color = Theme.riskSevere
    var size: CGFloat = 90
    var lineWidth: CGFloat = 9
    @ViewBuilder var center: Center

    @State private var animated: Double = 0

    private var ringColor: Color { progress > 1 ? overColor : color }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.18), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: min(1, animated))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            center
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { animated = max(0, progress) }
        }
        .onChange(of: progress) {
            withAnimation(.easeOut(duration: 0.6)) { animated = max(0, progress) }
        }
    }
}

// MARK: - Risk category chip

struct RiskChip: View {
    let band: RiskBand
    var compact: Bool = false

    var body: some View {
        Text(band.label)
            .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            .foregroundStyle(band.level.color)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 3 : 5)
            .background(band.level.color.opacity(0.16), in: Capsule())
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji).font(.system(size: 44))
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

// MARK: - Metric dot + label

struct MetricLabel: View {
    let metric: MetricType

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(metric.color).frame(width: 7, height: 7)
            Text(metric.shortName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}
