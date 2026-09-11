import Foundation
import SwiftUI

// MARK: - Species

enum PetSpecies: String, CaseIterable, Codable, Identifiable {
    case cat
    case dog

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

// MARK: - Variant

struct PetVariant: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let species: PetSpecies
    /// Body fill color as hex string, e.g. "#E8924A"
    let bodyHex: String
    let accentHex: String
    let bellyHex: String

    // MARK: Static catalog (add new variants here)
    static let catalog: [PetVariant] = [
        // Cats
        PetVariant(id: "orangeTabby", displayName: "Orange Tabby", species: .cat,
                   bodyHex: "#E8924A", accentHex: "#C06A28", bellyHex: "#FFF0D0"),
        PetVariant(id: "grayCat", displayName: "Gray Cat", species: .cat,
                   bodyHex: "#888888", accentHex: "#555555", bellyHex: "#DDDDDD"),
        PetVariant(id: "tanCat", displayName: "Tan Cat", species: .cat,
                   bodyHex: "#E6C280", accentHex: "#C49A50", bellyHex: "#FFF5E0"),
        // Dogs
        PetVariant(id: "goldenRetriever", displayName: "Golden", species: .dog,
                   bodyHex: "#D4A017", accentHex: "#9E7410", bellyHex: "#FFF0C0"),
        PetVariant(id: "grayDog", displayName: "Gray Dog", species: .dog,
                   bodyHex: "#888888", accentHex: "#555555", bellyHex: "#DDDDDD"),
        PetVariant(id: "tanDog", displayName: "Tan Dog", species: .dog,
                   bodyHex: "#E6C280", accentHex: "#C49A50", bellyHex: "#FFF5E0"),
    ]
}

// MARK: - Preferences Store

class PetPreferencesStore: ObservableObject {
    private static let key = "selectedPetVariantID"

    @Published var selectedVariantID: String {
        didSet { UserDefaults.standard.set(selectedVariantID, forKey: Self.key) }
    }

    var selectedVariant: PetVariant {
        PetVariant.catalog.first { $0.id == selectedVariantID } ?? PetVariant.catalog[0]
    }

    init() {
        self.selectedVariantID = UserDefaults.standard.string(forKey: Self.key) ?? "orangeTabby"
    }
}
