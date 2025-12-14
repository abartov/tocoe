# People Matcher UI Design

## Overview
A reusable UI component for associating objects (Tocs, Works, Expressions) with Person entities by searching across multiple authority databases.

## Requirements Summary
- **Input**: Name string (required), optional candidate identifications [source, ID, label]
- **Search Sources**: Local DB, VIAF, Wikidata, Library of Congress
- **Output**: Association between object and Person (creating Person if needed)
- **Features**:
  - 4 parallel search result lists
  - Context-aware candidate highlighting
  - "In DB" badges for existing Person records
  - Expandable details (AJAX-loaded)
  - Quick match action

## Design Options

### Option 1: Modal Dialog with Side-by-Side Lists (RECOMMENDED)

**Layout**: Full-screen modal with 4 equal-width columns

**Pros**:
- Maximizes screen space for comparing results
- Modal provides clear focus and context
- Side-by-side comparison is intuitive
- Familiar pattern (already used in app for lightboxes)
- Easy to see all sources at once

**Cons**:
- Requires wider screens (may need horizontal scroll on mobile)
- More screen real estate

**Mockup Structure**:
```
┌──────────────────────────────────────────────────────────────┐
│ Match Person: "Douglas Adams"                            [×] │
├──────────────────────────────────────────────────────────────┤
│ Searching for: Douglas Adams                                 │
│ [Refine Search] [Clear All]                                  │
├──────────────────────────────────────────────────────────────┤
│┌──────────┬──────────┬──────────┬──────────┐                │
││ Our DB   │ VIAF     │ Wikidata │ Lib.Cong │                │
││ (3)      │ (12)     │ (8)      │ (5)      │                │
│├──────────┼──────────┼──────────┼──────────┤                │
││          │          │          │          │                │
││ [Result] │ [Result] │ [Result] │ [Result] │                │
││ ▾ More   │ ▾ More   │ ▾ More   │ ▾ More   │                │
││ [Match!] │ [Match!] │ [Match!] │ [Match!] │                │
││          │          │          │          │                │
││ [Result] │ [Result] │ [Result] │ [Result] │                │
││          │          │          │          │                │
││ ...      │ ...      │ ...      │ ...      │                │
││          │          │          │          │                │
│└──────────┴──────────┴──────────┴──────────┘                │
│                                                               │
│                                    [Create New Person] [Cancel│
└──────────────────────────────────────────────────────────────┘
```

**Each Result Card**:
```
┌────────────────────────────────┐
│ Douglas Adams                  │ ← Name/Label
│ 🌟 Likely in context          │ ← Badge (if candidate)
│ 📚 In DB                      │ ← Badge (if exists in our DB)
│                                │
│ 1952-2001 • United Kingdom     │ ← Basic info
│                                │
│ ▾ Show more details            │ ← Collapsible trigger
│                                │
│ [Match!]                       │ ← Action button
└────────────────────────────────┘
```

**Expanded Details (AJAX-loaded)**:
```
┌────────────────────────────────┐
│ Douglas Adams                  │
│ 🌟 Likely in context          │
│ 📚 In DB                      │
│                                │
│ 1952-2001 • United Kingdom     │
│                                │
│ ▴ Hide details                 │
│ ┌──────────────────────────┐  │
│ │ Full name: Douglas Noël  │  │
│ │ Adams                     │  │
│ │                           │  │
│ │ Occupations: Novelist,    │  │
│ │ Screenwriter, Essayist    │  │
│ │                           │  │
│ │ Notable works: The        │  │
│ │ Hitchhiker's Guide to     │  │
│ │ the Galaxy                │  │
│ │                           │  │
│ │ Authority IDs:            │  │
│ │ • VIAF: 113230702         │  │
│ │ • LoC: n80076765          │  │
│ └──────────────────────────┘  │
│                                │
│ [Match!]                       │
└────────────────────────────────┘
```

---

### Option 2: Tabbed Interface

**Layout**: Modal with tabs switching between sources

**Pros**:
- Works better on smaller screens
- Cleaner, less overwhelming
- Focused attention on one source at a time

**Cons**:
- Harder to compare across sources
- More clicks required
- Can't see all results simultaneously
- Less efficient workflow

