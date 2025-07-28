# Setup Guides

This directory contains setup guides for the GCP Landing Zone Workshop in both Markdown and AsciiDoc formats.

## Available Guides

### Markdown Format (`setup-guides/`)
- `00-lab-environment-setup.md` - Basic lab environment setup (original)
- `complete-workshop-setup.md` - Comprehensive workshop setup guide

### AsciiDoc Format (`adoc-setup-guides/`)
- `00-lab-environment-setup.adoc` - Basic lab environment setup (converted)
- `complete-workshop-setup.adoc` - Comprehensive workshop setup guide (converted)

## Recommended Setup Guide

**Use `complete-workshop-setup.md` (or `.adoc`)** for the full workshop experience. This guide includes:

- ✅ Complete Ubuntu/Linux environment setup
- ✅ All required tools installation
- ✅ GCP authentication and project configuration
- ✅ Terraform state management setup
- ✅ Workshop directory structure creation
- ✅ Validation scripts and utilities
- ✅ Troubleshooting and support information

## Quick Start

1. **Choose your preferred format:**
   - Markdown: `setup-guides/complete-workshop-setup.md`
   - AsciiDoc: `adoc-setup-guides/complete-workshop-setup.adoc`

2. **Follow the setup steps** in order

3. **Run the validation script** to ensure everything is configured correctly

4. **Begin with Lab 01** once setup validation passes

## Important Notes

### 🚨 Credential Configuration Required
The setup guides contain placeholder values that **MUST** be replaced with your actual GCP credentials:

```bash
# REPLACE THESE VALUES WITH YOUR ACTUAL INFORMATION
export PROJECT_ID="YOUR_PROJECT_ID_HERE"
export BILLING_ACCOUNT="YOUR_BILLING_ACCOUNT_ID"
```

### 🔧 System Requirements
- Ubuntu 20.04 LTS or later (recommended)
- 8GB RAM minimum (16GB recommended)
- 20GB free disk space
- Stable internet connection

### 📋 Prerequisites
- Valid GCP account with billing enabled
- Project with Owner role permissions
- Basic familiarity with Linux/bash commands

## Support

If you encounter issues during setup:
1. Check the troubleshooting sections in the setup guides
2. Run the validation scripts to identify specific problems
3. Consult the workshop instructor or support team
4. Reference the GCP documentation for additional help

## File Structure

```
setup-guides/
├── README.md                           # This file
├── 00-lab-environment-setup.md         # Basic setup (original)
└── complete-workshop-setup.md          # Comprehensive setup (recommended)

adoc-setup-guides/
├── 00-lab-environment-setup.adoc       # Basic setup (AsciiDoc)
└── complete-workshop-setup.adoc        # Comprehensive setup (AsciiDoc)
```

---

**Ready to begin?** Choose your setup guide and start building your GCP Landing Zone! 🚀
