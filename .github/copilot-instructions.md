# GitHub Copilot Instructions for ToCoE

## Project Overview

**ToCoE** (Table of Contents of Everything) is a Rails 7.1 application for producing CC0 (public domain) tables of contents of written works through volunteer labor and linked open data.

**Key Features:**
- FRBR (Functional Requirements for Bibliographic Records) data model
- OpenLibrary API integration for book metadata
- Internet Archive integration for book scans and OCR
- TOC workflow: empty → pages_marked → transcribed → verified
- Google OAuth authentication (Devise + omniauth-google-oauth2)

## Tech Stack

- **Framework**: Rails 7.1
- **Ruby**: Check `.ruby-version` file (mise tool manager)
- **Database**: SQLite3 (development), MySQL2 (production)
- **Views**: HAML templates
- **Authentication**: Devise + Google OAuth2
- **Testing**: RSpec (preferred), Minitest (legacy), Cucumber (BDD)
- **External APIs**: OpenLibrary, Internet Archive, OCR services

## Coding Guidelines

### Internationalization (I18n) - MANDATORY

All user-facing strings MUST use Rails I18n. Never hardcode English strings.

**Controllers:**
```ruby
# Good
flash[:notice] = I18n.t('tocs.flash.pages_marked_successfully')
flash[:error] = I18n.t('tocs.flash.invalid_openlibrary_uri')

# Bad - NEVER do this
flash[:notice] = 'TOC pages marked successfully'
flash[:error] = 'Invalid OpenLibrary book URI'
```

**Views:**
```haml
-# Good
%h1= t('tocs.index.title')
= link_to t('common.actions.edit'), edit_toc_path(@toc)
= label_tag t('tocs.form.book_uri_label')

-# Bad - NEVER do this
%h1 Listing TOCs
= link_to 'Edit', edit_toc_path(@toc)
= label_tag 'Book URI'
```

**Locale File Organization** (`config/locales/en.yml`):
- `common.actions` - Shared action strings (Edit, Save, Back, etc.)
- `common.labels` - Shared label strings (Title, Status, etc.)
- `tocs.flash` - Flash messages from TocsController
- `tocs.index`, `tocs.show`, `tocs.edit` - View-specific strings
- `tocs.form` - Form-specific strings
- `home.index` - Homepage strings
- `publications.search` - Publications search strings

### Testing - MANDATORY

All new features and bug fixes MUST include RSpec tests.

**Test Structure:**
```ruby
# spec/models/work_spec.rb
RSpec.describe Work, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'associations' do
    it { should have_many(:expressions) }
  end

  describe '#method_name' do
    it 'does something specific' do
      # Arrange, Act, Assert
    end
  end
end
```

**Run tests:**
```bash
bundle exec rspec                              # All tests
bundle exec rspec spec/models/work_spec.rb     # Single file
bundle exec rspec spec/models/work_spec.rb:42  # Single example
```

### Git Workflow with Beads

This project uses **bd (beads)** for issue tracking.

**Correct commit workflow:**
1. Stage code: `git add <files>`
2. Commit with message: `git commit -m "Descriptive message..."`
3. Close beads issue: `bd close <id>`
4. Sync beads: `bd sync`
5. Push: `git push`

**CRITICAL**: Never run `bd sync` before committing your code, or it will commit with a generic "bd sync: [timestamp]" message.

## Issue Tracking with bd

**MANDATORY**: Use **bd** for ALL task tracking. Do NOT create markdown TODO lists.

### Essential Commands

```bash
# Find work
bd ready --json                    # Unblocked issues
bd list --status open --json       # All open issues

# Create and manage
bd create "Title" -t bug|feature|task -p 0-4 --json
bd update <id> --status in_progress --json
bd close <id> --reason "Done" --json

# Sync (at end of session!)
bd sync  # Sync with git remote
```

### Workflow

1. **Check ready work**: `bd ready --json`
2. **Claim task**: `bd update <id> --status in_progress`
3. **Work on it**: Implement, test, document
4. **Complete**: `bd close <id> --reason "Done"`
5. **Sync**: `bd sync`

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

## Project Structure

```
tocoe/
├── app/
│   ├── controllers/       # Rails controllers
│   ├── models/            # FRBR models (Work, Expression, Manifestation, Person)
│   ├── views/             # HAML templates
│   └── assets/            # JavaScript, CSS
├── config/
│   ├── locales/           # I18n translation files
│   └── routes.rb          # URL routing
├── db/
│   ├── migrate/           # Database migrations
│   └── schema.rb          # Current database schema
├── lib/
│   ├── open_library/      # OpenLibrary API client
│   └── subject_headings/  # Wikidata integration
├── spec/                  # RSpec tests (preferred)
├── test/                  # Minitest tests (legacy)
├── features/              # Cucumber BDD tests
└── .beads/
    └── issues.jsonl       # Beads issue tracking
```

## Important Rules

- ✅ Use `I18n.t()` / `t()` for ALL user-facing strings
- ✅ Write RSpec tests for all new code
- ✅ Use bd for ALL task tracking
- ✅ Commit code BEFORE running `bd sync`
- ✅ Run `bundle exec rspec` before committing
- ❌ Do NOT hardcode English strings
- ❌ Do NOT skip writing tests
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT commit without running tests

---

**For detailed guidelines, see [CLAUDE.md](../CLAUDE.md) and [AGENTS.md](../AGENTS.md)**