**Mockup Structure**:
```
┌──────────────────────────────────────────────────────┐
│ Match Person: "Douglas Adams"                    [×] │
├──────────────────────────────────────────────────────┤
│ Searching for: Douglas Adams                         │
│ [Refine Search] [Clear All]                          │
├──────────────────────────────────────────────────────┤
│ [Our DB (3)] [VIAF (12)] [Wikidata (8)] [LoC (5)]   │ ← Tabs
├──────────────────────────────────────────────────────┤
│                                                       │
│ ┌────────────────────────────────────────────────┐  │
│ │ Douglas Adams                                  │  │
│ │ 1952-2001 • United Kingdom                     │  │
│ │ ▾ More    [Match!]                             │  │
│ └────────────────────────────────────────────────┘  │
│                                                       │
│ ┌────────────────────────────────────────────────┐  │
│ │ Douglas Adams (musician)                       │  │
│ │ 1967-present • United States                   │  │
│ │ ▾ More    [Match!]                             │  │
│ └────────────────────────────────────────────────┘  │
│                                                       │
│ ...                                                   │
│                                                       │
│                        [Create New Person] [Cancel]  │
└──────────────────────────────────────────────────────┘
```

---

### Option 3: Accordion/Collapsible Sections

**Layout**: In-page component with expandable source sections

**Pros**:
- No modal overlay (less intrusive)
- Can integrate into existing forms
- Sequential workflow
- Mobile-friendly

**Cons**:
- Takes up page space
- Only one source visible at a time
- Harder to compare results
- Less focused (no modal isolation)

**Mockup Structure**:
```
┌──────────────────────────────────────────────────────┐
│ Match Person for this Work                           │
├──────────────────────────────────────────────────────┤
│ Name: [Douglas Adams              ]  [Search]        │
├──────────────────────────────────────────────────────┤
│                                                       │
│ ▾ Our Database (3 results)                           │
│ ├─────────────────────────────────────────────────┤ │
│ │ [Result cards...]                                │ │
│ └─────────────────────────────────────────────────┘ │
│                                                       │
│ ▸ VIAF (12 results)                                  │
│                                                       │
│ ▸ Wikidata (8 results)                               │
│                                                       │
│ ▸ Library of Congress (5 results)                    │
│                                                       │
│ [Create New Person] [Cancel]                         │
└──────────────────────────────────────────────────────┘
```

---

## Recommendation: Option 1 (Modal with Side-by-Side Lists)

**Why Option 1 is best**:

1. **Efficient Comparison**: Users can quickly scan all 4 sources simultaneously, which is critical for identifying the correct person when multiple similar results exist.

2. **Focused Workflow**: Modal provides clear context separation from the main page, signaling "you're in person-matching mode now."

3. **Matches Existing Patterns**: The app already uses modals (e.g., lightbox for scans), so this feels familiar to users.

4. **Optimal for the Task**: Person matching is inherently comparative - users need to evaluate "is this the same person as that one?" across sources. Side-by-side layout enables this mental model.

5. **Handles Candidate Highlighting Well**: Context-based candidates can be visually prominent at the top of their respective columns, making it easy to check "recommended" matches first.

6. **Scalable**: Can easily add/remove sources by adjusting column count.

**Responsive Strategy**:
- Desktop (>1024px): 4 columns side-by-side
- Tablet (768-1023px): 2x2 grid
- Mobile (<768px): Vertical stack with sticky source headers

---

## Detailed Component Specification

### Visual Design (using Design System)

