//
//  ContentBlocker.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import Foundation

enum FilterType: String, CaseIterable {
    case reels = "reels"
    case explore = "explore"
    case stories = "stories"
    case suggestions = "suggestions"
    case suggestedPosts = "suggestedPosts"
    case likes = "likes"
    case following = "following"
    case messages = "messages"
    
    var displayName: String {
        switch self {
        case .reels: return "Reels"
        case .explore: return "Explore"
        case .stories: return "Stories"
        case .suggestions: return "Suggestions"
        case .suggestedPosts: return "Suggested Posts"
        case .likes: return "Like Counter"
        case .following: return "Following Only Mode"
        case .messages: return "Messages"
        }
    }
    
    var isEnabled: Bool {
        get {
            PersistenceService.shared.isFilterEnabled(self.rawValue)
        }
        set {
            PersistenceService.shared.setFilterEnabled(newValue, for: self.rawValue)
        }
    }

    func setEnabled(_ enabled: Bool) {
        PersistenceService.shared.setFilterEnabled(enabled, for: self.rawValue)
    }
}

// MARK: - Instagram Theme
enum InstagramTheme: String, CaseIterable {
    case `default` = "default"
    case midnightPurple = "midnightPurple"
    case pinkGlow = "pinkGlow"
    case amoledBlack = "amoledBlack"
    
    var displayName: String {
        switch self {
        case .default: return "Default"
        case .midnightPurple: return "Midnight"
        case .pinkGlow: return "Pink"
        case .amoledBlack: return "Amoled"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .default: return false
        case .midnightPurple, .pinkGlow, .amoledBlack: return true
        }
    }
    
    // Primary background color (hex)
    var backgroundColor: String {
        switch self {
        case .default: return "" // No custom color
        case .midnightPurple: return "#1a1a2e"
        case .pinkGlow: return "#1a0a14" // Dark pink/magenta base
        case .amoledBlack: return "#000000"
        }
    }
    
    // Secondary/card background color (hex)
    var cardColor: String {
        switch self {
        case .default: return ""
        case .midnightPurple: return "#16213e"
        case .pinkGlow: return "#2d1a24" // Slightly lighter pink
        case .amoledBlack: return "#0a0a0a"
        }
    }
    
    // Accent color for highlights (hex)
    var accentColor: String {
        switch self {
        case .default: return ""
        case .midnightPurple: return "#e94560"
        case .pinkGlow: return "#fa0d70" // Bright pink like onboarding
        case .amoledBlack: return "#ffffff"
        }
    }
    
    // Preview colors for the UI cards (SwiftUI Color)
    var previewColors: (primary: (r: Double, g: Double, b: Double), secondary: (r: Double, g: Double, b: Double)) {
        switch self {
        case .default:
            return (primary: (0.1, 0.1, 0.1), secondary: (0.2, 0.2, 0.2))
        case .midnightPurple:
            return (primary: (0.10, 0.10, 0.18), secondary: (0.086, 0.129, 0.243))
        case .pinkGlow:
            return (primary: (0.10, 0.04, 0.08), secondary: (0.18, 0.10, 0.14)) // Pink preview
        case .amoledBlack:
            return (primary: (0.0, 0.0, 0.0), secondary: (0.04, 0.04, 0.04))
        }
    }
    
    // Persistence
    static var current: InstagramTheme {
        get {
            let rawValue = PersistenceService.shared.getSelectedTheme()
            return InstagramTheme(rawValue: rawValue) ?? .default
        }
        set {
            PersistenceService.shared.setSelectedTheme(newValue.rawValue)
        }
    }
}

class ContentBlocker {
    
