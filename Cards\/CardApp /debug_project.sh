#!/bin/bash

echo "====== Diagnostic CardApp ======"
echo "Nettoyage de l'environnement de compilation..."
rm -rf .build
rm -rf .swiftpm

echo "Vérification de l'environnement Swift..."
swift --version

echo "Tentative de compilation avec rapport d'erreur détaillé..."
swift build -v -Xswiftc -debug-time-function-bodies -Xswiftc -debug-time-compilation > build_log.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Compilation réussie!"
else
    echo "❌ Échec de compilation. Analyse des erreurs..."
    
    # Extraire les erreurs principales
    grep "error:" build_log.txt > compilation_errors.txt
    
    # Analyser les types d'erreurs les plus fréquents
    echo "Types d'erreurs les plus fréquents:"
    cat compilation_errors.txt | sort | uniq -c | sort -nr | head -10
    
    # Vérifier les problèmes courants
    echo "Vérification des problèmes de modèle CoreData..."
    find . -name "*.xcdatamodeld" -exec echo "Modèle trouvé: {}" \;
    
    echo "Vérification des dépendances circulaires potentielles..."
    grep -r "import " --include="*.swift" . | sort | uniq > import_statements.txt
    
    echo "Vérification des fichiers importants..."
    find . -name "AppDelegate.swift" -o -name "PersistenceController.swift" -o -name "Core.swift"
fi

echo "Création d'une version simplifiée du projet pour test..."
cat > Simplified_Package.swift << EOF
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CardAppSimplified",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [.executable(name: "CardAppSimplified", targets: ["App"])],
    dependencies: [],
    targets: [
        .target(name: "CoreMinimal", path: "CoreMinimal", sources: ["CoreMinimal.swift"]),
        .executableTarget(name: "App", dependencies: ["CoreMinimal"], path: "AppMinimal", sources: ["AppMinimal.swift"])
    ]
)
EOF

mkdir -p CoreMinimal AppMinimal

cat > CoreMinimal/CoreMinimal.swift << EOF
import Foundation

public struct Card {
    public let id: UUID
    public let question: String
    public let answer: String
    
    public init(id: UUID = UUID(), question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}

public class CardService {
    public static let shared = CardService()
    private init() {}
    
    public func getCards() -> [Card] {
        return [Card(question: "Test Question", answer: "Test Answer")]
    }
}
EOF

cat > AppMinimal/AppMinimal.swift << EOF
import Foundation
import CoreMinimal

@main
struct CardAppMinimal {
    static func main() {
        let cards = CardService.shared.getCards()
        print("Cards loaded: \(cards.count)")
        print("First card: \(cards.first?.question ?? "None")")
    }
}
EOF

echo "Tentative de compilation de la version simplifiée..."
swift build --package-path . -Xswiftc -swift-version -Xswiftc 5 --manifest-path Simplified_Package.swift

echo "====== Fin du diagnostic ======"
echo "Consultez build_log.txt et compilation_errors.txt pour plus de détails"
