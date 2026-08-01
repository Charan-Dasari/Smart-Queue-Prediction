import sys
import re

with open('README.md', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ('<img src="https://img.shields.io/badge/.NET_8-ASP.NET_Core-512BD4?style=for-the-badge&logo=dotnet&logoColor=white"/>', '<img src="https://img.shields.io/badge/.NET_9-ASP.NET_Core-512BD4?style=for-the-badge&logo=dotnet&logoColor=white"/>'),
    ('<img src="https://img.shields.io/badge/ML-Random_Forest-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white"/>', '<img src="https://img.shields.io/badge/ML-Linear_Regression-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white"/>\n  <img src="https://img.shields.io/badge/Azure-App_Service-0089D6?style=for-the-badge&logo=microsoftazure&logoColor=white"/>'),
    ('ASP.NET Core 8', 'ASP.NET Core 9'),
    ('.NET 8.0 SDK', '.NET 9.0 SDK'),
    ('dotnet/8.0', 'dotnet/9.0'),
    ('Random Forest Regressor', 'Linear Regression model'),
    ('Random Forest', 'Linear Regression'),
    ('ml-model', 'ML'),
    ('localhost:5126', 'localhost:5164'),
    ('// For Android Emulator\nstatic const String baseUrl = \'http://10.0.2.2:5126/api\';\n\n// For physical device (use your machine\'s local IP)\nstatic const String baseUrl = \'http://192.168.x.x:5126/api\';\n\n// For iOS Simulator / Web\nstatic const String baseUrl = \'http://localhost:5126/api\';', '// For Azure Deployment (Production)\nstatic const String baseUrl = \'https://intelliq-api.azurewebsites.net/api\';\n\n// For Local Testing (Web)\nstatic const String baseUrl = \'http://localhost:5164/api\';'),
    ('Base URL: `http://localhost:5164/api`', 'Base URL: `http://localhost:5164/api` (Local) / `https://intelliq-api.azurewebsites.net/api` (Prod)')
]

for old, new in replacements:
    content = content.replace(old, new)

old_sprint = r'### `v1\.0` — Polish, Dark Mode & Final Release \*\(Sprint 5\)\*.*?---'
new_sprint = r'''### `v0.9` — Azure Cloud Deployment, Polish & Dark Mode *(Sprint 5)*
> 🗓️ Production-ready release with CI/CD and full feature completeness

- [x] **Cloud:** Automated CI/CD pipelines via GitHub Actions
- [x] **Cloud:** ASP.NET Backend deployed to Azure App Service (`intelliq-api`)
- [x] **Cloud:** FastAPI ML server deployed to Azure App Service (Linux) (`intelliq-ml`)
- [x] **Cloud:** Flutter Frontend deployed to Azure Static Web Apps
- [x] **Frontend:** Dark Mode / Light Mode toggle with per-user persistence
- [x] **Frontend:** About screen, Help & Support screen, Profile screen updated
- [x] **Frontend:** Dynamic API URL routing (Localhost vs Azure)
- [x] **ML:** Refactored model to `Linear Regression` for faster inference
- [x] **Full:** GitHub structured into isolated deployment branches (`main`, `Frontend`, `Backend`, `ML`)

---'''

content = re.sub(old_sprint, new_sprint, content, flags=re.DOTALL)

with open('README.md', 'w', encoding='utf-8') as f:
    f.write(content)
