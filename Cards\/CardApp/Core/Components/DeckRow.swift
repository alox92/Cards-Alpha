import SwiftUI

struct DeckRow: View {
    let deck: Deck
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(deck.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: deck.icon)
                    .font(.system(size: 24))
                    .foregroundColor(deck.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Text("\(deck.totalCards) cartes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if deck.dueCards > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text("\(deck.dueCards) à réviser")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct DeckRow_Previews: PreviewProvider {
    static var previews: some View {
        DeckRow(deck: Deck.preview)
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 