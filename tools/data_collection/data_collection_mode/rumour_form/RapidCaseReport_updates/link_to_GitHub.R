
## Vincular project a GitHUb 

usethis::use_git_config(user.name = "epigen-cemic", user.email = "epigen.cemic@gmail.com")
usethis::use_git()

##Validar token
usethis::create_github_token()

## copiar token en GitHub

## Volvé a R y registrá el token:
gitcreds::gitcreds_set()

##pegar token y luego correr
usethis::use_github()


