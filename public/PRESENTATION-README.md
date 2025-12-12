# ToCoE Presentation

## Overview

This directory contains a comprehensive HTML presentation introducing the ToCoE (Table of Contents of Everything) platform.

## Files

- **tocoe-presentation.html** - Main presentation file (self-contained, single HTML file)
- **presentation-screenshots/** - Directory containing actual screenshots from the live application

## Screenshots Included

All screenshots are real captures from the running ToCoE application:

1. **homepage.png** - ToCoE platform homepage
2. **publications-search.png** - Search interface for Open Library and Gutenberg
3. **tocs-index.png** - Table of Contents listing page
4. **browse-scans.png** - Browse scans interface with page thumbnails and checkboxes
5. **toc-show.png** - TOC detail/show page
6. **toc-edit.png** - TOC edit interface with tabs for transcription, OCR, and scans

## Images from Wikimedia Commons

The presentation includes the following public domain images with proper attribution:

- **T.S. Eliot photograph (1923)** by Lady Ottoline Morrell - Public Domain
- **"The Sacred Wood" first edition cover (1920)** - Public Domain

## How to View

### Option 1: Direct File Access
Open the file in any modern web browser:
```
file:///home/asaf/dev/tocoe/public/tocoe-presentation.html
```

### Option 2: Via Rails Server
Start the Rails server and navigate to:
```bash
bin/rails server
# Then visit: http://localhost:3000/tocoe-presentation.html
```

## Navigation

- **Next Slide:** Click "Next →" button, press Right Arrow, or press Spacebar
- **Previous Slide:** Click "← Previous" button or press Left Arrow
- **View Screenshot Full Size:** Click on any screenshot to open it in a new tab
- **Slide Counter:** Top right corner shows current slide number

## Presentation Structure (15 Slides)

1. **Title Slide** - Introduction and CC0 dedication
2. **The Mission** - Purpose, crowdsourcing, public domain philosophy
3. **Understanding FRBR** - Data model explanation with layperson definitions
4. **Workflow Step 1** - Finding books (Open Library & Gutenberg)
5. **Workflow Step 2** - Marking ToC pages
6. **Workflow Step 3** - Transcribing with markdown
7. **Workflow Step 4** - Processing & linked data (VIAF, Wikidata, LCSH)
8. **Workflow Step 5** - Verification & quality control
9. **UX Conveniences** - OCR, quick preview, zoom controls, etc.
10. **Real Data Examples** - Current database statistics and examples
11. **Future Plans Part 1** - Export capabilities (Markdown, MARCXML)
12. **Future Plans Part 2** - Escalation system and public API
13. **The Impact** - Benefits for researchers, libraries, public
14. **Get Involved** - How to contribute
15. **Thank You** - Closing slide

## Technical Details

- **Format:** Single HTML file with embedded CSS and JavaScript
- **Dependencies:** None (fully self-contained)
- **Browser Compatibility:** Modern browsers (Chrome, Firefox, Safari, Edge)
- **Responsive:** Works on desktop, tablet, and mobile devices

## Key Features

✅ **Precise Terminology** - All technical terms (FRBR, CC0, MARCXML, VIAF, Wikidata, LCSH) are defined for laypeople on first use

✅ **Real Data** - Uses actual statistics and examples from the ToCoE database

✅ **Visual Screenshots** - Real screenshots from the application (not mockups)

✅ **Public Domain Images** - Includes properly attributed images from Wikimedia Commons

✅ **Interactive** - Click screenshots to view full size, smooth transitions

✅ **Accessible** - Keyboard navigation, clear typography, high contrast

## Customization

The presentation uses a gradient background and clean design. All colors and styles are defined in the `<style>` section and can be easily customized.

### Main Color Scheme
- Primary gradient: `#667eea` to `#764ba2`
- Workflow boxes: Light purple gradient `#a5b4fc` to `#c4b5fd` (improved readability)
- Text: Dark gray `#2d3748`, `#4a5568`
- Highlights: Yellow gradient

## License

The presentation content and ToCoE data are dedicated to the **CC0 Public Domain**.

All screenshots are from the ToCoE application and are released as CC0.

Wikimedia Commons images are properly credited and are in the Public Domain.
