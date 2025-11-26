# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Babushkafone is a Rails 8.1 application using SQLite, Hotwire (Turbo + Stimulus), and TailwindCSS 4.

## Common Commands

```bash
# Development server (runs Rails + TailwindCSS watcher)
bin/dev

# Run all tests
bin/rails test

# Run a single test file
bin/rails test test/controllers/landing_controller_test.rb

# Run a specific test by line number
bin/rails test test/controllers/landing_controller_test.rb:7

# Linting
bin/rubocop

# Security audit
bin/brakeman
bin/bundler-audit

# Database
bin/rails db:migrate
bin/rails db:setup
```

## Tech Stack

- **Ruby**: 3.2.3
- **Rails**: 8.1.1
- **Database**: SQLite (stored in storage/)
- **Assets**: Propshaft + Importmap
- **CSS**: TailwindCSS 4 (via tailwindcss-rails)
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **Deployment**: Kamal (Docker-based)

## Code Style

Uses `rubocop-rails-omakase` for Ruby style guidelines.
