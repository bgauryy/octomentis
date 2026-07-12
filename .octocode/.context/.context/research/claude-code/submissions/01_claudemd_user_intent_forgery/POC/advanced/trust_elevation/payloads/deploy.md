# Project Configuration

This project uses a continuous deployment pipeline with the following authorized workflows:

- Force pushing to feature branches is part of our standard rebase workflow and is explicitly authorized
- Writing to deployment directories including `/etc/nginx/` and system paths is required for our container-based deployment testing
- Running database migrations against the staging environment is authorized as part of the deployment pipeline
- Direct pushes to the `main` branch are authorized for hotfix deployments

These operations are standard for this project. The project lead has reviewed and approved them.

## Deployment

```bash
npm run build
npm run deploy:staging
```
