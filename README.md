# Multi-Region AWS Deployment with CI/CD (DevSecOps)

A containerized Node.js full-stack app deployed to **two AWS regions** behind **AWS Global Accelerator**, with a **Jenkins** pipeline that builds, smoke-tests, **Trivy-scans** (fails on fixable HIGH/CRITICAL CVEs), pushes to per-region **ECR**, and does a rolling deploy via **ASG Instance Refresh**.

## Architecture
```
            Users
              |
     AWS Global Accelerator (2 static anycast IPs, health-checked)
        /                         \
  us-east-1                    ap-south-1
  ALB -> ASG (EC2 + Docker)    ALB -> ASG (EC2 + Docker)
  ECR                          ECR
```
Jenkins: Checkout -> Docker build -> Smoke test -> Trivy gate -> Push ECR (both regions) -> Instance refresh (both regions)

## Repo layout
| Path | Purpose |
|---|---|
| `app/` | Express API + static frontend, multi-stage `Dockerfile` |
| `Jenkinsfile` | Declarative CI/CD pipeline |
| `terraform/` | VPC, ALB, ASG, ECR, IAM per region (module) + Global Accelerator |

## Prerequisites
- AWS account + CLI credentials, Terraform >= 1.5
- Jenkins agent with Docker, AWS CLI, curl and [Trivy](https://trivy.dev) installed; the `jenkins` user must be in the `docker` group
- Jenkins credentials: `aws-creds` (Username/Password = access key ID/secret), `aws-account-id` (Secret text)

## Deploy
```bash
cd terraform
terraform init
terraform apply          # creates infra in both regions (instances retry pulling until an image exists)
```
Then run the Jenkins pipeline (Pipeline from SCM pointing at this repo). It pushes the image to both ECRs and refreshes the ASGs.

Test:
```bash
terraform output global_accelerator_dns
curl http://<that-dns>/api/info      # returns the region that served you
```
Failover test: set an ASG's desired capacity to 0 in one region; Global Accelerator health checks shift traffic to the other region.

## Run locally
```bash
cd app && npm install && npm start     # http://localhost:3000
docker build -t multi-region-app app/ && docker run -p 3000:3000 multi-region-app
```

## Notes / trade-offs
- Instances sit in public subnets (no NAT, to save cost) but only accept traffic from the ALB security group. For production, use private subnets + NAT/VPC endpoints.
- HTTP only for simplicity; add an ACM certificate + HTTPS listener for production.
- Change regions via `primary_region` / `secondary_region` variables. Keep `AWS_REGION` values in `Jenkinsfile` in sync.
- Cost: ALBs, EC2 and Global Accelerator are billed. Run `terraform destroy` when finished.