**Colors**:
- Primary action (Match button): `$primary-600` (#9333ea)
- Candidate badge: `$warning-500` (#f59e0b) with gold star
- In-DB badge: `$info-500` (#3b82f6) with book icon
- Result cards: `$bg-primary` with `$border-light` borders
- Hover: `$gray-100` background

**Typography**:
- Source headers: `$text-lg`, `$font-semibold`
- Person name: `$text-base`, `$font-medium`
- Details: `$text-sm`, `$text-secondary`
- Badges: `$text-xs`, `$font-medium`

**Spacing**: 4px system (`$space-*`)
- Card padding: `$space-4` (16px)
- Gap between cards: `$space-3` (12px)
- Column gap: `$space-4` (16px)
- Modal padding: `$space-6` (24px)

**Interactions**:
- Cards: Hover state with subtle `$shadow-sm`
- Expand/collapse: `$transition-base` (200ms)
- Match button: Full-width in card, `$transition-fast`

### Data Structure

**Input Props**:
```javascript
{
  targetType: 'Toc' | 'Work' | 'Expression',
  targetId: number,
  nameQuery: string,
  candidates: [
    { source: 'viaf', id: '113230702', label: 'Adams, Douglas, 1952-2001' },
    { source: 'wikidata', id: 42, label: 'Douglas Adams' }
  ]
}
```

**Result Object**:
```javascript
{
  source: 'viaf' | 'wikidata' | 'loc' | 'database',
  id: string | number,
  label: string,
  dates: string,           // e.g., "1952-2001"
  country: string,         // e.g., "United Kingdom"
  isCandidate: boolean,
  inDatabase: boolean,
  personId: number | null, // If inDatabase
  details: null | {        // Loaded on expand
    fullName: string,
    occupations: string[],
    notableWorks: string[],
    authorityIds: {
      viaf: string,
      wikidata: string,
      loc: string
    }
  }
}
```

### API Endpoints Needed

**Search Endpoint**:
```
POST /people/search_all
Parameters: {
  query: string,
  candidates: [{source, id, label}]
}
Response: {
  database: [results],
  viaf: [results],
  wikidata: [results],
  loc: [results]
}
```

**Details Endpoint** (AJAX):
```
GET /people/fetch_details?source=viaf&id=113230702
Response: { details object }
```

**Match Endpoint**:
```
POST /people/match
Parameters: {
  target_type: string,
  target_id: number,
  source: string,
  external_id: string,
  person_id: number | null  // null if creating new
}
Response: {
  success: boolean,
  person: { id, name, ... }
}
```

### Component Files Architecture

```
app/
├── controllers/
│   └── people_controller.rb           # Add search_all, fetch_details, match
├── services/
│   └── person_matcher_service.rb      # Business logic for matching
├── views/
│   └── shared/
│       └── _person_matcher.html.haml  # Reusable component
├── assets/
│   ├── stylesheets/
│   │   └── person_matcher.scss        # Component styles
│   └── javascripts/
│       └── person_matcher.js          # Component behavior
```

### Usage Example

In any view where person matching is needed:
```haml
= render 'shared/person_matcher',
  target_type: 'Toc',
  target_id: @toc.id,
  name_query: 'Douglas Adams',
  candidates: [
    { source: 'viaf', id: '113230702', label: 'Adams, Douglas' }
  ]
```

Or trigger via JavaScript:
```javascript
PersonMatcher.open({
  targetType: 'Work',
  targetId: 123,
  nameQuery: 'Douglas Adams',
  candidates: []
});
```

---

## Implementation Breakdown (Beads)

After user approval, I recommend breaking implementation into these beads:

1. **Backend API Endpoints** (tocoe-XXX1)
   - Create PeopleController endpoints: search_all, fetch_details, match
   - Create PersonMatcherService for business logic
   - Write RSpec tests for service and controller

2. **Person Enrichment Logic** (tocoe-XXX2)
   - Implement cross-authority lookups (e.g., Wikidata → LoC)
   - Add methods to Person model for enrichment
   - Write RSpec tests for Person model methods

3. **Frontend Component Structure** (tocoe-XXX3)
   - Create HAML partial for modal
   - Create SCSS for component styling
   - Add I18n strings

4. **JavaScript Behavior** (tocoe-XXX4)
   - Implement PersonMatcher JS class
   - AJAX calls for search/details/match
   - Expand/collapse functionality
   - Loading states

5. **Integration & Testing** (tocoe-XXX5)
   - Integrate component into Toc transcription workflow (tocoe-svmq)
   - Add feature specs
   - Manual testing across all sources
   - Responsive testing

---

## Next Steps

Please review these design options and let me know:

1. Do you agree with the recommendation for Option 1 (Modal with Side-by-Side Lists)?
2. Any changes or additions to the component specification?
3. Should I proceed with breaking down the implementation into beads as outlined above?
4. Are there any additional authority sources beyond VIAF, Wikidata, and LoC that should be included?

Once approved, I'll create the implementation beads and begin development!
