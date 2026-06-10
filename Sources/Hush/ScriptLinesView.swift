import HushCore
import SwiftUI

/// Renders parsed Markdown lines: paragraphs and headings centered, lists with markers,
/// blockquotes with a bar, code blocks boxed, and rules as dividers. Each word keeps its index
/// so voice tracking can highlight and scroll to it.
struct ScriptLinesView: View {
    let lines: [ScriptLine]
    let currentTokenIndex: Int?
    let settings: TeleprompterSettings

    var body: some View {
        VStack(alignment: .center, spacing: settings.lineSpacing + 8) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                row(line)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .scaleEffect(x: settings.mirrored ? -1 : 1, y: 1)
    }

    @ViewBuilder
    private func row(_ line: ScriptLine) -> some View {
        switch line.kind {
        case .thematicBreak:
            Divider().frame(maxWidth: 140)
        case .listItem(let ordinal):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(ordinal.map { "\($0)." } ?? "•")
                    .font(.system(size: settings.fontSize, design: .rounded))
                    .foregroundStyle(settings.theme.textColor.opacity(0.6))
                flow(line.tokens)
            }
            .padding(.leading, CGFloat(line.indent) * 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .blockQuote:
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(settings.theme.textColor.opacity(0.4))
                    .frame(width: 3)
                flow(line.tokens)
            }
            .padding(.leading, CGFloat(line.indent) * 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .code:
            flow(line.tokens)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(settings.theme.textColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        case .paragraph, .heading:
            flow(line.tokens)
        }
    }

    private func flow(_ tokens: [Token]) -> some View {
        FlowLayout(spacing: 3, lineSpacing: settings.lineSpacing) {
            ForEach(tokens, id: \.index) { token in
                if let cue = Cue.parse(token.text) {
                    CueChip(cue: cue, settings: settings).id(token.index)
                } else {
                    WordView(token: token, currentTokenIndex: currentTokenIndex, settings: settings)
                }
            }
        }
    }
}

struct WordView: View {
    let token: Token
    let currentTokenIndex: Int?
    let settings: TeleprompterSettings

    var body: some View {
        let isCurrent = token.index == currentTokenIndex
        let size = settings.fontSize * headingScale(token.headingLevel)
        let design: Font.Design = token.code ? .monospaced : .rounded
        Text(token.text)
            .font(.system(size: size, weight: weight(isCurrent), design: design))
            .italic(token.italic)
            .strikethrough(token.strikethrough)
            .foregroundStyle(color(isCurrent))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                isCurrent ? AnyShapeStyle(settings.highlight.color) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 7)
            )
            .id(token.index)
    }

    private func weight(_ isCurrent: Bool) -> Font.Weight {
        if settings.boldText || token.bold || token.headingLevel > 0 { return .bold }
        return isCurrent ? .semibold : .medium
    }

    private func color(_ isCurrent: Bool) -> Color {
        if isCurrent { return settings.highlight.textColor }
        if settings.focusDimming, let current = currentTokenIndex, token.index < current {
            return settings.theme.textColor.opacity(0.3)
        }
        return settings.theme.textColor.opacity(0.9)
    }

    private func headingScale(_ level: Int) -> Double {
        switch level {
        case 1: 1.5
        case 2: 1.3
        case 3: 1.15
        case 4...: 1.05
        default: 1
        }
    }
}

struct CueChip: View {
    let cue: Cue
    let settings: TeleprompterSettings

    var body: some View {
        Label(cue.label, systemImage: cue.symbol)
            .font(.system(size: settings.fontSize * 0.68, weight: .semibold, design: .rounded))
            .foregroundStyle(settings.theme.textColor.opacity(0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(settings.theme.textColor.opacity(0.14), in: Capsule())
    }
}

/// A centered wrapping layout: each word flows to the next line when it runs out of width, and
/// every row is horizontally centered.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let computed = layout(maxWidth: maxWidth, sizes: sizes)
        return CGSize(width: proposal.width ?? computed.contentWidth, height: computed.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let computed = layout(maxWidth: bounds.width, sizes: sizes)
        var y = bounds.minY
        for line in computed.rows {
            let wordsWidth = line.indices.reduce(0) { $0 + sizes[$1].width }
            let rowWidth = wordsWidth + spacing * CGFloat(max(0, line.indices.count - 1))
            var x = bounds.minX + (bounds.width - rowWidth) / 2
            for index in line.indices {
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(sizes[index])
                )
                x += sizes[index].width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var height: CGFloat = 0
    }

    private struct Result {
        var rows: [Row]
        var height: CGFloat
        var contentWidth: CGFloat
    }

    private func layout(maxWidth: CGFloat, sizes: [CGSize]) -> Result {
        var rows: [Row] = []
        var row = Row()
        var x: CGFloat = 0
        var contentWidth: CGFloat = 0
        for (index, size) in sizes.enumerated() {
            if x + size.width > maxWidth, !row.indices.isEmpty {
                rows.append(row)
                contentWidth = max(contentWidth, x - spacing)
                row = Row()
                x = 0
            }
            row.indices.append(index)
            row.height = max(row.height, size.height)
            x += size.width + spacing
        }
        if !row.indices.isEmpty {
            rows.append(row)
            contentWidth = max(contentWidth, x - spacing)
        }
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
        return Result(rows: rows, height: height, contentWidth: max(0, contentWidth))
    }
}
