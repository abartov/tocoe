require 'rails_helper'

RSpec.feature 'Help page', type: :feature do
  scenario 'visitor can access help page without authentication' do
    visit '/help'

    expect(page).to have_current_path('/help')
    expect(page).to have_css('.help-page')
    expect(page).to have_css('h1', text: I18n.t('help.index.title'))
  end

  scenario 'help page displays all sections' do
    visit '/help'

    # Check for all section headings
    expect(page).to have_css('#getting-started', text: I18n.t('help.sections.getting_started.title'))
    expect(page).to have_css('#creating-tocs', text: I18n.t('help.sections.creating_tocs.title'))
    expect(page).to have_css('#markdown-format', text: I18n.t('help.sections.markdown_format.title'))
    expect(page).to have_css('#ocr', text: I18n.t('help.sections.ocr.title'))
    expect(page).to have_css('#subjects', text: I18n.t('help.sections.subjects.title'))
    expect(page).to have_css('#verification', text: I18n.t('help.sections.verification.title'))
    expect(page).to have_css('#faq', text: I18n.t('help.sections.faq.title'))
  end

  scenario 'help page displays navigation pills' do
    visit '/help'

    expect(page).to have_css('.nav-pills')
    expect(page).to have_link(I18n.t('help.sections.getting_started.title'), href: '#getting-started')
    expect(page).to have_link(I18n.t('help.sections.creating_tocs.title'), href: '#creating-tocs')
    expect(page).to have_link(I18n.t('help.sections.markdown_format.title'), href: '#markdown-format')
    expect(page).to have_link(I18n.t('help.sections.ocr.title'), href: '#ocr')
    expect(page).to have_link(I18n.t('help.sections.subjects.title'), href: '#subjects')
    expect(page).to have_link(I18n.t('help.sections.verification.title'), href: '#verification')
    expect(page).to have_link(I18n.t('help.sections.faq.title'), href: '#faq')
  end

  scenario 'getting started section displays contribution steps' do
    visit '/help'

    within '#getting-started' do
      expect(page).to have_content(I18n.t('help.sections.getting_started.intro'))
      expect(page).to have_content(I18n.t('help.sections.getting_started.step1_title'))
      expect(page).to have_content(I18n.t('help.sections.getting_started.step2_title'))
      expect(page).to have_content(I18n.t('help.sections.getting_started.step3_title'))
      expect(page).to have_content(I18n.t('help.sections.getting_started.step4_title'))
    end
  end

  scenario 'markdown format section displays syntax examples' do
    visit '/help'

    within '#markdown-format' do
      expect(page).to have_content(I18n.t('help.sections.markdown_format.title'))
      expect(page).to have_css('pre code', text: /# Title/)
      expect(page).to have_css('.help-example')
    end
  end

  scenario 'OCR section displays magic trim examples' do
    visit '/help'

    within '#ocr' do
      expect(page).to have_content(I18n.t('help.sections.ocr.magic_trim_title'))
      expect(page).to have_content(I18n.t('help.sections.ocr.magic_trim_before'))
      expect(page).to have_content(I18n.t('help.sections.ocr.magic_trim_after'))
    end
  end

  scenario 'FAQ section displays all questions and answers' do
    visit '/help'

    within '#faq' do
      expect(page).to have_css('.help-faq-item', count: 7)
      expect(page).to have_content(I18n.t('help.sections.faq.q1_question'))
      expect(page).to have_content(I18n.t('help.sections.faq.q1_answer'))
      expect(page).to have_link(I18n.t('help.sections.faq.github_issues'), href: 'https://github.com/abartov/tocoe/issues')
    end
  end

  scenario 'verification section displays important callout' do
    visit '/help'

    within '#verification' do
      expect(page).to have_css('.help-callout-warning')
      expect(page).to have_content(I18n.t('help.sections.verification.important_cannot_verify_own'))
    end
  end

  scenario 'subjects section displays success callout' do
    visit '/help'

    within '#subjects' do
      expect(page).to have_css('.help-callout-success')
      expect(page).to have_content(I18n.t('help.sections.subjects.why_important_description'))
    end
  end

  scenario 'OCR section displays info callout' do
    visit '/help'

    within '#ocr' do
      expect(page).to have_css('.help-callout-info')
      expect(page).to have_content(I18n.t('help.sections.ocr.tip_always_review'))
    end
  end

  scenario 'authenticated user can access help page', js: true do
    user = User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123')
    sign_in_as(user)

    visit '/help'

    expect(page).to have_current_path('/help')
    expect(page).to have_css('h1', text: I18n.t('help.index.title'))
  end
end
