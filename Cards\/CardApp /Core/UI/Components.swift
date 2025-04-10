import SwiftUI

// Composants d'interface utilisateur réutilisables

// MARK: - SearchBar
struct SearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            TextField("Rechercher...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if isEditing && !text.isEmpty {
                            Button(action: {
                                text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .onTapGesture {
                    isEditing = true
                }
            
            if isEditing {
                Button(action: {
                    isEditing = false
                    text = ""
                    // Dismiss keyboard on iOS, no-op on macOS
                }) {
                    Text("Annuler")
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default, value: isEditing)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - FilterBar
struct FilterBar<FilterOption>: View where FilterOption: Hashable & CustomStringConvertible {
    @Binding var selectedFilter: FilterOption
    let options: [FilterOption]
    let iconForOption: ((FilterOption) -> String)?
    
    init(
        selectedFilter: Binding<FilterOption>,
        options: [FilterOption],
        iconForOption: ((FilterOption) -> String)? = nil
    ) {
        self._selectedFilter = selectedFilter
        self.options = options
        self.iconForOption = iconForOption
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    FilterOptionButton(
                        title: String(describing: option.description),
                        systemImage: iconForOption?(option),
                        isSelected: selectedFilter == option
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedFilter = option
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
    }
}

struct FilterOptionButton: View {
    let title: String
    let systemImage: String?
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(8)
    }
}

// MARK: - Previews
struct UIComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SearchBar(text: .constant(""))
            
            FilterBar(
                selectedFilter: .constant("Toutes"),
                options: ["Toutes", "Nouvelles", "À revoir"],
                iconForOption: { option in
                    switch option {
                    case "Toutes": return "tray.full"
                    case "Nouvelles": return "star"
                    case "À revoir": return "clock"
                    default: return "questionmark"
                    }
                }
            )
        }
        .padding()
    }
} 