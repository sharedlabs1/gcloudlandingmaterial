# GCP Landing Zone Workshop Materials

Welcome to the comprehensive GCP Landing Zone Workshop! This repository contains all materials needed for a 2-day hands-on workshop building enterprise-grade cloud infrastructure.

## Quick Start

### 1. Environment Setup
```bash
# Review setup guide
cat setup-guides/00-lab-environment-setup.md

# Check your environment
scripts/check-environment.sh
```

### 2. Workshop Configuration
```bash
# Set up workshop directory
cd ~/gcp-landing-zone-workshop
source workshop-config.env

# Verify setup
scripts/track-progress.sh
```

### 3. Start with Lab 01
```bash
# Begin first lab
cd lab-01
cat ../workshop-materials/lab-guides/lab-01-gcp-organizational-foundation.md
```

## Workshop Structure

| Lab | Title | Duration | Focus Area |
|-----|-------|----------|------------|
| 01 | GCP Organizational Foundation | 45m | Project hierarchy, Terraform basics |
| 02 | Terraform Environment Setup | 45m | Advanced Terraform, modules, KMS |
| 03 | Core Networking Architecture | 60m | VPC, firewalls, load balancers |
| 04 | Network Security Implementation | 60m | Cloud Armor, DDoS protection |
| 05 | Identity and Access Management | 60m | IAM, service accounts, security |
| 06 | Cloud Monitoring Foundation | 45m | Metrics, dashboards, alerting |
| 07 | Cloud Logging Architecture | 45m | Centralized logging, compliance |
| 08 | Shared Services Implementation | 60m | DNS, certificates, security |
| 09 | Workload Environment Setup | 60m | Compute, auto-scaling, HA |
| 10 | Security Controls & Compliance | 60m | Encryption, compliance automation |
| 11 | Advanced Monitoring & Alerting | 60m | SRE practices, incident response |
| 12 | Disaster Recovery & Backup | 45m | Backup strategies, DR procedures |
| 13 | Cost Management & Optimization | 45m | Cost controls, optimization |
| 14 | Final Validation & Optimization | 60m | End-to-end validation |

## Helper Scripts

- **check-environment.sh**: Validate workshop prerequisites
- **track-progress.sh**: Monitor lab completion progress  
- **cleanup-lab.sh**: Clean up individual lab resources

## Support

- 📧 **Technical Issues**: Raise hand for instructor support
- 📖 **Documentation**: Comprehensive guides in each lab
- 🔧 **Troubleshooting**: Common issues and solutions included
- 💬 **Community**: Workshop participant collaboration

## Success Tips

1. **Follow Sequential Order**: Labs build upon each other
2. **Validate Each Lab**: Run validation scripts before proceeding
3. **Save Outputs**: Lab outputs are used by subsequent labs
4. **Ask Questions**: Instructors are here to help
5. **Take Breaks**: Complex material requires mental breaks

## Architecture Overview

The workshop builds a complete TechCorp landing zone including:

- 🏗️ **Organizational Structure**: Projects, folders, billing
- 🌐 **Networking**: VPC, subnets, firewalls, load balancers
- 🔐 **Security**: IAM, encryption, compliance controls
- 📊 **Monitoring**: Metrics, logs, alerting, dashboards
- 🚀 **Workloads**: Compute, storage, applications
- 💰 **Cost Management**: Budgets, optimization, governance

Ready to build enterprise cloud infrastructure? Let's get started! 🚀
