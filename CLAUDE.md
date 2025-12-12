# CLAUDE.md

**Note**: This project uses [bd (beads)](https://github.com/steveyegge/beads) for issue tracking. Use `bd` commands instead of markdown TODOs. See AGENTS.md for workflow details.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ToCoE (Table of Contents of Everything) is a Rails 7.1 application for producing CC0 (public domain) tables of contents of written works through volunteer labor and linked open data. The platform integrates with Open Library and uses FRBR (Functional Requirements for Bibliographic Records) concepts to model bibliographic entities.

## Development Environment

**Ruby version:** Check `.ruby-version` file (mise tool manager configured)

**Database:** SQLite3 for development, MySQL2 for production

**Key dependencies:**
- `openlibrary` gem for Open Library API integration
- `haml-rails` for view templates
- `httparty` for REST API consumption
- `puma` as the web server

## Common Commands

### Setup and Development
```bash
bundle install                    # Install dependencies
bin/rails db:migrate             # Run database migrations
bin/rails server                 # Start development server (default: localhost:3000)
bin/rails console                # Start Rails console
```

### Testing
```bash
# RSpec tests (preferred for new code)
bundle exec rspec                              # Run all RSpec tests
bundle exec rspec spec/models/work_spec.rb     # Run a single spec file
bundle exec rspec spec/models/work_spec.rb:42  # Run a single example at line 42

# Legacy Minitest tests
bin/rails test                                 # Run all Minitest tests
bin/rails test test/models/work_test.rb       # Run a single test file

# Cucumber BDD tests
cucumber                                       # Run Cucumber BDD tests
cucumber features/file.feature                 # Run a single feature file
```

### Database
```bash
bin/rails db:schema:load         # Load schema (faster than migrations for new databases)
bin/rails db:reset               # Drop, create, load schema
```

## Environment Configuration

The application uses environment variables for configuration (via the `dotenv-rails` gem).

**Setup:**
1. Copy `.env.example` to `.env`: `cp .env.example .env`
2. Update `.env` with your local values (never commit `.env` to git)

**Key environment variables:**
- `OCR_METHOD` - OCR method: 'tesseract' (local binary) or 'rest' (web service)
- `TESSERACT_PATH` - Path to tesseract binary (default: 'tesseract')
- `OCR_SERVICE_URL` - REST API endpoint for OCR service (when using OCR_METHOD=rest)
- `OCR_LANGUAGE` - OCR language code (default: 'eng')
- `GOOGLE_OAUTH2_CLIENT_ID` - Google OAuth2 client ID for sign-in
- `GOOGLE_OAUTH2_CLIENT_SECRET` - Google OAuth2 client secret
- `GUTENDEX_API_URL` - Gutendex API endpoint (default: 'https://gutendex.toolforge.org')
- `DEVISE_PEPPER` - Devise secret for password encryption (generate with `rails secret`)

**Production deployment:**
Set these environment variables in your hosting platform (Heroku, Docker, etc.).

## Core Architecture

### FRBR Data Model

The application implements a simplified FRBR model for bibliographic entities with four main entity types:

**Work** - Abstract intellectual content (the "idea" of a book/article)
- Has many creators (Person) through `people_works`
- Has many Expressions through `reifications`
- Supports aggregation (anthologies) and sequencing (ordered components) via `work_relationships`

**Expression** - Specific realization of a Work (e.g., translation, edition)
- Belongs to one Work via `reification`
- Has many realizers (Person) through `realizations` (e.g., translators, editors)
- Has many Manifestations through `embodiments`
- Supports aggregation and sequencing via `expression_relationships`

**Manifestation** - Physical/digital publication embodying one or more Expressions
- Has many Expressions through `embodiments`
- The `embodiments` table has a `sequence_number` field that preserves the table of contents order

**Person** - Creator or realizer of Works/Expressions
- Linked to external authority files: `openlibrary_id`, `viaf_id`, `wikidata_q`

### Key Relationships

- **Aggregation**: Used for collections (anthologies, essay collections, journals) where multiple independent works are grouped. Implemented via `work_relationships` and `expression_relationships` with `reltype: :aggregation`

- **Sequence**: Represents ordered succession of components within an aggregate. Implemented via `work_relationships` and `expression_relationships` with `reltype: :sequence`

- **Embodiment**: Links Expressions to Manifestations with `sequence_number` to reconstruct tables of contents

### ToC Markdown Format

The application parses a custom markdown format for table of contents (see `DESIGN` file):

- `# Title` - Top-level work in a collection
- `## Title` - Component of the preceding work (nested)
- `# Section Name /` - Section heading (trailing slash), no entity created
- `# Title || Author Name` - Work with explicit author
- `# Title || Author1; Author2` - Work with multiple authors (semicolon-separated)

When a ToC is created:
1. An aggregating Work and Expression are created for the collection
2. Each entry creates a Work, Expression, and Embodiment
3. The Embodiment's `sequence_number` preserves the order
4. Work/Expression relationships are created for aggregation and sequencing

### Controllers

**TocsController** (`app/controllers/tocs_controller.rb`)
- Primary controller for creating and managing tables of contents
- `process_toc(markdown)` - Core method that parses ToC markdown and creates FRBR entities
- `do_ocr` - AJAX endpoint for OCR processing of book images
- Integrates with Open Library API to fetch book/author metadata
- Uses OpenOCR class for external OCR service integration

**PublicationsController** (`app/controllers/publications_controller.rb`)
- Search interface to Open Library API
- Uses singleton `@@olclient` for Open Library client

### External Integrations

**Open Library API**
- Search and metadata retrieval for books
- Author information linked via `openlibrary_id` in Person model
- Custom client code in `lib/open_library/`

**OpenOCR Service**
- Configured via `OCR_SERVICE_URL` environment variable
- Used to extract text from book page images
- Accessible through `TocsController#do_ocr`
- OCR method selection via `OCR_METHOD` environment variable (tesseract/rest)

## Testing

### Testing Frameworks

- **RSpec** - Preferred framework for all new code (specs in `spec/` directory)
- **Minitest** - Legacy test framework (tests in `test/` directory)
- **Cucumber** - BDD tests (features in `features/` directory)
- **database_cleaner** - Used to clean test database between tests

### Testing Requirements - MANDATORY

**All new features and bug fixes MUST include RSpec tests.** This is part of the Definition of Done.

#### When to Write Tests

1. **New Features**: Write RSpec tests for all new functionality
   - Model specs for new models or model methods
   - Controller specs for new controller actions or changes
   - Request specs for API endpoints
   - Service/Library specs for new classes in `lib/`

2. **Bug Fixes**: Write RSpec tests that:
   - Reproduce the bug (test should fail initially)
   - Verify the fix (test should pass after fix)

3. **Refactoring**: Ensure existing tests pass, add tests for edge cases

#### Test Coverage Requirements

- **Models**: Test validations, associations, instance methods, class methods, scopes
- **Controllers**: Test successful responses, error handling, parameter handling
- **Services/Libraries**: Test public methods, edge cases, error conditions
- **Integration**: Test critical user workflows

#### Definition of Done

Before marking any feature or fix as complete, you MUST:

1. ✅ Write RSpec tests for all new/changed code
2. ✅ Run the full RSpec suite: `bundle exec rspec`
3. ✅ Ensure all tests pass (0 failures)
4. ✅ Review test coverage for the changed code
5. ✅ Commit tests along with implementation code

**A feature or fix is NOT complete until all tests pass.**

#### Example Test Structure

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
      # Arrange
      work = create(:work)

      # Act
      result = work.method_name

      # Assert
      expect(result).to eq(expected_value)
    end
  end
end
```

#### Authentication in Feature Specs

Feature specs (Capybara tests) require authentication mocking since the application uses Devise. Use the `sign_in_as` helper:

```ruby
# spec/features/my_feature_spec.rb
RSpec.feature 'My feature', type: :feature do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    sign_in_as(user)
  end

  scenario 'user can access protected page' do
    visit '/tocs'
    expect(page).to have_current_path('/tocs')
  end
end
```

The `sign_in_as` helper:
- Bypasses the authentication UI using Warden test helpers
- Is automatically available in all feature specs via `spec/support/devise_feature_helpers.rb`
- Automatically cleans up after each test

**IMPORTANT**: All feature specs that access protected routes MUST use `sign_in_as` to authenticate a user.

#### Running Tests

Always run the full suite before committing:
```bash
bundle exec rspec
```

For TDD workflow, run specific specs during development:
```bash
bundle exec rspec spec/models/work_spec.rb
bundle exec rspec spec/controllers/tocs_controller_spec.rb
bundle exec rspec spec/features/my_feature_spec.rb
```

## Internationalization (I18n)

This application uses Rails I18n for all user-facing strings to support future translation to multiple languages.

### Guidelines

**MANDATORY**: All new user-facing strings MUST be added to locale files. Never hardcode English strings in controllers or views.

#### Controllers

Use `I18n.t()` for all flash messages and user-facing text:

```ruby
# Good
flash[:notice] = I18n.t('tocs.flash.pages_marked_successfully')
flash[:error] = I18n.t('tocs.flash.invalid_openlibrary_uri')

# Bad - NEVER do this
flash[:notice] = 'TOC pages marked successfully'
flash[:error] = 'Invalid OpenLibrary book URI'
```

#### Views

Use the `t()` helper for all user-facing strings:

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

#### Locale File Organization

Strings are organized in `config/locales/en.yml` by namespace:

- `common.actions` - Shared action strings (Edit, Save, Back, etc.)
- `common.labels` - Shared label strings (Title, Status, etc.)
- `tocs.flash` - Flash messages from TocsController
- `tocs.index`, `tocs.show`, `tocs.edit`, etc. - View-specific strings
- `tocs.form` - Form-specific strings
- `home.index` - Homepage strings
- `publications.search` - Publications search strings

#### Pluralization

Use Rails pluralization for count-based messages:

```yaml
# Locale file
created_multiple_success:
  one: "Successfully created %{count} TOC"
  other: "Successfully created %{count} TOCs"

# Controller
flash[:notice] = I18n.t('tocs.flash.created_multiple_success', count: created_count)
```

#### Interpolation

Use interpolation for dynamic values:

```yaml
# Locale file
welcome_back: "Welcome back, %{email}!"
page_number: "TOC Page %{number}"

# View
t('home.index.welcome_back', email: current_user.email)
t('tocs.show.page_number', number: index + 1)
```

#### JavaScript

JavaScript strings in views currently use hardcoded English text. For full I18n support, consider using a JavaScript I18n library like `i18n-js`. For now, JavaScript strings are acceptable as-is but should be documented for future translation work.

#### Testing I18n Changes

When adding new I18n strings:

1. Add strings to `config/locales/en.yml`
2. Update controllers/views to use `I18n.t()` / `t()`
3. Run full RSpec suite: `bundle exec rspec`
4. Verify all tests pass

## Git Workflow with Beads

This project uses the Beads issue tracker which integrates with git. **CRITICAL**: Follow this exact workflow to ensure proper commit messages.

### Correct Workflow for Committing Code

When you complete work on a task:

1. **Stage your code changes**:
   ```bash
   git add <files>
   ```

2. **Commit your code changes with a descriptive message**:
   ```bash
   git commit -m "$(cat <<'EOF'
   Your descriptive commit message here

   - Bullet point 1
   - Bullet point 2

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   EOF
   )"
   ```

3. **Close the beads issue** (if applicable):
   ```bash
   bd close <issue-id>
   ```

4. **Sync beads changes** (this will commit beads.jsonl):
   ```bash
   bd sync
   ```

5. **Push all commits to remote**:
   ```bash
   git push
   ```

### IMPORTANT: What NOT to Do

❌ **NEVER stage code changes and then run `bd sync` without committing first**

This is wrong:
```bash
git add <files>
bd sync  # This will commit your code with "bd sync: [timestamp]"
```

The `bd sync` command commits any staged changes to git, so if you stage your code and then run `bd sync`, your code will be committed with a generic "bd sync: [timestamp]" message instead of your descriptive commit message.

### Why This Matters

- Descriptive commit messages help understand the project history
- They explain what changed and why
- Generic "bd sync" messages provide no context
- Code review and debugging are harder with poor commit messages

## Important Notes

- The aggregating Expression for a collection has a `nil` sequence_number in its Embodiment to exclude it from reconstructed tables of contents
- Person records are deduplicated by `openlibrary_id` before creation
- The ToC controller automatically creates all necessary FRBR entities from markdown input
- Work and Expression models have mirrored relationship methods for aggregation/sequencing
