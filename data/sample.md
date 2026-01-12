# Sample Markdown Document

This is a sample document to test Pandoc conversions.

## Features

### Text Formatting

You can make text **bold**, *italic*, or ***both***. You can also use ~~strikethrough~~ and `inline code`.

### Lists

Unordered list:
- Item one
- Item two
  - Nested item
  - Another nested item
- Item three

Ordered list:
1. First item
2. Second item
3. Third item

### Code Blocks

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .padding()
    }
}
```

### Tables

| Format | Input | Output |
|--------|-------|--------|
| Markdown | Yes | Yes |
| HTML | Yes | Yes |
| PDF | No | Yes |
| DOCX | Yes | Yes |

### Links and Images

Visit [Pandoc](https://pandoc.org) for more information.

### Blockquotes

> Pandoc is a universal document converter.
> It can convert between many markup formats.
>
> — John MacFarlane

### Math

Inline math: $E = mc^2$

Block math:

$$
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
$$

### Footnotes

This is a sentence with a footnote.[^1]

[^1]: This is the footnote content.

---

*Document created for Pandoc iOS testing.*
