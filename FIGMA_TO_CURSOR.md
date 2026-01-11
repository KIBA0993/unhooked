# Figma to Cursor UI Workflow

## 🎨 How to Use Figma Designs to Build UI in Cursor

This guide shows you how to turn Figma designs into working Swift/SwiftUI code using Cursor AI.

---

## Method 1: Screenshot + AI Description (What We Just Did!)

### Step 1: Export Design from Figma
1. Open your Figma file
2. Select the frame/screen you want to implement
3. Take a screenshot or export as PNG
4. Save it locally

### Step 2: Share with Cursor AI
In Cursor chat:
1. **Upload the image** (drag & drop or paste)
2. **Ask Cursor to match the style**: 
   ```
   "Match this UI style" or "Implement this design"
   ```
3. Cursor will analyze:
   - Colors and gradients
   - Spacing and layout
   - Typography (font sizes, weights)
   - Border styles and shadows
   - Component structure

### Step 3: Iterate and Refine
- Cursor will create the components
- Review the code
- Ask for adjustments: "Make the borders thicker" or "Change to solid colors"
- Cursor updates the code in real-time

### ✅ Pros:
- Fast and easy
- Works with any design
- No export steps needed
- Great for overall style matching

### ❌ Cons:
- May need manual adjustments for exact pixel precision
- Colors might need fine-tuning

---

## Method 2: Figma Dev Mode (More Precise)

### Step 1: Enable Dev Mode in Figma
1. Open your Figma file
2. Click "Dev Mode" in top-right (or press `Shift + D`)
3. Select a component/frame

### Step 2: Copy Design Specs
Dev Mode shows you:
- **Exact colors**: `#FFCC00`, `rgba(255, 204, 0, 1)`
- **Spacing**: padding, margins, gaps
- **Typography**: font family, size, weight, line height
- **Dimensions**: width, height
- **Border radius**: corner rounding
- **Shadows**: offset, blur, spread

### Step 3: Give Cursor the Specs
In Cursor chat:
```
Create a SwiftUI button with:
- Background: #FFCC00 (yellow)
- Border: 4pt black solid
- Corner radius: 16pt
- Shadow: offset (6, 6), no blur
- Text: 16pt bold, black
- Padding: 20pt horizontal, 12pt vertical
```

### ✅ Pros:
- Pixel-perfect implementation
- Exact color values
- Precise measurements

### ❌ Cons:
- More manual work
- Need to extract each property

---

## Method 3: Figma MCP Integration (Advanced)

### What is Figma MCP?
Figma's Model Context Protocol server lets Cursor **directly access** Figma files.

### Setup Steps:

#### A. Remote MCP Server (Easiest)
1. In Cursor, open settings
2. Find "MCP" or "Model Context Protocol" settings
3. Add Figma server:
   ```json
   {
     "servers": {
       "figma": {
         "url": "https://mcp.figma.com/mcp",
         "type": "http"
       }
     }
   }
   ```
4. Authenticate with Figma OAuth when prompted

#### B. Desktop MCP Server
1. Open Figma Desktop App
2. Open your design file
3. Press `Shift + D` (Dev Mode)
4. Enable "Desktop MCP Server"
5. In Cursor, configure:
   ```json
   {
     "servers": {
       "figma": {
         "url": "http://127.0.0.1:3845/mcp",
         "type": "http"
       }
     }
   }
   ```

### Using Figma MCP:
Once connected, you can:
1. Copy Figma frame link: `https://figma.com/file/...`
2. In Cursor chat:
   ```
   "Implement the design at this Figma link: [paste link]"
   ```
3. Cursor fetches design data directly from Figma
4. Generates code automatically

### ✅ Pros:
- Most automated
- Direct access to design files
- Gets exact properties
- Can update when design changes

### ❌ Cons:
- Requires Figma paid plan (Professional/Organization/Enterprise)
- Setup required
- More complex

---

## Method 4: Export Code from Figma Plugins

### Popular Plugins:
- **Anima** - Exports to React/SwiftUI
- **Locofy** - Converts designs to code
- **SwiftUI Inspector** - Figma to SwiftUI

### Process:
1. Install plugin in Figma
2. Select frames to export
3. Plugin generates code
4. Copy code to Cursor
5. Ask Cursor to refine/adapt it

### ✅ Pros:
- Quick code generation
- Good starting point

### ❌ Cons:
- Generated code often needs cleanup
- May not match your architecture
- Not all plugins work well

---

## Best Practices for Figma → Cursor Workflow

