from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    # Development uchun parolni biroz erkinroq qilamiz (masalan: "123")
    password = serializers.CharField(write_only=True, min_length=3)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'password', 'bio')

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            bio=validated_data.get('bio', '')
        )
        return user
