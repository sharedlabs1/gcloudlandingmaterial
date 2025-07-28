# AsciiDoc Setup Guides

This directory contains the AsciiDoc versions of the setup guides for the GCP Landing Zone Workshop.

## Available Guides

- `00-lab-environment-setup.adoc` - Basic lab environment setup (converted from original)
- `complete-workshop-setup.adoc` - Comprehensive workshop setup guide (recommended)

## Features

All AsciiDoc guides include:
* Table of Contents (TOC) enabled
* Numbered sections  
* Syntax highlighting for code blocks
* Font icons for better readability

## Usage

### Viewing AsciiDoc Files

You can view these files with any AsciiDoc viewer or convert them to other formats:

**Convert to HTML:**
```bash
asciidoctor filename.adoc
```

**Convert to PDF:**
```bash
asciidoctor-pdf filename.adoc
```

**Convert to Word (via Pandoc):**
```bash
pandoc -f asciidoc -t docx filename.adoc -o filename.docx
```

### Recommended Setup Guide

**Use `complete-workshop-setup.adoc`** for the full workshop experience.

## Important Notes

### 🚨 Credential Configuration Required
The setup guides contain placeholder values that **MUST** be replaced with your actual GCP credentials:

```bash
# REPLACE THESE VALUES WITH YOUR ACTUAL INFORMATION
export PROJECT_ID="YOUR_PROJECT_ID_HERE"
export BILLING_ACCOUNT="YOUR_BILLING_ACCOUNT_ID"
```

### 📋 Prerequisites
- Valid GCP account with billing enabled
- Ubuntu 20.04 LTS or later system
- Project with Owner role permissions
- Basic familiarity with Linux/bash commands

## Original Files

The original Markdown files are preserved in the `setup-guides/` directory.

---

**Ready to begin?** Start with `complete-workshop-setup.adoc` and build your GCP Landing Zone! 🚀
