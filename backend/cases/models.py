from django.db import models
from django.conf import settings


class Case(models.Model):
    """
    Asosiy ish modeli.
    Avval hamma ma'lumotlar JSONField ichida saqlangan, lekin
    endi tezkor qidiruv va filtrlash uchun muhim maydonlar alohida ustunlarga ajratildi.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="cases",
    )

    # Asosiy metadata
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    status = models.CharField(
        max_length=50,
        default="new",
        help_text="Masalan: new, processing, completed",
    )

    # Sudga oid aniq maydonlar (frontenddagi qiymatlar bilan mos)
    court_type = models.CharField(
        max_length=100,
        blank=True,
        help_text="Masalan: Fuqarolik, Jinoyat, Ma'muriy, Iqtisodiy",
    )
    court_stage = models.CharField(
        max_length=100,
        blank=True,
        help_text="Masalan: Tergov, Birinchi instansiya, Apellyatsiya, Kassatsiya, Nazorat tartibida",
    )

    # Mijozga oid ma'lumotlar
    client_name = models.CharField(
        max_length=255,
        blank=True,
        help_text="Himoya qilinayotgan shaxs F.I.O",
    )
    client_role = models.CharField(
        max_length=100,
        blank=True,
        help_text="Masalan: Da'vogar, Javobgar, Sudlanuvchi, Jabrlanuvchi, Guvoh, Boshqa",
    )

    # UI bo'yicha ish holati
    folder = models.CharField(
        max_length=50,
        blank=True,
        default="",
        help_text="Masalan: Faol, Arxivlangan, Muzlatilgan",
    )

    # Muvofiqlik va rejalashtirish
    deadline = models.DateField(
        null=True,
        blank=True,
        help_text="Asosiy muddat (agar mavjud bo'lsa)",
    )

    # Teglar (masalan, 'jinoyat', 'fuqarolik', mavzular va hokazo)
    tags = models.JSONField(default=list, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # AI tahlillari va fayllar uchun maydonlar
    # JSONField SQLite da to'g'ridan-to'g'ri qo'llab-quvvatlanadi (Django 3.1+)
    case_data = models.JSONField(default=dict, blank=True)  # Ish tafsilotlari (to'liq snapshot)
    participants = models.JSONField(default=list, blank=True)  # Qatnashchilar
    files_data = models.JSONField(
        default=list, blank=True
    )  # Fayllar haqida meta-ma'lumot (base64 emas, faqat meta)

    analysis_result = models.JSONField(default=dict, blank=True)  # AI tahlil natijalari
    simulation_data = models.JSONField(
        default=dict, blank=True
    )  # Simulyatsiya natijalari

    class Meta:
        ordering = ["-updated_at"]
        indexes = [
            models.Index(fields=["user", "created_at"]),
            models.Index(fields=["user", "status"]),
            models.Index(fields=["user", "folder"]),
        ]

    def __str__(self) -> str:  # type: ignore[override]
        return f"{self.title} - {self.user.username}"
