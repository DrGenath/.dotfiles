alias ll='ls -l'
alias la='ls -la'

alias function='declare -F'

# Python
alias python='winpty python.exe'
alias pip-u='python -m pip install --upgrade pip'

# Shortcuts for Enviromentsetup (Python)
venv-create(){
  python -m venv "$1"
}
alias venv-act='source venv*/Scripts/activate'
alias req-save='pip freeze > requirements.txt'
alias req-install='pip install -r requirements.txt'

# Shortcuts for Django
alias django-install='pip install django pillow martor django-admin-interface python-decouple django-heroku'
django-start(){
  django-admin startproject "$1"
}
alias django-run='python manage.py runserver'
alias django-migrate='python manage.py makemigrations; python manage.py migrate'
alias django-superuser='winpty python manage.py createsuperuser'
alias django-collect='python manage.py collectstatic'
django-procfile(){ # Parameter: projectname(settings.py-file folder)
  touch Procfile
  echo web: gunicorn "$1".wsgi > Procfile
}
django-app(){
  python manage.py startapp "$1"
}
django-setup(){
  mkdir -p static
  mkdir -p media
}