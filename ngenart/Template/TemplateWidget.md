<!--import WidgetKit-->
<!--import SwiftUI-->
<!---->
<!--struct Provider<Renderer: TemplateArtRenderer>: TimelineProvider {-->
<!--    let renderer: Renderer-->
<!--    -->
<!--    func placeholder(in context: Context) -> SimpleEntry {-->
<!--        SimpleEntry(date: Date(), value: 0)-->
<!--    }-->
<!---->
<!--    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {-->
<!--        fetchData { value in-->
<!--            let entry = SimpleEntry(date: Date(), value: value)-->
<!--            completion(entry)-->
<!--        }-->
<!--    }-->
<!---->
<!--    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {-->
<!--        fetchData { value in-->
<!--            let entry = SimpleEntry(date: Date(), value: value)-->
<!--            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!-->
<!--            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))-->
<!--            completion(timeline)-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    func fetchData(completion: @escaping (Double) -> Void) {-->
<!--        renderer.fetchData()-->
<!--        completion(renderer.data)-->
<!--    }-->
<!--}-->
<!---->
<!--struct SimpleEntry: TimelineEntry {-->
<!--    let date: Date-->
<!--    let value: Double-->
<!--}-->
<!---->
<!--struct TemplateArtWidgetEntryView<Renderer: TemplateArtRenderer>: View {-->
<!--    var entry: Provider<Renderer>.Entry-->
<!--    let renderer: Renderer-->
<!--    @Environment(\.widgetFamily) var family-->
<!---->
<!--    var body: some View {-->
<!--        ZStack {-->
<!--            Color.clear // This ensures the widget has a background-->
<!--            Image(uiImage: renderer.renderArt(size: widgetSize))-->
<!--                .resizable()-->
<!--                .aspectRatio(contentMode: .fit)-->
<!--        }-->
<!--        .containerBackground(for: .widget) {-->
<!--            Color.clear // This sets the container background-->
<!--        }-->
<!--    }-->
<!--    -->
<!--    var widgetSize: CGSize {-->
<!--        switch family {-->
<!--        case .systemSmall:-->
<!--            return CGSize(width: 158, height: 158)-->
<!--        case .systemMedium:-->
<!--            return CGSize(width: 338, height: 158)-->
<!--        case .systemLarge:-->
<!--            return CGSize(width: 338, height: 338)-->
<!--        @unknown default:-->
<!--            return CGSize(width: 338, height: 158)-->
<!--        }-->
<!--    }-->
<!--}-->
<!---->
<!--struct TemplateArtWidget<Renderer: TemplateArtRenderer>: Widget {-->
<!--    let kind: String-->
<!--    let renderer: Renderer-->
<!---->
<!--    var body: some WidgetConfiguration {-->
<!--        StaticConfiguration(kind: kind, provider: Provider(renderer: renderer)) { entry in-->
<!--            TemplateArtWidgetEntryView(entry: entry, renderer: renderer)-->
<!--        }-->
<!--        .configurationDisplayName(renderer.artPiece.title)-->
<!--        .description(renderer.artPiece.description)-->
<!--        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])-->
<!--    }-->
<!--}-->
<!---->
<!--#Preview {-->
<!--    TemplateArtWidgetEntryView(entry: SimpleEntry(date: Date(), value: 236.9), renderer: PreviewRenderer())-->
<!--        .previewContext(WidgetPreviewContext(family: .systemMedium))-->
<!--}-->
<!---->
<!--// This is just for the preview, you'll need to implement an actual renderer-->
<!--class PreviewRenderer: TemplateArtRenderer {-->
<!--    override func renderArt(size: CGSize) -> UIImage {-->
<!--        // Implement a simple preview rendering-->
<!--        let renderer = UIGraphicsImageRenderer(size: size)-->
<!--        return renderer.image { ctx in-->
<!--            // Draw a simple placeholder-->
<!--            UIColor.gray.setFill()-->
<!--            ctx.fill(CGRect(origin: .zero, size: size))-->
<!--            -->
<!--            let text = "Preview: \(data)"-->
<!--            text.draw(at: CGPoint(x: 10, y: 10), withAttributes: [.foregroundColor: UIColor.white])-->
<!--        }-->
<!--    }-->
<!--}-->
