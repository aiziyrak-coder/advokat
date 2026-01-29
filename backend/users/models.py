from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    # Qo'shimcha maydonlar (kerak bo'lsa)
    bio = models.TextField(blank=True)
    
    def __str__(self):
        return self.username
