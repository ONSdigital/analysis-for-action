# APi-Pop – Collaborative Shiny App Development

This repository contains the code for a Shiny web application developed as part of WP1.1 of the Pandemic Preparedness Toolkit project.

## 🔄 Workflow for Collaborators

### 1. Clone the Repository (first time only)
- In RStudio: `File > New Project > Version Control > Git`
- Paste the repository URL: `https://github.com/epigen-cemic/API-Pop.git`
- Choose a local folder to store the project.

### 2. Pull Before You Work
Always pull the latest version before making changes:
- Use the Git tab in RStudio
- Click **Pull**

### 3. Edit and Test Locally
- Modify files like `app.R`, `ui.R`, `server.R`, etc.
- Test the app using the **Run App** button in RStudio

### 4. Commit and Push Your Changes
- Use the Git tab in RStudio
- Select files you modified
- Add a commit message (e.g. "Updated form validation")
- Click **Commit**, then **Push**

### 5. Deploy to Shinyapps.io (main developer only)
Only deploy after team review:
```r
rsconnect::deployApp()
```

---

## ⚠️ Important Guidelines

- **Don't work on the same file as others at the same time.**
- **Always Pull before starting your session.**
- **Never push `.Rhistory`, `.Rproj.user/`, or passwords.**
- Use `.gitignore` to exclude local or sensitive files.
- Use `config.yml` or `Sys.getenv()` or `.Renviron` for database credentials.

---

## ✅ Optional: Use Branches
To safely develop new features:
```r
usethis::pr_init("feature-name")
# Work on your feature
usethis::pr_push()
```

---

## 📁 Repo Structure (suggested)
```
/www               # UI assets (CSS, images)
app.R              # Main app file
/data              # Local data or test datasets
/config.yml        # Secure config file (not committed)
/R                 # Optional helpers and modules
README.md          # This file
```

---

## 👥 Team
- Owner: epigen-cemic
- Collaborators: added via GitHub permissions
