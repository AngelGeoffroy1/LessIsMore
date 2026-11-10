//
//  YouTubeBlocker.swift
//  LessIsMore
//
//  Content filters for mobile YouTube (m.youtube.com).
//  Exposes the same JS API as the Instagram script (lessIsMoreToggleFilter /
//  lessIsMoreApplyAllFilters), so WebViewManager drives both the same way.
//

import Foundation

enum YouTubeBlocker {

    static func getBlockingScript() -> String {
        let initial = FilterType.allCases
            .filter { $0.platform == .youtube }
            .map { "\"\($0.rawValue)\": \($0.isEnabled)" }
            .joined(separator: ", ")

        return """
        (function() {
            // YouTube-only script
            if (!/(^|\\.)youtube\\.com$/.test(location.hostname)) { return; }
            if (window.__lessIsMoreYouTube) { return; }
            window.__lessIsMoreYouTube = true;

            const state = { youtubeShorts: false };
            Object.assign(state, {\(initial)});

            const HIDE_SHORTS = 'lessismore-yt-hide-shorts';
            const style = document.createElement('style');
            style.textContent = `
                /* Shorts shelves on Home, Subscriptions, Search, channel pages */
                .${HIDE_SHORTS} ytm-reel-shelf-renderer,
                .${HIDE_SHORTS} ytm-rich-section-renderer:has(ytm-reel-shelf-renderer),
                .${HIDE_SHORTS} ytm-rich-section-renderer:has(ytm-shorts-lockup-view-model),
                .${HIDE_SHORTS} grid-shelf-view-model:has(ytm-shorts-lockup-view-model),
                .${HIDE_SHORTS} ytm-shorts-lockup-view-model,
                .${HIDE_SHORTS} ytm-reel-item-renderer,
                /* Individual Shorts tagged by JS (lists, search results) */
                .${HIDE_SHORTS} [data-lessismore-yt-short="true"],
                /* "Shorts" tab in the bottom navigation bar */
                .${HIDE_SHORTS} ytm-pivot-bar-item-renderer:has(.pivot-shorts),
                .${HIDE_SHORTS} ytm-pivot-bar-item-renderer:has(a[href^="/shorts"]) {
                    display: none !important;
                }
            `;
            (document.head || document.documentElement).appendChild(style);

            const shortsItemSelector = [
                'ytm-video-with-context-renderer',
                'ytm-rich-item-renderer',
                'ytm-compact-video-renderer',
                'ytm-shorts-lockup-view-model',
                'ytm-reel-item-renderer'
            ].join(', ');

            function tagShortsItems() {
                if (!state.youtubeShorts) { return; }
                document.querySelectorAll('a[href^="/shorts/"]').forEach(link => {
                    const item = link.closest(shortsItemSelector);
                    if (item) { item.setAttribute('data-lessismore-yt-short', 'true'); }
                });
            }

            // Opening a Short (shared link, notification...) plays it in the normal player instead
            function redirectShortsPage() {
                if (!state.youtubeShorts) { return; }
                const match = location.pathname.match(/^\\/shorts\\/([^/?#]+)/);
                if (match) { location.replace('/watch?v=' + match[1]); }
            }

            function applyState() {
                document.documentElement.classList.toggle(HIDE_SHORTS, !!state.youtubeShorts);
                redirectShortsPage();
                tagShortsItems();
            }

            window.lessIsMoreToggleFilter = function(filterType, enabled) {
                if (!(filterType in state)) { return; }
                state[filterType] = !!enabled;
                applyState();
            };

            window.lessIsMoreApplyAllFilters = function(filters) {
                Object.keys(state).forEach(key => {
                    if (key in filters) { state[key] = !!filters[key]; }
                });
                applyState();
            };

            // YouTube is a single-page app: re-check after each in-app navigation and as content loads
            ['pushState', 'replaceState'].forEach(method => {
                const original = history[method];
                history[method] = function() {
                    const result = original.apply(this, arguments);
                    setTimeout(applyState, 0);
                    return result;
                };
            });
            window.addEventListener('popstate', applyState);
            setInterval(tagShortsItems, 1000);

            applyState();

            // Usage tracking: YouTube time is counted as "Other"
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lessIsMoreTracker) {
                window.webkit.messageHandlers.lessIsMoreTracker.postMessage('Other');
            }
        })();
        """
    }
}
