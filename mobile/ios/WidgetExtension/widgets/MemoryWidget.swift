import AppIntents
import SwiftUI
import WidgetKit

struct ImmichMemoryProvider: TimelineProvider {
  func getYearDifferenceSubtitle(assetYear: Int) -> String {
    let currentYear = Calendar.current.component(.year, from: Date.now)
    // construct a "X years ago" subtitle
    let yearDifference = currentYear - assetYear

    return "\(yearDifference) year\(yearDifference == 1 ? "" : "s") ago"
  }

  func placeholder(in context: Context) -> ImageEntry {
    ImageEntry(date: Date(), image: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping @Sendable (ImageEntry) -> Void
  ) {
    let cacheKey = "memory_\(context.family.rawValue)"

    Task {
      guard let api = try? await ImmichAPI() else {
        completion(ImageEntry.handleCacheFallback(for: cacheKey, error: .noLogin).entries.first!)
        return
      }

      guard let memories = try? await api.fetchMemory(for: Date.now)
      else {
        completion(ImageEntry.handleCacheFallback(for: cacheKey).entries.first!)
        return
      }

      for memory in memories {
        if let asset = memory.assets.first(where: { $0.type == .image }),
          var entry = try? await ImageEntry.build(
            api: api,
            asset: asset,
            dateOffset: 0,
            subtitle: getYearDifferenceSubtitle(assetYear: memory.data.year)
          )
        {
          entry.resize()
          completion(entry)
          return
        }
      }

      // fallback to random image
      guard
        let randomImage = try? await api.fetchSearchResults(
          with: SearchFilters(size: 1)
        ).first,
        var imageEntry = try? await ImageEntry.build(
          api: api,
          asset: randomImage,
          dateOffset: 0
        )
      else {
        completion(ImageEntry.handleCacheFallback(for: cacheKey).entries.first!)
        return
      }

      imageEntry.resize()
      completion(imageEntry)
    }
  }

  func getTimeline(
    in context: Context,
    completion: @escaping @Sendable (Timeline<ImageEntry>) -> Void
  ) {
    Task {
      var entries: [ImageEntry] = []
      let now = Date()

      let cacheKey = "memory_\(context.family.rawValue)"

      guard let api = try? await ImmichAPI() else {
        completion(
          ImageEntry.handleCacheFallback(for: cacheKey, error: .noLogin)
        )
        return
      }

      let memories = try await api.fetchMemory(for: Date.now)

      await withTaskGroup(of: ImageEntry?.self) { group in
        var totalAssets = 0

        for memory in memories {
          for asset in memory.assets {
            if asset.type == .image && totalAssets < 12 {
              group.addTask {
                try? await ImageEntry.build(
                  api: api,
                  asset: asset,
                  dateOffset: totalAssets,
                  subtitle: getYearDifferenceSubtitle(
                    assetYear: memory.data.year
                  )
                )
              }

              totalAssets += 1
            }
          }
        }

        for await result in group {
          if let entry = result {
            entries.append(entry)
          }
        }
      }

      // If we didnt add any memory images (some failure occured or no images in memory),
      // default to 12 hours of random photos
      if entries.count == 0 {
        entries.append(
          contentsOf: (try? await generateRandomEntries(
            api: api,
            now: now,
            count: 12
          )) ?? []
        )
      }

      // If we fail to fetch images, we still want to add an entry
      // with a nil image and an error
      if entries.count == 0 {
        completion(ImageEntry.handleCacheFallback(for: cacheKey))
        return
      }

      // Resize all images to something that can be stored by iOS
      for i in entries.indices {
        entries[i].resize()
      }

      // cache the last image
      try? entries.last!.cache(for: cacheKey)

      completion(Timeline(entries: entries, policy: .atEnd))
    }
  }
}

struct ImmichMemoryWidget: Widget {
  let kind: String = "com.immich.widget.memory"

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: ImmichMemoryProvider()
    ) { entry in
      ImmichWidgetView(entry: entry)
        .containerBackground(.regularMaterial, for: .widget)
    }
    // allow image to take up entire widget
    .contentMarginsDisabled()

    // widget picker info
    .configurationDisplayName("Memories")
    .description("See memories from Immich.")
  }
}
