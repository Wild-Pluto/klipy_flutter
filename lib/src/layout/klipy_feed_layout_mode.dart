/// How [KlipyTabView] lays out the mixed GIF / ad feed.
enum KlipyFeedLayoutMode {
  /// Two-column staggered sliver with optional full-span rows (legacy).
  mixedMasonry,

  /// Precomputed rows (Klipy iOS demo style); avoids column "holes" before
  /// wide ads.
  rowBased,
}