### 1. Design with Code in Mind
- Use consistent spacing (8pt grid)
- Create reusable components in Figma
- Name layers clearly
- Use Auto Layout (Figma's flexbox)

### 2. Extract Design Tokens First
Before coding, extract:
- **Colors**: Create a color palette
- **Typography**: Font sizes, weights
- **Spacing**: Standard margins/paddings
- **Borders**: Standard border widths
- **Shadows**: Shadow styles

Example in Figma Dev Mode → Copy as iOS:
```swift
struct DesignTokens {
    static let yellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let borderWidth: CGFloat = 4
    static let cornerRadius: CGFloat = 16
}
```

### 3. Build Component by Component
Don't try to implement entire screens at once:
1. Start with smallest components (buttons, badges)
2. Combine into larger components (cards, forms)
3. Build full screens
4. Test and iterate

### 4. Use Cursor's AI Effectively

**Good prompts:**
```
"Create a SwiftUI button matching this Figma design [image]"
"Update the colors to match this style [image]"
"Make the borders thicker like in this screenshot"
```

**Bad prompts:**
```
"Make it look good"
"Fix the UI"
"Make it like Figma"
```

### 5. Iterate with Screenshots
1. Take screenshot of Figma design
2. Run your app, take screenshot
3. Show both to Cursor: "Make mine match the Figma design"
4. Cursor adjusts differences

---

## Recommended Workflow (What Worked for This Project)

### Phase 1: Style System Setup
1. Take screenshot of Figma design
2. Ask Cursor: "Extract the color palette and create a RetroColors struct"
3. Define border styles, shadows, typography

### Phase 2: Component Creation
1. Screenshot each component (button, card, etc.)
2. Ask Cursor: "Create this component in SwiftUI"
3. Cursor generates with design tokens

### Phase 3: Assembly
1. Screenshot full screen
2. Ask Cursor: "Build this view using the components"
3. Cursor assembles layout

### Phase 4: Polish
1. Run app side-by-side with Figma
2. Compare visually
3. Ask for specific adjustments: "Make borders thicker", "Change that color to brighter green"

---

## Tools & Resources

### Figma
- **Dev Mode**: Get exact CSS/iOS specs
- **Inspect Panel**: See all properties
- **Export**: Download assets (PNG, SVG)

### Cursor Features
- **Image Upload**: Drag & drop screenshots
- **Multi-file Editing**: Updates many files at once
- **AI Code Generation**: Understands design context
- **Real-time Preview**: See changes immediately

### Additional Tools
- **SF Symbols**: Apple's icon library (matches iOS style)
- **Color Picker**: macOS Digital Color Meter
- **Zeplin/Figma Inspect**: Alternative inspection tools

---

## Example: What We Did Today

### Input (Figma Screenshot):
- Bold black borders (4-5pt)
- Vibrant solid colors (yellow, pink, green, blue)
- Large typography (14-28pt, black weight)
- Hard shadows (no blur, 4-6pt offset)
- Rounded corners (12-24pt)

### Cursor's Output:
```swift
struct RetroColors {
    static let yellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let pink = Color(red: 1.0, green: 0.4, blue: 0.8)
    static let green = Color(red: 0.0, green: 0.9, blue: 0.4)
    // ... more colors
}

// Usage:
Button {
    action()
} label: {
    Text("FEED")
        .font(.system(size: 14, weight: .black))
}
.frame(height: 90)
.background(RetroColors.green)
.foregroundColor(.black)
.retroBorder(width: 4, cornerRadius: 12)
.retroShadow(offset: 4)
```

---

## Tips for Success

### ✅ Do:
- Take clear, well-lit screenshots
- Focus on one component at a time
- Be specific about what to change
- Iterate gradually
- Test on real device

### ❌ Don't:
- Rush - take time to review each component
- Ignore spacing/alignment
- Forget about different screen sizes
- Skip accessibility considerations
- Overcomplicate the design system

---

## Troubleshooting

### "The design doesn't match exactly"
→ Take a screenshot of both side-by-side, show Cursor the differences

### "Colors look different"
→ Use Figma Dev Mode to get exact hex/RGB values

### "Spacing is off"
→ Specify exact padding/margins in your prompt

### "Layout breaks on different screens"
→ Ask Cursor to make it responsive: "Make this work on all iPhone sizes"

---

## Next Steps

1. **Practice**: Try implementing a simple button from Figma
2. **Build a component library**: Create reusable components
3. **Establish patterns**: Consistent spacing, colors, typography
4. **Document**: Keep track of your design tokens
5. **Iterate**: Designs evolve, so does your code

---

## Summary

**Best Method for Most People:**
Screenshot + AI Description (Method 1)
- Fast, easy, no setup
- Works great for iOS/SwiftUI
- What we used for this project!

**Best Method for Teams:**
Figma MCP Integration (Method 3)
- Automated, precise
- Great for ongoing design updates
- Requires setup and paid Figma plan

**Best Method for Learning:**
Dev Mode Specs (Method 2)
- Understand design details
- Learn the relationships
- Build design intuition

---

## Questions?

Common questions:

**Q: Can Cursor read Figma files directly?**
A: Only with MCP setup. Otherwise, use screenshots.

**Q: How accurate is screenshot-based conversion?**
A: Very good for overall style, may need tweaking for exact pixels.

**Q: Do I need Figma Pro?**
A: No for screenshots, yes for MCP integration.

**Q: Can I use this for other platforms?**
A: Yes! Works for React, Flutter, web, etc. Just specify the framework.

**Q: How long does it take?**
A: Simple components: 1-2 minutes. Full screen: 10-30 minutes.

---

**Happy designing! 🎨✨**



