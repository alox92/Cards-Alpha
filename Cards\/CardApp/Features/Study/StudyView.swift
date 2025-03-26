import SwiftUI

struct StudyView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var studyViewModel: StudyViewModel
    @State private var showingCardFront = true
    @State private var showingFinishAlert = false
    @State private var offset = CGSize.zero
    @State private var backgroundColor = Color.white
    @State private var cardRotation: Double = 0
    
    let deckId: UUID
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // MARK: - Layouts
    
    private var macOSLayout: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: backgroundColor)
            
            HStack(spacing: 20) {
                // Colonne de gauche - informations sur la session
                VStack(alignment: .leading, spacing: 20) {
                    Text("Session d'étude")
                        .font(.title)
                        .fontWeight(.bold)
                        .accessibility(label: Text("Session d'étude"))
                        
                    studyProgressHeader
                    
                    Divider()
                    
                    if studyViewModel.currentDeck != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Paquet:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(studyViewModel.currentDeck?.name ?? "")
                                .font(.title3)
                                .accessibility(label: Text("Nom du paquet: \(studyViewModel.currentDeck?.name ?? "")"))
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Statistiques:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            statsItem(count: studyViewModel.sessionStats.cardsReviewed, 
                                    label: "Étudiées", 
                                    icon: "checkmark.circle", 
                                    color: .blue)
                                .accessibility(label: Text("\(studyViewModel.sessionStats.cardsReviewed) cartes étudiées"))
                            
                            Spacer()
                            
                            statsItem(count: studyViewModel.sessionStats.correctAnswers, 
                                    label: "Correctes", 
                                    icon: "hand.thumbsup", 
                                    color: .green)
                                .accessibility(label: Text("\(studyViewModel.sessionStats.correctAnswers) réponses correctes"))
                        }
                        
                        HStack {
                            statsItem(count: studyViewModel.sessionStats.incorrectAnswers, 
                                    label: "Incorrectes", 
                                    icon: "hand.thumbsdown", 
                                    color: .red)
                                .accessibility(label: Text("\(studyViewModel.sessionStats.incorrectAnswers) réponses incorrectes"))
                            
                            Spacer()
                            
                            if studyViewModel.sessionStats.cardsReviewed > 0 {
                                statsItem(value: String(format: "%.0f%%", studyViewModel.sessionStats.successRate), 
                                        label: "Réussite", 
                                        icon: "percent", 
                                        color: .orange)
                                    .accessibility(label: Text("Taux de réussite: \(Int(studyViewModel.sessionStats.successRate))%"))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Terminer la session") {
                        showingFinishAlert = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut("e", modifiers: [.command])
                    .accessibility(label: Text("Terminer la session d'étude"))
                    .accessibility(hint: Text("Raccourci clavier: Commande + E"))
                }
                .frame(width: 250)
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.5))
                
                // Colonne de droite - carte en cours
                VStack {
                    if studyViewModel.isLoading {
                        loadingView
                    } else if studyViewModel.error != nil {
                        errorView
                    } else if studyViewModel.isStudying {
                        if let card = studyViewModel.currentCard {
                            Spacer()
                            
                            flashcardView(card: card)
                                .frame(maxWidth: 600, maxHeight: 400)
                                .accessibility(label: Text("Carte: " + (showingCardFront ? "Question" : "Réponse")))
                                .accessibility(value: Text(showingCardFront ? card.question : card.answer))
                                .accessibility(hint: Text("Appuyez sur Espace pour retourner la carte"))
                            
                            if !showingCardFront {
                                ratingButtonsWithKeyboardShortcuts
                                    .padding(.top, 24)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            Spacer()
                        }
                    } else {
                        emptyView
                    }
                }
                .frame(maxWidth: .infinity)
                .onKeyPress(.space) { _ in
                    if studyViewModel.isStudying {
                        withAnimation(.spring()) {
                            if showingCardFront {
                                cardRotation = 180
                                showingCardFront = false
                                
                                // Démarrer le chronomètre si c'est la première fois qu'on retourne la carte
                                if studyViewModel.reviewStartTime == nil {
                                    studyViewModel.startCardReview()
                                }
                            } else {
                                cardRotation = 0
                                showingCardFront = true
                            }
                        }
                        return .handled
                    }
                    return .ignored
                }
            }
        }
        .alert(isPresented: $showingFinishAlert) {
            Alert(
                title: Text("Terminer la session?"),
                message: Text("Voulez-vous terminer cette session d'étude?"),
                primaryButton: .destructive(Text("Terminer")) {
                    studyViewModel.endSession()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .navigationTitle("Étude: " + (studyViewModel.currentDeck?.name ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if studyViewModel.isStudying {
                    Button(action: {
                        showingFinishAlert = true
                    }) {
                        Text("Terminer")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .onAppear {
            studyViewModel.startSession(deckId: deckId)
        }
    }
    
    private var iOSLayout: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: backgroundColor)
            
            VStack {
                if studyViewModel.isLoading {
                    loadingView
                } else if studyViewModel.error != nil {
                    errorView
                } else if studyViewModel.isStudying {
                    studySessionView
                } else {
                    emptyView
                }
            }
            .alert(isPresented: $showingFinishAlert) {
                Alert(
                    title: Text("Terminer la session?"),
                    message: Text("Voulez-vous terminer cette session d'étude?"),
                    primaryButton: .destructive(Text("Terminer")) {
                        studyViewModel.endSession()
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationBarBackButtonHidden(studyViewModel.isStudying)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if studyViewModel.isStudying {
                    Button(action: {
                        showingFinishAlert = true
                    }) {
                        Text("Terminer")
                            .fontWeight(.medium)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if studyViewModel.isStudying {
                    Button(action: {
                        showingFinishAlert = true
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .onAppear {
            studyViewModel.startSession(deckId: deckId)
        }
    }
    
    // MARK: - Helper Views
    
    private func statsItem(count: Int, label: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text("\(count)")
                    .font(.headline)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func statsItem(value: String, label: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.headline)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Chargement des cartes...")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 70))
                .foregroundColor(.orange)
            
            Text("Impossible de charger les cartes")
                .font(.title2)
                .fontWeight(.bold)
            
            if let error = studyViewModel.error {
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Réessayer") {
                studyViewModel.startSession(deckId: deckId)
            }
            .buttonStyle(.bordered)
            .padding(.top, 10)
        }
    }
    
    private var emptyView: some View {
        EmptyStateView(
            title: "Aucune carte à étudier",
            message: "Ce paquet ne contient pas de cartes à étudier aujourd'hui. Revenez plus tard ou ajoutez de nouvelles cartes.",
            systemImage: "book.closed",
            action: {
                presentationMode.wrappedValue.dismiss()
            },
            actionTitle: "Retour"
        )
    }
    
    private var studySessionView: some View {
        VStack(spacing: 0) {
            studyProgressHeader
                .padding(.horizontal)
                .padding(.bottom)
            
            if let card = studyViewModel.currentCard {
                flashcardView(card: card)
                    .padding(.horizontal)
                
                if !showingCardFront {
                    ratingButtons
                        .padding(.top, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private var studyProgressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Carte \(studyViewModel.currentCardIndex + 1)/\(studyViewModel.cardsToStudy.count)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(studyViewModel.sessionStats.cardsReviewed) étudiées")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(studyViewModel.currentCardIndex), total: Double(studyViewModel.cardsToStudy.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
    }
    
    private func flashcardView(card: Card) -> some View {
        let dragGesture = DragGesture()
            .onChanged { value in
                offset = value.translation
                
                // Change background color based on drag direction
                let dragPercentage = min(abs(value.translation.width) / 150, 1.0)
                if value.translation.width > 0 {
                    backgroundColor = Color.green.opacity(0.1 * dragPercentage)
                } else if value.translation.width < 0 {
                    backgroundColor = Color.red.opacity(0.1 * dragPercentage)
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 120
                
                if value.translation.width > threshold {
                    // Swipe right - Easy
                    showAnswer()
                    recordRating(.easy)
                } else if value.translation.width < -threshold {
                    // Swipe left - Again
                    showAnswer()
                    recordRating(.again)
                }
                
                withAnimation {
                    offset = .zero
                    backgroundColor = .white
                }
            }
        
        let tapGesture = TapGesture()
            .onEnded {
                withAnimation(.spring()) {
                    if showingCardFront {
                        cardRotation = 180
                        showingCardFront = false
                        
                        // Démarrer le chronomètre si c'est la première fois qu'on retourne la carte
                        if studyViewModel.reviewStartTime == nil {
                            studyViewModel.startCardReview()
                        }
                    } else {
                        cardRotation = 0
                        showingCardFront = true
                    }
                }
            }
        
        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    MasteryLevelBadge(level: card.masteryLevel)
                    
                    Spacer()
                    
                    Text("Tapez pour retourner")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding([.horizontal, .top])
                
                Divider()
                
                if showingCardFront {
                    // Front side (Question)
                    ScrollView {
                        Text(card.question)
                            .font(.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)
                    }
                } else {
                    // Back side (Answer)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Réponse:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(card.answer)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            
                            if let additionalInfo = card.additionalInfo, !additionalInfo.isEmpty {
                                Divider()
                                
                                Text("Information supplémentaire:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text(additionalInfo)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .frame(height: 350)
        .rotation3DEffect(
            .degrees(cardRotation),
            axis: (x: 0, y: 1, z: 0)
        )
        .offset(offset)
        .gesture(dragGesture)
        .gesture(tapGesture)
    }
    
    private var ratingButtonsWithKeyboardShortcuts: some View {
        HStack(spacing: 12) {
            ForEach(ReviewRating.allCases) { rating in
                Button(action: {
                    recordRating(rating)
                }) {
                    VStack {
                        Text(rating.displayName)
                            .fontWeight(.medium)
                        
                        Text(rating.keyboardShortcut)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .frame(minWidth: 80)
                    .background(rating.color.opacity(0.1))
                    .foregroundColor(rating.color)
                    .cornerRadius(8)
                }
                .keyboardShortcut(KeyEquivalent(Character(rating.keyboardShortcut)), modifiers: [])
                .buttonStyle(.plain)
                .accessibility(label: Text("Évaluer: \(rating.displayName)"))
                .accessibility(hint: Text("Raccourci clavier: \(rating.keyboardShortcut)"))
            }
        }
    }
    
    // MARK: - Actions
    
    private func showAnswer() {
        if showingCardFront {
            withAnimation(.spring()) {
                cardRotation = 180
                showingCardFront = false
            }
            
            // Démarrer le chronomètre si c'est la première fois qu'on retourne la carte
            if studyViewModel.reviewStartTime == nil {
                studyViewModel.startCardReview()
            }
        }
    }
    
    private func recordRating(_ rating: ReviewRating) {
        // S'assurer que la carte a été retournée avant de pouvoir noter
        if !showingCardFront {
            studyViewModel.recordReview(rating: rating)
            
            // Réinitialiser l'affichage pour la prochaine carte
            showingCardFront = true
            cardRotation = 0
        }
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        let cardService = CardService(context: PersistenceController.preview.container.viewContext)
        let viewModel = StudyViewModel(cardService: cardService)
        
        NavigationView {
            StudyView(deckId: UUID())
        }
    }
} 