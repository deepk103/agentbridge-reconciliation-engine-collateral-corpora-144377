# Project Structure

```
.
├── workflow.json          # Main n8n workflow definition
├── README.md             # Project overview and quick start
├── package.json          # Node.js package configuration
├── docker-compose.yml    # Docker deployment configuration
├── .env.example         # Environment variables template
├── .gitignore           # Git ignore rules for security
├── LICENSE              # MIT license
├── CHANGELOG.md         # Version history
├── CONTRIBUTING.md      # Contribution guidelines
├── SECURITY.md          # Security policy
├── .github/
│   └── workflows/
│       └── deploy.yml   # CI/CD pipeline
└── docs/
    ├── ARCHITECTURE.md   # System architecture
    ├── DEPLOYMENT.md     # Deployment guide
    ├── CONFIGURATION.md  # Configuration options
    ├── API.md           # API documentation
    ├── TROUBLESHOOTING.md # Common issues
    └── PROJECT_STRUCTURE.md # This file
```

## File Descriptions
- **workflow.json**: Core n8n workflow with 7 nodes
- **docs/**: Comprehensive documentation
- **.github/**: CI/CD and GitHub templates
- **.gitignore**: Prevents sensitive files from being committed
