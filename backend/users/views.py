from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from .serializers import UserSerializer
from .models import User
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from datetime import timedelta
from django.conf import settings

@method_decorator(csrf_exempt, name='dispatch')
class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = UserSerializer
    
    def post(self, request, *args, **kwargs):
        # Ma'lumotlarni tozalash - agar username array bo'lsa, birinchi elementni olamiz
        if isinstance(request.data, dict):
            data = request.data.copy()
            if 'username' in data and isinstance(data['username'], list) and len(data['username']) > 0:
                data['username'] = data['username'][0]
            request._full_data = data
        return super().post(request, *args, **kwargs)

class UserProfileView(generics.RetrieveUpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_object(self):
        return self.request.user


class CustomTokenObtainPairView(TokenObtainPairView):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            access_token = response.data.get('access')
            refresh_token = response.data.get('refresh')

            if access_token:
                response.set_cookie(
                    key='access_token',
                    value=access_token,
                    httponly=True,
                    secure=settings.AUTH_COOKIE_SECURE,  # Use setting for secure
                    samesite='Lax',
                    expires=timedelta(minutes=settings.SIMPLE_JWT['ACCESS_TOKEN_LIFETIME'].total_seconds())
                )
            if refresh_token:
                response.set_cookie(
                    key='refresh_token',
                    value=refresh_token,
                    httponly=True,
                    secure=settings.AUTH_COOKIE_SECURE,  # Use setting for secure
                    samesite='Lax',
                    expires=timedelta(days=settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'].days)
                )
            return response
        return response

class CustomTokenRefreshView(TokenRefreshView):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            access_token = response.data.get('access')
            if access_token:
                response.set_cookie(
                    key='access_token',
                    value=access_token,
                    httponly=True,
                    secure=settings.AUTH_COOKIE_SECURE,  # Use setting for secure
                    samesite='Lax',
                    expires=timedelta(minutes=settings.SIMPLE_JWT['ACCESS_TOKEN_LIFETIME'].total_seconds())
                )
            return response
        return response

class LogoutView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, *args, **kwargs):
        response = Response({'detail': 'Successfully logged out.'}, status=status.HTTP_200_OK)
        response.delete_cookie('access_token')
        response.delete_cookie('refresh_token')
        return response