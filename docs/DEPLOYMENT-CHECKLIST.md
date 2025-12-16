# Deployment Checklist

## Pre-Deployment

- [ ] S3 bucket created
- [ ] DynamoDB table created
- [ ] OIDC provider created
- [ ] IAM roles deployed
- [ ] GitHub secrets configured
- [ ] GitHub environment created

## Deployment

- [ ] Code pushed to GitHub
- [ ] Init & Validate passed
- [ ] Plan reviewed
- [ ] Docker image built
- [ ] Apply approved
- [ ] Application accessible

## Post-Deployment

- [ ] Health check passing
- [ ] CloudWatch logs visible
- [ ] Auto-scaling configured
- [ ] Monitoring dashboards created

## Testing

- [ ] Homepage loads
- [ ] Health endpoint responds
- [ ] Auto-scaling triggers
- [ ] Logs appear in CloudWatch

## Rollback

If issues occur:
```bash
git revert HEAD
git push origin main
```

Or manually:
```bash
terraform apply -var="container_image="
```