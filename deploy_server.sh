#!/bin/bash
echo "=== Starting Teacher Portal Deployment ==="
cd /home/ubuntu/VPHS-TEACHERS-PORTAL

echo "1. Pulling latest commits from GitHub..."
git pull origin master

echo "2. Activating virtual environment..."
source backend/.venv/bin/activate

echo "3. Running Django database migrations..."
python backend/manage.py migrate

echo "4. Setting up default login credentials..."
python backend/manage.py shell -c "
from django.contrib.auth.models import User
t, _ = User.objects.get_or_create(username='teacher')
t.set_password('teacher123')
t.first_name='Sarah'
t.last_name='Conner'
t.email='teacher@vyaspublicschool.in'
t.save()

admin, _ = User.objects.get_or_create(username='admin')
admin.set_password('admin123')
admin.is_superuser=True
admin.is_staff=True
admin.first_name='Principal'
admin.last_name='Office'
admin.email='admin@vyaspublicschool.in'
admin.save()
print('Credentials set successfully!')
"

echo "5. Restoring directory ownership permissions..."
sudo chown -R ubuntu:ubuntu /home/ubuntu/VPHS-TEACHERS-PORTAL

echo "6. Restarting Gunicorn daemon..."
sudo systemctl restart gunicorn

echo "=== Deployment Completed Successfully ==="
