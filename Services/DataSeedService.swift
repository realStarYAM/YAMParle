//
//  DataSeedService.swift
//  YAMParle
//

import Foundation
import SwiftData

struct DataSeedService {
    @MainActor
    static func seedInitialDataIfNeeded(in context: ModelContext) {
        do {
            let categoryDescriptor = FetchDescriptor<AACCategory>()
            let existingCategories = try context.fetch(categoryDescriptor)

            // If empty or older categories don't have the new conversation category, seed
            let hasConversation = existingCategories.contains(where: { $0.id == "cat_conversation" })
            if existingCategories.isEmpty || !hasConversation {
                // Delete previous default seeds if updating schema
                if !hasConversation && !existingCategories.isEmpty {
                    for cat in existingCategories where !cat.isCustom {
                        context.delete(cat)
                    }
                    let itemDescriptor = FetchDescriptor<AACItem>()
                    let existingItems = try context.fetch(itemDescriptor)
                    for item in existingItems where !item.isCustom {
                        context.delete(item)
                    }
                }
                populateData(in: context)
            }
        } catch {
            print("Failed to check or seed data: \(error)")
        }
    }

    @MainActor
    private static func populateData(in context: ModelContext) {
        struct ItemSeed {
            let text: String
            let label: String?
            let speech: String?
            let icon: String
        }

        struct CategorySeed {
            let id: String
            let name: String
            let icon: String
            let colorHex: String
            let items: [ItemSeed]
        }

        let seedCategories: [CategorySeed] = [
            // 1. Conversation
            CategorySeed(
                id: "cat_conversation",
                name: "Conversation",
                icon: "bubble.left.and.bubble.right.fill",
                colorHex: "#1E73F2",
                items: [
                    ItemSeed(text: "Bonjour", label: nil, speech: nil, icon: "hand.wave.fill"),
                    ItemSeed(text: "Bonsoir", label: nil, speech: nil, icon: "moon.stars.fill"),
                    ItemSeed(text: "Bonne journée", label: nil, speech: nil, icon: "sun.max.fill"),
                    ItemSeed(text: "Bonne nuit", label: nil, speech: nil, icon: "bed.double.fill"),
                    ItemSeed(text: "Comment ça va ?", label: "Comment ça va ?", speech: nil, icon: "questionmark.bubble.fill"),
                    ItemSeed(text: "Ça va bien", label: nil, speech: nil, icon: "hand.thumbsup.fill"),
                    ItemSeed(text: "Ça ne va pas bien", label: "Ça va mal", speech: nil, icon: "hand.thumbsdown.fill"),
                    ItemSeed(text: "Comment tu t’appelles ?", label: "Ton prénom ?", speech: nil, icon: "person.crop.circle.badge.questionmark"),
                    ItemSeed(text: "Ravi de vous voir", label: "Ravi de vous voir", speech: nil, icon: "face.smiling.fill"),
                    ItemSeed(text: "Excusez-moi", label: nil, speech: nil, icon: "exclamationmark.bubble.fill"),
                    ItemSeed(text: "Attendez un instant", label: "Attendez", speech: nil, icon: "clock.fill"),
                    ItemSeed(text: "Quoi de neuf ?", label: "Quoi de neuf ?", speech: nil, icon: "sparkles"),
                    ItemSeed(text: "Je n’ai pas compris, pouvez-vous répéter ?", label: "Répéter ?", speech: nil, icon: "arrow.counterclockwise.circle.fill"),
                    ItemSeed(text: "Pourriez-vous m’aider ?", label: "M'aider ?", speech: "Pourriez-vous m'aider s'il vous plaît ?", icon: "lifepreserver.fill"),
                    ItemSeed(text: "Je l’aime", label: "J'aime", speech: "Je l'aime", icon: "heart.fill"),
                    ItemSeed(text: "Je n’aime pas ça", label: "J'aime pas", speech: "Je n'aime pas ça", icon: "heart.slash.fill"),
                    ItemSeed(text: "À plus tard", label: "À plus tard", speech: nil, icon: "clock.arrow.circlepath"),
                    ItemSeed(text: "Au revoir", label: nil, speech: nil, icon: "figure.walk.departure"),
                    ItemSeed(text: "Oui", label: nil, speech: nil, icon: "checkmark.circle.fill"),
                    ItemSeed(text: "Non", label: nil, speech: nil, icon: "xmark.circle.fill"),
                    ItemSeed(text: "Peut-être", label: nil, speech: nil, icon: "questionmark.circle.fill")
                ]
            ),

            // 2. Informations
            CategorySeed(
                id: "cat_informations",
                name: "Informations",
                icon: "info.circle.fill",
                colorHex: "#32ADE6",
                items: [
                    ItemSeed(text: "Je m'appelle...", label: "Mon nom", speech: "Bonjour, je m'appelle", icon: "person.text.rectangle.fill"),
                    ItemSeed(text: "J'utilise cette application pour parler", label: "Application AAC", speech: "J'utilise cette application pour communiquer", icon: "iphone.gen3"),
                    ItemSeed(text: "Mon adresse", label: "Mon adresse", speech: "Voici mon adresse", icon: "house.fill"),
                    ItemSeed(text: "Mon numéro de téléphone", label: "Téléphone", speech: "Voici mon numéro de téléphone", icon: "phone.fill"),
                    ItemSeed(text: "J'ai un rendez-vous", label: "Rendez-vous", speech: "J'ai un rendez-vous médical", icon: "calendar"),
                    ItemSeed(text: "Je suis allergique", label: "Allergie", speech: "Attention, j'ai des allergies", icon: "allergens"),
                    ItemSeed(text: "Appelez mon aidant", label: "Aidant", speech: "Pouvez-vous appeler mon aidant s'il vous plaît ?", icon: "person.badge.shield.checkmark.fill"),
                    ItemSeed(text: "Voici ma carte d'identité", label: "Carte", speech: "Voici mes papiers d'identité", icon: "creditcard.fill")
                ]
            ),

            // 3. Personnes
            CategorySeed(
                id: "cat_personnes",
                name: "Personnes",
                icon: "person.2.fill",
                colorHex: "#5856D6",
                items: [
                    ItemSeed(text: "Moi", label: nil, speech: nil, icon: "person.crop.circle.fill"),
                    ItemSeed(text: "Toi", label: nil, speech: nil, icon: "person.fill"),
                    ItemSeed(text: "Nous", label: nil, speech: nil, icon: "person.3.sequence.fill"),
                    ItemSeed(text: "Maman", label: nil, speech: nil, icon: "figure.stand.dress"),
                    ItemSeed(text: "Papa", label: nil, speech: nil, icon: "figure.stand"),
                    ItemSeed(text: "Mon ami", label: "Ami", speech: "Mon ami", icon: "person.2.fill"),
                    ItemSeed(text: "Le médecin", label: "Docteur", speech: "Mon médecin", icon: "cross.case.fill"),
                    ItemSeed(text: "Mon aidant", label: "Aidant", speech: "Mon aidant", icon: "hands.sparkles.fill"),
                    ItemSeed(text: "Le professeur", label: "Professeur", speech: "Le professeur", icon: "graduationcap.fill")
                ]
            ),

            // 4. Endroits
            CategorySeed(
                id: "cat_endroits",
                name: "Endroits",
                icon: "map.fill",
                colorHex: "#34C759",
                items: [
                    ItemSeed(text: "À la maison", label: "Maison", speech: "Je veux rentrer à la maison", icon: "house.fill"),
                    ItemSeed(text: "À l'hôpital", label: "Hôpital", speech: "À l'hôpital", icon: "cross.fill"),
                    ItemSeed(text: "À la pharmacie", label: "Pharmacie", speech: "À la pharmacie", icon: "pills.fill"),
                    ItemSeed(text: "Au magasin", label: "Magasin", speech: "Au magasin", icon: "cart.fill"),
                    ItemSeed(text: "Au parc", label: "Parc", speech: "Je voudrais aller au parc", icon: "tree.fill"),
                    ItemSeed(text: "Aux toilettes", label: "Toilettes", speech: "Où sont les toilettes s'il vous plaît ?", icon: "toilet.fill"),
                    ItemSeed(text: "À l'école", label: "École", speech: "À l'école", icon: "building.2.fill"),
                    ItemSeed(text: "Au restaurant", label: "Restaurant", speech: "Au restaurant", icon: "fork.knife")
                ]
            ),

            // 5. Maison
            CategorySeed(
                id: "cat_maison",
                name: "Maison",
                icon: "house.fill",
                colorHex: "#AF52DE",
                items: [
                    ItemSeed(text: "Ma chambre", label: "Chambre", speech: "Dans ma chambre", icon: "bed.double.fill"),
                    ItemSeed(text: "Le salon", label: "Salon", speech: "Dans le salon", icon: "sofa.fill"),
                    ItemSeed(text: "La cuisine", label: "Cuisine", speech: "Dans la cuisine", icon: "refrigerator.fill"),
                    ItemSeed(text: "La salle de bain", label: "Salle de bain", speech: "Dans la salle de bain", icon: "shower.fill"),
                    ItemSeed(text: "Ouvrir la porte", label: "Porte", speech: "Pouvez-vous ouvrir la porte s'il vous plaît ?", icon: "door.left.hand.open"),
                    ItemSeed(text: "Fermer la fenêtre", label: "Fenêtre", speech: "Fermez la fenêtre s'il vous plaît", icon: "window.vertical.closed"),
                    ItemSeed(text: "Allumer la lumière", label: "Lumière", speech: "Allumez la lumière s'il vous plaît", icon: "lightbulb.fill"),
                    ItemSeed(text: "Allumer la télévision", label: "Télévision", speech: "Je voudrais regarder la télévision", icon: "tv.fill")
                ]
            ),

            // 6. Nourriture
            CategorySeed(
                id: "cat_nourriture",
                name: "Nourriture",
                icon: "fork.knife",
                colorHex: "#FF9500",
                items: [
                    ItemSeed(text: "J'ai faim", label: "Faim", speech: "J'ai très faim", icon: "fork.knife.circle.fill"),
                    ItemSeed(text: "J'ai soif", label: "Soif", speech: "J'ai soif, je voudrais boire", icon: "drop.fill"),
                    ItemSeed(text: "Un verre d'eau", label: "Eau", speech: "Un verre d'eau s'il vous plaît", icon: "cup.and.saucer.fill"),
                    ItemSeed(text: "Du café", label: "Café", speech: "Un café s'il vous plaît", icon: "mug.fill"),
                    ItemSeed(text: "Du thé", label: "Thé", speech: "Un thé s'il vous plaît", icon: "cup.and.saucer"),
                    ItemSeed(text: "Du pain", label: "Pain", speech: "Du pain s'il vous plaît", icon: "takeoutbag.and.cup.and.straw.fill"),
                    ItemSeed(text: "Des fruits", label: "Fruits", speech: "Des fruits s'il vous plaît", icon: "apple.logo"),
                    ItemSeed(text: "C'est délicieux", label: "Délicieux", speech: "C'est délicieux, merci", icon: "star.fill")
                ]
            ),

            // 7. Objets
            CategorySeed(
                id: "cat_objets",
                name: "Objets",
                icon: "cube.fill",
                colorHex: "#FF2D55",
                items: [
                    ItemSeed(text: "Mes lunettes", label: "Lunettes", speech: "Où sont mes lunettes ?", icon: "glasses"),
                    ItemSeed(text: "Mon téléphone", label: "Téléphone", speech: "Mon téléphone portable", icon: "iphone"),
                    ItemSeed(text: "Mes clés", label: "Clés", speech: "Mes clés de maison", icon: "key.fill"),
                    ItemSeed(text: "Mon livre", label: "Livre", speech: "Mon livre de lecture", icon: "book.fill"),
                    ItemSeed(text: "Mon fauteuil", label: "Fauteuil", speech: "Mon fauteuil roulant", icon: "figure.roll"),
                    ItemSeed(text: "Mon chargeur", label: "Chargeur", speech: "J'ai besoin de mon chargeur", icon: "cable.connector"),
                    ItemSeed(text: "Un mouchoir", label: "Mouchoir", speech: "Donnez-moi un mouchoir s'il vous plaît", icon: "hand.point.up.fill")
                ]
            ),

            // 8. Sentiments
            CategorySeed(
                id: "cat_sentiments",
                name: "Sentiments",
                icon: "face.smiling.fill",
                colorHex: "#FFCC00",
                items: [
                    ItemSeed(text: "Je suis heureux", label: "Heureux", speech: "Je suis très heureux", icon: "face.smiling.fill"),
                    ItemSeed(text: "Je suis triste", label: "Triste", speech: "Je me sens triste", icon: "face.dashed"),
                    ItemSeed(text: "Je suis fatigué", label: "Fatigué", speech: "Je suis fatigué, j'ai besoin de repos", icon: "zzz"),
                    ItemSeed(text: "Je suis en colère", label: "En colère", speech: "Je suis en colère", icon: "flame.fill"),
                    ItemSeed(text: "J'ai peur", label: "Peur", speech: "J'ai un peu peur", icon: "exclamationmark.shield.fill"),
                    ItemSeed(text: "Je suis calme", label: "Calme", speech: "Je me sens calme et détendu", icon: "heart.fill")
                ]
            ),

            // 9. Corps
            CategorySeed(
                id: "cat_corps",
                name: "Corps",
                icon: "figure.walk",
                colorHex: "#007AFF",
                items: [
                    ItemSeed(text: "J'ai mal à la tête", label: "Tête", speech: "J'ai très mal à la tête", icon: "brain.head.profile"),
                    ItemSeed(text: "J'ai mal au ventre", label: "Ventre", speech: "J'ai mal au ventre", icon: "cross.circle.fill"),
                    ItemSeed(text: "J'ai mal au dos", label: "Dos", speech: "J'ai mal dans le dos", icon: "figure.walk"),
                    ItemSeed(text: "J'ai froid", label: "Froid", speech: "J'ai froid, donnez-moi une couverture", icon: "snowflake"),
                    ItemSeed(text: "J'ai chaud", label: "Chaud", speech: "J'ai très chaud", icon: "sun.max.trianglebadge.exclamationmark.fill"),
                    ItemSeed(text: "J'ai des vertiges", label: "Vertiges", speech: "J'ai des vertiges", icon: "tornado")
                ]
            ),

            // 10. Vêtements
            CategorySeed(
                id: "cat_vetements",
                name: "Vêtements",
                icon: "tshirt.fill",
                colorHex: "#A2845E",
                items: [
                    ItemSeed(text: "Mon manteau", label: "Manteau", speech: "Mettez mon manteau s'il vous plaît", icon: "jacket.fill"),
                    ItemSeed(text: "Mes chaussures", label: "Chaussures", speech: "Mes chaussures", icon: "shoe.fill"),
                    ItemSeed(text: "Mon pull", label: "Pull", speech: "Mon pull chaud", icon: "tshirt.fill"),
                    ItemSeed(text: "Mon pantalon", label: "Pantalon", speech: "Mon pantalon", icon: "figure.stand"),
                    ItemSeed(text: "Mon chapeau", label: "Chapeau", speech: "Mon chapeau", icon: "hat.widebrim.fill"),
                    ItemSeed(text: "C'est trop serré", label: "Trop serré", speech: "C'est trop serré, ça me gêne", icon: "arrow.right.and.line.vertical.and.arrow.left")
                ]
            )
        ]

        var categoryOrder = 0
        for catSeed in seedCategories {
            let category = AACCategory(
                id: catSeed.id,
                name: catSeed.name,
                iconName: catSeed.icon,
                colorHex: catSeed.colorHex,
                sortOrder: categoryOrder,
                isCustom: false
            )
            context.insert(category)
            categoryOrder += 1

            var itemOrder = 0
            for itemSeed in catSeed.items {
                let item = AACItem(
                    text: itemSeed.text,
                    label: itemSeed.label,
                    speechText: itemSeed.speech,
                    iconName: itemSeed.icon,
                    customImageData: nil,
                    categoryId: catSeed.id,
                    customColorHex: nil,
                    sortOrder: itemOrder,
                    isFavorite: false,
                    isCustom: false
                )
                context.insert(item)
                itemOrder += 1
            }
        }

        try? context.save()
    }
}
