import SwiftUI

struct CardRow: View {
    let card: Card
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.question)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(card.answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                MasteryLevelBadge(level: card.masteryLevel)
                
                Text(card.formattedSuccessRate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CardRow_Previews: PreviewProvider {
    static var previews: some View {
        CardRow(card: Card.preview)
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 