    static func getBlockingScript() -> String {
        // Injecter les valeurs actuelles des filtres directement dans le script
        let filtersJson = FilterType.allCases.map { "\"\($0.rawValue)\": \($0.isEnabled)" }.joined(separator: ", ")

        return """
        (function() {
            console.log('LessIsMore: Initialisation du bloqueur de contenu');

            // Filtres initiaux injectés depuis l'app iOS
            window.__lessIsMoreInitialFilters = {\(filtersJson)};
            
            // Style CSS pour masquer les éléments
            const style = document.createElement('style');
            style.textContent = `
                /* Masquer les reels */
                .lessismore-hidden-reels [href="/reels/"],
                .lessismore-hidden-reels a[href*="/reels/"],
                .lessismore-hidden-reels [role="tablist"] a[href="/reels/"],
                .lessismore-hidden-reels nav a[href="/reels/"] {
                    display: none !important;
                }
                
                /* Masquer la page explorer */
                .lessismore-hidden-explore [href="/explore/"],
                .lessismore-hidden-explore a[href*="/explore/"],
                .lessismore-hidden-explore [role="tablist"] a[href="/explore/"],
                .lessismore-hidden-explore nav a[href="/explore/"] {
                    display: none !important;
                }
                
                /* Masquer l'onglet messages */
                .lessismore-hidden-messages [href="/direct/inbox/"],
                .lessismore-hidden-messages a[href*="/direct/"],
                .lessismore-hidden-messages [role="tablist"] a[href="/direct/"],
                .lessismore-hidden-messages nav a[href="/direct/"],
                .lessismore-hidden-messages [aria-label*="message" i],
                .lessismore-hidden-messages [aria-label*="Message" i],
                .lessismore-hidden-messages [aria-label*="MESSAGES" i],
                .lessismore-hidden-messages [data-testid*="message"],
                .lessismore-hidden-messages [data-testid*="direct"] {
                    display: none !important;
                }
                
                /* Masquer les stories - sélecteurs ultra-précis */
                .lessismore-hidden-stories [data-testid="stories-container"],
                .lessismore-hidden-stories [data-testid="stories"],
                .lessismore-hidden-stories [data-testid="story"],
                .lessismore-hidden-stories [data-testid="story-ring"],
                .lessismore-hidden-stories [aria-label*="story" i],
                .lessismore-hidden-stories [aria-label*="Story" i],
                .lessismore-hidden-stories [aria-label*="STORIES" i],
                .lessismore-hidden-stories div[style*="overflow-x: auto"],
                .lessismore-hidden-stories div[style*="scrollbar-width"],
                .lessismore-hidden-stories div[style*="cursor: pointer"][style*="border-radius"],
                .lessismore-hidden-stories section > div > div:first-child,
                .lessismore-hidden-stories div:has(> div > div > img[alt*="story" i]),
                .lessismore-hidden-stories div:has(> div > div > img[alt*="Story" i]),
                .lessismore-hidden-stories div:has(> div > div > img[alt*="STORIES" i]),
                .lessismore-hidden-stories div:has(> div > div > img[alt*="stories" i]),
                .lessismore-hidden-stories div:has(> div > div > img[alt*="Stories" i]) {
                    display: none !important;
                }
                
                /* Masquer les suggestions de la sidebar */
                .lessismore-hidden-suggestions aside,
                .lessismore-hidden-suggestions [data-testid*="suggestion"],
                .lessismore-hidden-suggestions div[style*="position: sticky"],
                .lessismore-hidden-suggestions div:has(> div > div > span:contains("Suggestions pour vous")) {
                    display: none !important;
                }
                
                /* Masquer les posts suggérés dans le feed */
                .lessismore-hidden-suggestedPosts article:has(span:contains("Suggested for you")),
                .lessismore-hidden-suggestedPosts article:has(span:contains("Suggéré pour vous")),
                .lessismore-hidden-suggestedPosts article:has(span:contains("Suggerido para ti")),
                .lessismore-hidden-suggestedPosts article:has(span:contains("Für dich vorgeschlagen")),
                .lessismore-hidden-suggestedPosts article:has([data-testid*="suggested"]),
                .lessismore-hidden-suggestedPosts div:has(> article):has(span:contains("Suggested")),
                .lessismore-hidden-suggestedPosts div:has(> article):has(span:contains("Suggéré")),
                .lessismore-hidden-suggestedPosts [data-lessismore-suggested-post="true"] {
                    display: none !important;
                }
                
                /* Masquer les compteurs de likes - sélecteurs très précis */
                .lessismore-hidden-likes [data-testid="like-count"],
                .lessismore-hidden-likes [data-testid="likes-count"],
                .lessismore-hidden-likes [data-testid="likes"],
                .lessismore-hidden-likes [aria-label*="like" i][aria-label*="person"],
                .lessismore-hidden-likes [aria-label*="Like" i][aria-label*="person"],
                .lessismore-hidden-likes [aria-label*="LIKES" i][aria-label*="person"],
                .lessismore-hidden-likes a[href*="/liked_by/"],
                .lessismore-hidden-likes a[href*="/likes/"] {
                    display: none !important;
                }
                
                /* Masquer le bouton "For you" et forcer le mode Following */
                .lessismore-hidden-following [aria-label*="For you" i],
                .lessismore-hidden-following [aria-label*="For You" i],
                .lessismore-hidden-following [aria-label*="FOR YOU" i],
                .lessismore-hidden-following [data-testid*="for-you"],
                .lessismore-hidden-following [data-testid*="foryou"],
                .lessismore-hidden-following [href="/"],
                .lessismore-hidden-following a[href="/"],
                .lessismore-hidden-following [role="tab"][aria-selected="false"] {
                    display: none !important;
                }
                

            `;
            
            document.head.appendChild(style);
            
            // Le bouton éclair a été supprimé comme demandé
            
            // Fonction pour appliquer/retirer les filtres
            window.lessIsMoreToggleFilter = function(filterType, enabled) {
                const className = 'lessismore-hidden-' + filterType;
                if (enabled) {
                    document.body.classList.add(className);
                    
                    // Pour les stories, appliquer un masquage supplémentaire
                    if (filterType === 'stories') {
                        setTimeout(() => {
                            window.lessIsMoreDebugStories(); // Déboguer d'abord
                            window.lessIsMoreHideStories();
                        }, 50);
                    }
                    
                    // Pour les likes, appliquer un masquage supplémentaire
                    if (filterType === 'likes') {
                        setTimeout(() => {
                            window.lessIsMoreDebugLikes(); // Déboguer d'abord
                            window.lessIsMoreHideLikes();
                        }, 50);
                    }
                    
                    // Pour le mode Following, masquer le bouton "For you"
                    if (filterType === 'following') {
                        setTimeout(() => {
                            window.lessIsMoreDebugFollowing(); // Déboguer d'abord
                            window.lessIsMoreHideForYou();
                        }, 50);
                    }
                    
                    
                    // Pour les posts suggérés dans le feed
                    if (filterType === 'suggestedPosts') {
                        setTimeout(() => {
                            window.lessIsMoreHideSuggestedPosts();
                        }, 50);
                    }
                } else {
                    document.body.classList.remove(className);
                    
                    // Pour les stories, restaurer l'affichage
                    if (filterType === 'stories') {
                        setTimeout(() => {
                            window.lessIsMoreShowStories();
                        }, 50);
                    }
                    
                    // Pour les likes, restaurer l'affichage
                    if (filterType === 'likes') {
                        setTimeout(() => {
                            window.lessIsMoreShowLikes();
                        }, 50);
                    }
                    
                    // Pour le mode Following, restaurer le bouton "For you"
                    if (filterType === 'following') {
                        setTimeout(() => {
                            window.lessIsMoreShowForYou();
                        }, 50);
                    }
                    
                    
                    // Pour les posts suggérés, restaurer l'affichage
                    if (filterType === 'suggestedPosts') {
                        setTimeout(() => {
                            window.lessIsMoreShowSuggestedPosts();
                        }, 50);
                    }
                }
                
                // L'état est maintenant géré par l'app iOS
            };
            
            // Fonction de débogage pour analyser la structure des stories
            window.lessIsMoreDebugStories = function() {
                console.log('=== DEBUG STORIES ===');
                const possibleStories = document.querySelectorAll('div[style*="border-radius"], div[style*="cursor: pointer"], [role="button"]');
                console.log('Éléments potentiels de stories trouvés:', possibleStories.length);
                
                possibleStories.forEach((el, index) => {
                    if (index < 10) { // Limiter à 10 éléments
                        console.log(`Élément ${index}:`, {
                            tagName: el.tagName,
                            className: el.className,
                            style: el.getAttribute('style'),
                            dataTestId: el.getAttribute('data-testid'),
                            ariaLabel: el.getAttribute('aria-label'),
                            hasImage: !!el.querySelector('img'),
                            dimensions: `${el.offsetWidth}x${el.offsetHeight}`
                        });
                    }
                });
                
                // Analyser la première section
                const firstSection = document.querySelector('section');
                if (firstSection) {
                    console.log('Première section:', {
                        children: firstSection.children.length,
                        firstChild: firstSection.firstElementChild?.tagName,
                        firstChildStyle: firstSection.firstElementChild?.getAttribute('style')
                    });
                }
            };
            
            // Fonction de débogage pour analyser la structure des likes
            window.lessIsMoreDebugLikes = function() {
                console.log('=== DEBUG LIKES ===');
                
                // Chercher les éléments avec data-testid liés aux likes
                const likeTestIds = document.querySelectorAll('[data-testid*="like"], [data-testid*="likes"]');
                console.log('Éléments avec data-testid likes trouvés:', likeTestIds.length);
                likeTestIds.forEach((el, index) => {
                    if (index < 5) {
                        console.log(`Like testid ${index}:`, {
                            dataTestId: el.getAttribute('data-testid'),
                            tagName: el.tagName,
                            text: el.textContent?.substring(0, 50),
                            ariaLabel: el.getAttribute('aria-label')
                        });
                    }
                });
                
                // Chercher les aria-label contenant "like"
                const likeAriaLabels = document.querySelectorAll('[aria-label*="like" i]');
                console.log('Éléments avec aria-label likes trouvés:', likeAriaLabels.length);
                likeAriaLabels.forEach((el, index) => {
                    if (index < 5) {
                        console.log(`Like aria-label ${index}:`, {
                            ariaLabel: el.getAttribute('aria-label'),
                            tagName: el.tagName,
                            text: el.textContent?.substring(0, 50)
                        });
                    }
                });
                
                // Chercher les spans avec du texte de likes
                const likeSpans = document.querySelectorAll('span');
                const likeTextSpans = [];
                likeSpans.forEach(span => {
                    const text = span.textContent || span.innerText || '';
                    if (text.match(/^\\d+\\s*(like|likes|Like|Likes)$/i)) {
                        likeTextSpans.push(span);
                    }
                });
                console.log('Spans avec texte de likes trouvés:', likeTextSpans.length);
                likeTextSpans.forEach((span, index) => {
                    if (index < 5) {
                        console.log(`Like span ${index}:`, {
                            text: span.textContent,
                            tagName: span.tagName,
                            parent: span.parentElement?.tagName
                        });
                    }
                });
            };
            
            // Fonction spécifique pour masquer les stories
            window.lessIsMoreHideStories = function() {
                const storySelectors = [
                    '[data-testid="stories-container"]',
                    '[data-testid="stories"]',
                    '[data-testid="story"]',
                    '[data-testid="story-ring"]',
                    '[aria-label*="story" i]',
                    '[aria-label*="Story" i]',
                    '[aria-label*="STORIES" i]',
                    'div[style*="overflow-x: auto"]',
                    'div[style*="scrollbar-width"]',
                    'section > div > div:first-child',
                    'div[style*="cursor: pointer"][style*="border-radius"]'
                ];
                
                // Masquer avec CSS
                storySelectors.forEach(selector => {
                    const elements = document.querySelectorAll(selector);
                    elements.forEach(el => {
                        if (el.style.display !== 'none') {
                            el.style.setProperty('display', 'none', 'important');
                            // Marquer l'élément comme masqué par LessIsMore
                            el.setAttribute('data-lessismore-hidden', 'true');
                        }
                    });
                });
                
                // Masquer avec des sélecteurs plus génériques pour les stories
                const genericStorySelectors = [
                    'div[style*="border-radius"]',
                    'div[style*="cursor: pointer"]',
                    'div[role="button"]'
                ];
                
                genericStorySelectors.forEach(selector => {
                    const elements = document.querySelectorAll(selector);
                    elements.forEach(el => {
                        // Vérifier si l'élément ressemble à une story
                        if (el.querySelector('img') && 
                            (el.style.borderRadius || el.style.cursor === 'pointer') &&
                            el.offsetWidth > 50 && el.offsetHeight > 50) {
                            el.style.setProperty('display', 'none', 'important');
                            // Marquer l'élément comme masqué par LessIsMore
                            el.setAttribute('data-lessismore-hidden', 'true');
                        }
                    });
                });
                
                // Masquer les conteneurs de stories par position
                const firstSection = document.querySelector('section');
                if (firstSection && firstSection.firstElementChild) {
                    const firstChild = firstSection.firstElementChild;
                    if (firstChild.style.overflowX === 'auto' || 
                        firstChild.style.overflowX === 'scroll') {
                        firstChild.style.setProperty('display', 'none', 'important');
                        firstChild.setAttribute('data-lessismore-hidden', 'true');
                    }
                }
            };
            
            // Fonction pour restaurer l'affichage des stories
            window.lessIsMoreShowStories = function() {
                // Restaurer tous les éléments masqués par LessIsMore
                const hiddenElements = document.querySelectorAll('[data-lessismore-hidden="true"]');
                hiddenElements.forEach(el => {
                    el.style.removeProperty('display');
                    el.removeAttribute('data-lessismore-hidden');
                });
                
                console.log('Stories restaurées:', hiddenElements.length, 'éléments');
            };
            
            // Fonction pour masquer les compteurs de likes - très précise
            window.lessIsMoreHideLikes = function() {
                const likeSelectors = [
                    '[data-testid="like-count"]',
                    '[data-testid="likes-count"]',
                    '[data-testid="likes"]'
                ];
                
                // Masquer avec CSS - sélecteurs très précis
                likeSelectors.forEach(selector => {
                    const elements = document.querySelectorAll(selector);
                    elements.forEach(el => {
                        if (el.style.display !== 'none') {
                            el.style.setProperty('display', 'none', 'important');
                            el.setAttribute('data-lessismore-hidden', 'true');
                        }
                    });
                });
                
                // Masquer les liens vers les likes (plus précis)
                const likeLinks = document.querySelectorAll('a[href*="/liked_by/"], a[href*="/likes/"]');
                likeLinks.forEach(link => {
                    if (link.style.display !== 'none') {
                        link.style.setProperty('display', 'none', 'important');
                        link.setAttribute('data-lessismore-hidden', 'true');
                    }
                });
                
                // Masquer les aria-label très spécifiques aux compteurs de likes
                const ariaLabels = document.querySelectorAll('[aria-label]');
                ariaLabels.forEach(el => {
                    const ariaLabel = el.getAttribute('aria-label') || '';
                    // Seulement masquer si c'est vraiment un compteur de likes
                    if ((ariaLabel.includes('like') || ariaLabel.includes('Like') || ariaLabel.includes('LIKES')) &&
                        ariaLabel.includes('person') && 
                        (ariaLabel.includes('other') || ariaLabel.includes('person') || ariaLabel.includes('people'))) {
                        if (el.style.display !== 'none') {
                            el.style.setProperty('display', 'none', 'important');
                            el.setAttribute('data-lessismore-hidden', 'true');
                        }
                    }
                });
                
                // Masquer les spans qui sont clairement des compteurs de likes
                const allSpans = document.querySelectorAll('span');
                allSpans.forEach(span => {
                    const text = span.textContent || span.innerText || '';
                    // Seulement masquer si c'est un nombre suivi de "like" ou "likes"
                    if (text.match(/^\\d+\\s*(like|likes|Like|Likes)$/i)) {
                        if (span.style.display !== 'none') {
                            span.style.setProperty('display', 'none', 'important');
                            span.setAttribute('data-lessismore-hidden', 'true');
                        }
                    }
                });
                
                console.log('Filtre likes appliqué - éléments masqués:', document.querySelectorAll('[data-lessismore-hidden="true"]').length);
            };
            
            // Fonction pour restaurer l'affichage des likes
            window.lessIsMoreShowLikes = function() {
                // Restaurer tous les éléments masqués par LessIsMore
                const hiddenElements = document.querySelectorAll('[data-lessismore-hidden="true"]');
                hiddenElements.forEach(el => {
                    el.style.removeProperty('display');
                    el.removeAttribute('data-lessismore-hidden');
                });
                
                console.log('Likes restaurés:', hiddenElements.length, 'éléments');
            };
            
            // Fonction de débogage simplifiée pour analyser la structure des boutons For you/Following
            window.lessIsMoreDebugFollowing = function() {
                console.log('DEBUG FOLLOWING');
            };
            
            // Fonction pour masquer le bouton "For you" et forcer le mode Following
            window.lessIsMoreHideForYou = function() {
                try {
                    // Skip on login/account pages to prevent login loop on iPad
                    const currentUrl = window.location.href;
                    if (currentUrl.includes('/accounts/') || currentUrl.includes('/login') || currentUrl.includes('/challenge/') || currentUrl.includes('/consent/') || currentUrl.includes('/oauth/') || currentUrl.includes('/onetap/')) {
                        console.log('LessIsMore: Skip HideForYou on login page');
                        return;
                    }
                    // D'abord, rediriger vers la page Following si on n'y est pas déjà
                    if (!currentUrl.includes('variant=following')) {
                        console.log('Redirection vers Following');
                        // Essayer d'abord de cliquer sur le bouton Following
                        const followingButton = document.querySelector('[aria-label*="Following" i], [aria-label*="following" i]');
                        if (followingButton) {
                            console.log('Clic sur le bouton Following');
                            followingButton.click();
                        } else {
                            // Si pas de bouton, rediriger directement vers la bonne URL
                            window.location.href = 'https://www.instagram.com/?variant=following';
                        }
                        return; // Sortir de la fonction après redirection
                    }
                    
                    // Masquer les éléments "For you"
                    const forYouElements = document.querySelectorAll('[aria-label*="For you" i], [aria-label*="For You" i]');
                    forYouElements.forEach(function(el) {
                        if (el && el.style) {
                            el.style.setProperty('display', 'none', 'important');
                            el.setAttribute('data-lessismore-hidden', 'true');
                        }
                    });
                    
                    // Masquer les liens vers la page d'accueil (For you)
                    const homeLinks = document.querySelectorAll('a[href="/"]');
                    homeLinks.forEach(function(link) {
                        if (link && link.style) {
                            link.style.setProperty('display', 'none', 'important');
                            link.setAttribute('data-lessismore-hidden', 'true');
                        }
                    });
                    
                    // Masquer les onglets non sélectionnés
                    const tabs = document.querySelectorAll('[role="tab"]');
                    tabs.forEach(function(tab) {
                        if (tab && tab.getAttribute('aria-selected') === 'false') {
                            tab.style.setProperty('display', 'none', 'important');
                            tab.setAttribute('data-lessismore-hidden', 'true');
                        }
                    });
                    
                    console.log('Mode Following forcé');
                } catch (error) {
                    console.log('Erreur dans lessIsMoreHideForYou:', error.message);
                }
            };
            
            // Fonction pour restaurer l'affichage du bouton "For you"
            window.lessIsMoreShowForYou = function() {
                try {
                    // Skip on login/account pages to prevent login loop on iPad
                    const currentUrl = window.location.href;
                    if (currentUrl.includes('/accounts/') || currentUrl.includes('/login') || currentUrl.includes('/challenge/') || currentUrl.includes('/consent/') || currentUrl.includes('/oauth/') || currentUrl.includes('/onetap/')) {
                        console.log('LessIsMore: Skip ShowForYou on login page');
                        return;
                    }
                    // D'abord, rediriger vers la page For you si on n'y est pas déjà
                    if (!currentUrl.includes('variant=foryou')) {
                        console.log('Redirection vers For you');
                        // Essayer d'abord de cliquer sur le bouton For you
                        const forYouButton = document.querySelector('[aria-label*="For you" i], [aria-label*="For You" i]');
                        if (forYouButton) {
                            console.log('Clic sur le bouton For you');
                            forYouButton.click();
                        } else {
                            // Si pas de bouton, rediriger directement vers la bonne URL
                            window.location.href = 'https://www.instagram.com/?variant=foryou';
                        }
                        return; // Sortir de la fonction après redirection
                    }
                    
                    // Restaurer tous les éléments masqués par LessIsMore
                    const hiddenElements = document.querySelectorAll('[data-lessismore-hidden="true"]');
                    hiddenElements.forEach(function(el) {
                        if (el && el.style) {
                            el.style.removeProperty('display');
                            el.removeAttribute('data-lessismore-hidden');
                        }
                    });
                    
                    console.log('Bouton "For you" restauré');
                } catch (error) {
                    console.log('Erreur dans lessIsMoreShowForYou:', error.message);
                }
            };
            
            // Fonction pour masquer les posts suggérés dans le feed
            window.lessIsMoreHideSuggestedPosts = function() {
                try {
                    // Mots-clés de suggestion dans différentes langues
                    const suggestionKeywords = [
                        'Suggested for you',
                        'Suggéré pour vous',
                        'Suggerido para ti',
                        'Für dich vorgeschlagen',
                        'Sugerido para ti',
                        'Consigliato per te',
                        'Suggested',
                        'Suggéré',
                        'Voor jou aanbevolen'
                    ];
                    
                    // Parcourir tous les articles (posts) dans le feed
                    const articles = document.querySelectorAll('article');
                    let hiddenCount = 0;
                    
                    articles.forEach(article => {
                        // Vérifier si l'article contient un texte de suggestion
                        const articleText = article.innerText || article.textContent || '';
                        const isSuggested = suggestionKeywords.some(keyword => 
                            articleText.includes(keyword)
                        );
                        
                        if (isSuggested && article.style.display !== 'none') {
                            // Masquer l'article et son conteneur parent si nécessaire
                            article.style.setProperty('display', 'none', 'important');
                            article.setAttribute('data-lessismore-suggested-post', 'true');
                            hiddenCount++;
                            
                            // Vérifier le parent direct pour masquer le conteneur complet
                            const parent = article.parentElement;
                            if (parent && parent.children.length === 1) {
                                parent.style.setProperty('display', 'none', 'important');
                                parent.setAttribute('data-lessismore-suggested-post', 'true');
                            }
                        }
                    });
                    
                    // Chercher également les spans avec le texte de suggestion et masquer leurs parents articles
                    const allSpans = document.querySelectorAll('span, div');
                    allSpans.forEach(span => {
                        const text = span.innerText || span.textContent || '';
                        const isSuggestionText = suggestionKeywords.some(keyword => 
                            text.trim() === keyword || text.includes(keyword)
                        );
                        
                        if (isSuggestionText) {
                            // Remonter pour trouver l'article parent
                            let parentArticle = span.closest('article');
                            if (parentArticle && parentArticle.style.display !== 'none') {
                                parentArticle.style.setProperty('display', 'none', 'important');
                                parentArticle.setAttribute('data-lessismore-suggested-post', 'true');
                                hiddenCount++;
                            }
                        }
                    });
                    
                    if (hiddenCount > 0) {
                        console.log('LessIsMore: Posts suggérés masqués:', hiddenCount);
                    }
                } catch (error) {
                    console.log('Erreur dans lessIsMoreHideSuggestedPosts:', error.message);
                }
            };
            
            // Fonction pour restaurer l'affichage des posts suggérés
            window.lessIsMoreShowSuggestedPosts = function() {
                try {
                    const hiddenPosts = document.querySelectorAll('[data-lessismore-suggested-post="true"]');
                    hiddenPosts.forEach(el => {
                        el.style.removeProperty('display');
                        el.removeAttribute('data-lessismore-suggested-post');
                    });
                    
                    console.log('LessIsMore: Posts suggérés restaurés:', hiddenPosts.length);
                } catch (error) {
                    console.log('Erreur dans lessIsMoreShowSuggestedPosts:', error.message);
                }
            };
            
            // Les gestionnaires d'événements du bouton éclair ont été supprimés
            
            // Fonction pour appliquer tous les filtres depuis l'app iOS
            window.lessIsMoreApplyAllFilters = function(filters) {
                console.log('Application des filtres:', filters);
                
                // D'abord, restaurer tous les éléments masqués
                const hiddenElements = document.querySelectorAll('[data-lessismore-hidden="true"]');
                hiddenElements.forEach(el => {
                    el.style.removeProperty('display');
                    el.removeAttribute('data-lessismore-hidden');
                });
                
                // Ensuite, appliquer les filtres actifs
                Object.keys(filters).forEach(filterType => {
                    window.lessIsMoreToggleFilter(filterType, filters[filterType]);
                });
                
                // Appliquer un masquage supplémentaire des stories si activé
                if (filters.stories) {
                    setTimeout(() => {
                        window.lessIsMoreHideStories();
                    }, 100);
                }
                
                // Appliquer un masquage supplémentaire du bouton "For you" si activé
                if (filters.following) {
                    setTimeout(() => {
                        window.lessIsMoreHideForYou();
                    }, 100);
                }
                
                // Appliquer un masquage supplémentaire des posts suggérés si activé
                if (filters.suggestedPosts) {
                    setTimeout(() => {
                        window.lessIsMoreHideSuggestedPosts();
                    }, 100);
                }
            };
            
            // Observer les mutations DOM pour détecter les nouvelles stories et posts suggérés
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                        // Vérifier si le filtre stories est activé
                        if (document.body.classList.contains('lessismore-hidden-stories')) {
                            setTimeout(() => {
                                window.lessIsMoreHideStories();
                            }, 25);
                        }
                        
                        // Vérifier si le filtre suggestedPosts est activé
                        if (document.body.classList.contains('lessismore-hidden-suggestedPosts')) {
                            setTimeout(() => {
                                window.lessIsMoreHideSuggestedPosts();
                            }, 25);
                        }
                    }
                });
            });
            
            // Démarrer l'observation
            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
            
            // Nettoyage continu des stories, likes et following si les filtres sont activés
            setInterval(function() {
                // Skip on login/account pages to prevent login loop on iPad
                var currentHref = window.location.href;
                if (currentHref.includes('/accounts/') || currentHref.includes('/login') || currentHref.includes('/challenge/') || currentHref.includes('/consent/') || currentHref.includes('/oauth/') || currentHref.includes('/onetap/')) {
                    return;
                }
                // Gestion des stories
                if (document.body.classList.contains('lessismore-hidden-stories')) {
                    window.lessIsMoreHideStories();
                } else {
                    // Si le filtre stories est désactivé, s'assurer que les stories sont visibles
                    const hiddenStories = document.querySelectorAll('[data-lessismore-hidden="true"]');
                    if (hiddenStories.length > 0) {
                        window.lessIsMoreShowStories();
                    }
                }
                
                // Gestion des likes
                if (document.body.classList.contains('lessismore-hidden-likes')) {
                    window.lessIsMoreHideLikes();
                } else {
                    // Si le filtre likes est désactivé, s'assurer que les likes sont visibles
                    const hiddenLikes = document.querySelectorAll('[data-lessismore-hidden="true"]');
                    if (hiddenLikes.length > 0) {
                        window.lessIsMoreShowLikes();
                    }
                }
                
                // Gestion du mode Following
                if (document.body.classList.contains('lessismore-hidden-following')) {
                    window.lessIsMoreHideForYou();
                } else {
                    // Si le filtre following est désactivé, s'assurer que le bouton "For you" est visible
                    const hiddenForYou = document.querySelectorAll('[data-lessismore-hidden="true"]');
                    if (hiddenForYou.length > 0) {
                        window.lessIsMoreShowForYou();
                    }
                }
                
                // Gestion des posts suggérés dans le feed
                if (document.body.classList.contains('lessismore-hidden-suggestedPosts')) {
                    window.lessIsMoreHideSuggestedPosts();
                } else {
                    // Si le filtre suggestedPosts est désactivé, s'assurer que les posts suggérés sont visibles
                    const hiddenSuggestions = document.querySelectorAll('[data-lessismore-suggested-post="true"]');
                    if (hiddenSuggestions.length > 0) {
                        window.lessIsMoreShowSuggestedPosts();
                    }
                }
            }, 1000);
            
            // Préchargement des filtres actifs depuis l'app iOS (injectés au démarrage)
            const activeFilters = window.__lessIsMoreInitialFilters || {
                reels: false,
                explore: false,
                stories: false,
                suggestions: false,
                suggestedPosts: false,
                likes: false,
                following: false,
                messages: false
            };

            // Fonction pour appliquer les filtres dès que le body est disponible
            const applyFiltersWhenReady = () => {
                if (!document.body) {
                    // Attendre que le body soit disponible
                    requestAnimationFrame(applyFiltersWhenReady);
                    return;
                }

                // Skip on login/account pages to prevent login loop on iPad
                var pageUrl = window.location.href;
                if (pageUrl.includes('/accounts/') || pageUrl.includes('/login') || pageUrl.includes('/challenge/') || pageUrl.includes('/consent/') || pageUrl.includes('/oauth/') || pageUrl.includes('/onetap/')) {
                    console.log('LessIsMore: Skip filters on login page');
                    return;
                }

                // Redirection automatique si le filtre Following est activé
                // Skip redirect on login/account pages to prevent login loop on iPad
                var isLoginPage = window.location.href.includes('/accounts/') ||
                                  window.location.href.includes('/login') ||
                                  window.location.href.includes('/challenge/') ||
                                  window.location.href.includes('/consent/') ||
                                  window.location.href.includes('/oauth/') ||
                                  window.location.href.includes('/onetap/');
                if (activeFilters.following && !window.location.href.includes('variant=following') && !isLoginPage) {
                    console.log('Redirection automatique vers Following');
                    window.location.href = 'https://www.instagram.com/?variant=following';
                    return;
                }

                // Application immédiate des filtres préchargés
                Object.keys(activeFilters).forEach(filterType => {
                    if (activeFilters[filterType]) {
                        window.lessIsMoreToggleFilter(filterType, true);
                    }
                });

                console.log('LessIsMore: Filtres initiaux appliqués:', activeFilters);
            };

            // Lancer l'application des filtres
            applyFiltersWhenReady();
            
            // --- Tracker de catégorie ---
            (function() {
                const getCategory = () => {
                    const path = window.location.pathname;
                    const url = window.location.href;
                    
                    if (path === '/' || path.includes('/direct/') || path.includes('/p/')) {
                        if (path.includes('/direct/')) return 'Messages';
                        if (url.includes('variant=following') || path === '/' || path.includes('/p/')) return 'Feed';
                    }
                    if (path.includes('/reels/')) return 'Reels';
                    if (path.includes('/stories/')) return 'Stories';
                    if (path.includes('/explore/')) return 'Explore';
                    
                    return 'Other';
                };

                const reportCategory = () => {
                    const category = getCategory();
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lessIsMoreTracker) {
                        window.webkit.messageHandlers.lessIsMoreTracker.postMessage(category);
                    }
                };

                // Observer les changements d'URL
                let lastUrl = location.href;
                const observer = new MutationObserver(() => {
                    if (location.href !== lastUrl) {
                        lastUrl = location.href;
                        reportCategory();
                    }
                });
                observer.observe(document, {subtree: true, childList: true});

                // Overrides pour pushState et replaceState (SPA navigation)
                const originalPushState = history.pushState;
                const originalReplaceState = history.replaceState;
                history.pushState = function() {
                    originalPushState.apply(this, arguments);
                    reportCategory();
                };
                history.replaceState = function() {
                    originalReplaceState.apply(this, arguments);
                    reportCategory();
                };
                window.addEventListener('popstate', reportCategory);

                // Rapport initial
                setTimeout(reportCategory, 1000);
            })();

            console.log('LessIsMore: Bloqueur de contenu initialisé avec succès');
        })();
        """
    }
    
