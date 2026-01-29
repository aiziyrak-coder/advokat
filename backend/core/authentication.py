from django.conf import settings
from rest_framework_simplejwt.authentication import JWTAuthentication


class CookieJWTAuthentication(JWTAuthentication):
    """
    JWT autentifikatsiya:
    - Avval Authorization header'dan (Bearer xxx) tokenni o'qiydi
    - Agar u bo'lmasa, access_token cookie'dan tokenni o'qiydi
    """

    def authenticate(self, request):
        # Avval odatdagi header orqali urunib ko'ramiz
        header = self.get_header(request)
        if header is not None:
            return super().authenticate(request)

        # Header bo'lmasa, cookie'dan tokenni olishga harakat qilamiz
        cookie_name = getattr(settings, "AUTH_COOKIE_NAME", "access_token")
        raw_token = request.COOKIES.get(cookie_name)
        if raw_token is None:
            return None

        try:
            validated_token = self.get_validated_token(raw_token)
            return self.get_user(validated_token), validated_token
        except Exception:
            # Token noto'g'ri bo'lsa, autentifikatsiyani muvaffaqiyatsiz deb hisoblaymiz
            return None

