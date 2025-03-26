import SwiftUI

struct MasteryLevelBadge: View {
    let level: MasteryLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.caption)
            
            Text(level.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(level.color.opacity(0.2))
        .foregroundColor(level.color)
        .clipShape(Capsule())
    }
}

struct MasteryLevelBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            MasteryLevelBadge(level: .new)
            MasteryLevelBadge(level: .learning)
            MasteryLevelBadge(level: .familiar)
            MasteryLevelBadge(level: .mastered)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 