    static func getToggleScript(for filterType: FilterType) -> String {
        let enabled = filterType.isEnabled
        return """
        if (window.lessIsMoreToggleFilter) {
            window.lessIsMoreToggleFilter('\(filterType.rawValue)', \(enabled));
        }
        """
    }
    
    static func getApplyAllFiltersScript() -> String {
        let filters = FilterType.allCases.map { "\"\($0.rawValue)\": \($0.isEnabled)" }.joined(separator: ", ")
        return """
        if (window.lessIsMoreApplyAllFilters) {
            window.lessIsMoreApplyAllFilters({\(filters)});
        }
        """
    }
    
    // MARK: - Theme Application
    
    static func getApplyThemeScript(theme: InstagramTheme) -> String {
        // Remove theme if default
        if theme == .default {
            return """
            (function() {
                const existingStyle = document.getElementById('lessismore-theme-style');
                if (existingStyle) {
                    existingStyle.remove();
                }
                document.body.classList.remove('lessismore-themed');
                console.log('LessIsMore: Thème par défaut restauré');
            })();
            """
        }
        
        let bgColor = theme.backgroundColor
        let cardColor = theme.cardColor
        let accentColor = theme.accentColor
        
        return """
        (function() {
            // Supprimer l'ancien style de thème si présent
            const existingStyle = document.getElementById('lessismore-theme-style');
            if (existingStyle) {
                existingStyle.remove();
            }
            
            // Créer le nouveau style de thème
            const themeStyle = document.createElement('style');
            themeStyle.id = 'lessismore-theme-style';
            themeStyle.textContent = `
                /* LessIsMore Custom Theme: \(theme.rawValue) */
                
                /* ===== BACKGROUNDS PRINCIPAUX ===== */
                body,
                html,
                #react-root,
                #react-root > div,
                #react-root > section,
                main,
                div[role="main"],
                ._aa_i,
                ._aagu,
                ._aak0,
                ._aak1 {
                    background-color: \(bgColor) !important;
                    background: \(bgColor) !important;
                }
                
                /* ===== HEADERS ET NAVIGATION / TAB BAR ===== */
                nav,
                header,
                ._aak5,
                ._aak6,
                ._aak4,
                ._ab8w,
                div[role="banner"],
                div[role="navigation"],
                /* Bottom Tab Bar Instagram - AGGRESSIVE SELECTORS */
                ._acao,
                ._acaq,
                ._acar,
                ._acat,
                ._acau,
                div[role="tablist"],
                [role="tablist"],
                [role="tablist"] > div,
                /* Fixed/Sticky bottom bar */
                div[style*="position: fixed"],
                div[style*="position:fixed"],
                div[style*="bottom: 0"],
                div[style*="bottom:0"],
                /* Mobile footer navigation */
                footer,
                ._abl-,
                ._ablz,
                ._abm0,
                ._abm1,
                ._abn_,
                /* All fixed positioning elements at bottom */
                div[style*="z-index"][style*="bottom"] {
                    background-color: \(cardColor) !important;
                    background: \(cardColor) !important;
                }
                
                /* ===== STORIES CONTAINER ===== */
                /* Zone derrière les stories - SAME COLOR AS POSTS */
                section > div:first-child,
                div[style*="overflow-x: auto"],
                div[style*="overflow-x:auto"],
                div[style*="overflow: auto"],
                div[style*="scrollbar-width"],
                ._aac4,
                ._aac5,
                ._aacl,
                ._aack,
                /* Container des stories circulaires */
                div:has(> canvas),
                div:has(> div > canvas) {
                    background-color: \(cardColor) !important;
                    background: \(cardColor) !important;
                }
                
                /* ===== POSTS ET ARTICLES ===== */
                article,
                article > div,
                ._aatb,
                ._aam1,
                ._acan,
                ._acap,
                ._acas,
                ._acav,
                ._ae1h,
                ._ae1i {
                    background-color: \(cardColor) !important;
                    background: \(cardColor) !important;
                }
                
                /* ===== DESCRIPTIONS ET TEXTES (zone derrière le texte) ===== */
                /* Conteneurs de texte de description */
                article span,
                article div,
                ._a9zs,
                ._a9zt,
                ._a9zu,
                ._aade,
                ._aacl > div,
                /* Zone de légende/description */
                div[style*="padding-left: 16px"],
                div[style*="padding: 0 16px"],
                h2 + div,
                a + span,
                /* Arrière-plan des textes */
                ._aagv,
                ._aagw {
                    background-color: transparent !important;
                    background: transparent !important;
                }
                
                /* ===== TOUS LES FONDS BLANCS ===== */
                div[style*="background-color: rgb(255, 255, 255)"],
                div[style*="background-color:rgb(255, 255, 255)"],
                div[style*="background-color: white"],
                div[style*="background-color:white"],
                div[style*="background: white"],
                div[style*="background:white"],
                div[style*="background: rgb(255, 255, 255)"],
                div[style*="background:rgb(255, 255, 255)"],
                span[style*="background-color: rgb(255, 255, 255)"],
                section[style*="background"],
                /* Classes courantes de fond blanc */
                ._aa61,
                ._ab8w {
                    background-color: \(cardColor) !important;
                    background: \(cardColor) !important;
                }
                
                /* ===== SIDEBAR ===== */
                aside,
                ._aal_,
                div[style*="position: sticky"]:not([style*="bottom"]) {
                    background-color: \(bgColor) !important;
                    background: \(bgColor) !important;
                }
                
                /* ===== MODALS ET OVERLAYS ===== */
                div[role="dialog"],
                div[role="dialog"] > div,
                div[role="dialog"] > div:first-child,
                ._aaz6,
                ._ab8s {
                    background-color: \(cardColor) !important;
                    background: \(cardColor) !important;
                }
                
                /* ===== INPUT FIELDS ===== */
                input,
                textarea,
                [contenteditable="true"] {
                    background-color: \(cardColor) !important;
                    background: \(cardColor) !important;
                    border-color: \(accentColor)33 !important;
                }
                
                /* ===== POIGNÉE/SWIPE INDICATOR (si visible) ===== */
                div[style*="border-radius: 2.5px"],
                div[style*="border-radius:2.5px"],
                ._abm0 {
                    background-color: \(accentColor)66 !important;
                }
                
                /* ===== COMMENTAIRES ===== */
                ul,
                li,
                ._a9ym,
                ._a9yn {
                    background-color: transparent !important;
                }
                
                /* ===== CARROUSEL INFÉRIEUR ===== */
                div[style*="flex-direction: row"][style*="overflow"],
                ._aahi,
                ._aahj {
                    background-color: \(bgColor) !important;
                    background: \(bgColor) !important;
                }
                
                /* ===== SCROLLBAR ===== */
                ::-webkit-scrollbar {
                    width: 8px;
                    background-color: \(bgColor) !important;
                }
                ::-webkit-scrollbar-thumb {
                    background-color: \(accentColor)44 !important;
                    border-radius: 4px;
                }
                ::-webkit-scrollbar-track {
                    background-color: \(bgColor) !important;
                }
                
                /* ===== UNIVERSAL CATCH-ALL ===== */
                /* Forcer les div enfants directs du body */
                body > div,
                body > div > div,
                body > div > div > div {
                    background-color: \(bgColor) !important;
                }
                
                /* ===== MARKER ===== */
                body.lessismore-themed {
                    /* Theme active marker */
                }
            `;
            
            document.head.appendChild(themeStyle);
            document.body.classList.add('lessismore-themed');
            
            // Forcer l'application sur le body inline style
            document.body.style.backgroundColor = '\(bgColor)';
            document.documentElement.style.backgroundColor = '\(bgColor)';
            
            console.log('LessIsMore: Thème appliqué - \(theme.rawValue)');
        })();
        """
    }
}
