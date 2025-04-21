# AWS Disaster Recovery Infrastructure

This repository contains Terraform configurations and management scripts for implementing a robust disaster recovery (DR) solution in AWS. The infrastructure is designed to provide cross-region redundancy with automated failover capabilities.

## Architecture Overview

### Primary Region (eu-west-1)
- VPC with public and private subnets across 3 AZs
- Primary RDS instance with Multi-AZ deployment
- S3 bucket with versioning and encryption
- KMS keys for encryption
- IAM roles for service access
- Security groups for network access control

### DR Region (us-west-1)
- Mirror VPC configuration
- RDS read replica for quick promotion
- S3 bucket with cross-region replication
- Matching KMS and IAM configurations
- Independent security groups

## Prerequisites

1. AWS CLI installed and configured
2. Terraform v1.0.0 or later
3. Appropriate AWS permissions
4. bash shell environment

## Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd aws-dr-terraform
   ```

2. Initialize the infrastructure:
   ```bash
   ./scripts/init.sh
   ```

3. Deploy to your desired environment:
   ```bash
   ./scripts/deploy.sh prod
   ```

## Configuration

### Directory Structure
```
.
├── modules/
│   ├── iam/       # IAM roles and policies
│   ├── rds/       # RDS primary and replica
│   ├── s3/        # S3 buckets with replication
│   ├── security/  # Security groups
│   └── vpc/       # Network configuration
├── primary/       # Primary region configuration
├── dr/           # DR region configuration
└── scripts/      # Management scripts
```

### Configuration Files
- `terraform.tfvars`: Main variable definitions
- `primary/terraform.tfvars`: Primary region specifics
- `dr/terraform.tfvars`: DR region specifics

## Management Scripts

### 1. Initialization
```bash
./scripts/init.sh
```
- Sets up S3 backend for state management
- Creates DynamoDB table for state locking
- Initializes Terraform

### 2. Deployment
```bash
./scripts/deploy.sh <environment>
```
- Validates environment
- Plans and applies changes
- Supports dev/staging/prod environments

### 3. Monitoring
```bash
./scripts/monitor.sh
```
- Checks RDS replication lag
- Verifies S3 replication status
- Reviews CloudWatch alarms

### 4. Failover
```bash
./scripts/failover.sh
```
- Promotes DR RDS to primary
- Updates DNS records
- Handles failover process

### 5. Cleanup
```bash
./scripts/cleanup.sh <environment>
```
- Safely destroys infrastructure
- Requires explicit confirmation

## Disaster Recovery Process

### Normal Operations
1. Primary RDS serves all database operations
2. DR RDS maintains real-time replication
3. S3 buckets maintain cross-region replication
4. Monitor replication health with `monitor.sh`

### Failover Process
1. Assess the situation and confirm DR necessity
2. Execute `failover.sh`
3. Verify application functionality in DR region
4. Update application configurations if needed

### Recovery Process
1. Resolve primary region issues
2. Re-establish replication
3. Plan maintenance window
4. Fail back to primary region

## Security Considerations

- All data encrypted at rest using KMS
- Network isolation using VPCs and security groups
- IAM roles follow principle of least privilege
- No public access to databases
- Automated secret rotation

## Monitoring and Maintenance

### Regular Tasks
1. Monitor replication lag
2. Review CloudWatch alarms
3. Test failover procedures
4. Update security patches

### Alerts
- RDS replication lag > 5 minutes
- S3 replication failures
- Failed system health checks

## Cost Optimization

- Use appropriate instance sizes
- Monitor and clean up old snapshots
- Set lifecycle policies for S3 objects
- Regular review of resource utilization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please contact the infrastructure team or create an issue in the repository.