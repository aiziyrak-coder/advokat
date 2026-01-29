from rest_framework import serializers
from .models import Case
from users.serializers import UserSerializer


class CaseSerializer(serializers.ModelSerializer):
    """
    Frontend bilan moslashgan, lekin backend tomonda yanada strukturali
    saqlashni ta'minlaydigan serializer.

    - Frontend hanuzgacha `case_data`, `participants`, `analysis_result` va h.k. bilan ishlashi mumkin.
    - Shu bilan birga `court_type`, `court_stage`, `client_name`, `client_role`, `folder`, `deadline`, `tags`
      maydonlari alohida ustunlarga yoziladi va o'qiladi.
    """

    user_details = UserSerializer(source="user", read_only=True)

    class Meta:
        model = Case
        fields = [
            "id",
            "user",
            "user_details",
            "title",
            "description",
            "status",
            "court_type",
            "court_stage",
            "client_name",
            "client_role",
            "folder",
            "deadline",
            "tags",
            "case_data",
            "participants",
            "files_data",
            "analysis_result",
            "simulation_data",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ("user", "created_at", "updated_at")

    @staticmethod
    def _sync_structured_fields(instance: Case, case_data):
        """
        Frontend `case_data` ichida yuboradigan ma'lumotlarni
        alohida ustunlarga ko'chirib qo'yish.
        """
        if not isinstance(case_data, dict):
            return

        instance.court_type = case_data.get("courtType", instance.court_type or "") or instance.court_type
        instance.court_stage = case_data.get("courtStage", instance.court_stage or "") or instance.court_stage
        instance.client_name = case_data.get("clientName", instance.client_name or "") or instance.client_name
        instance.client_role = case_data.get("clientRole", instance.client_role or "") or instance.client_role

    def create(self, validated_data):
        """
        Yangi ish yaratishda `case_data` dan strukturali maydonlarni ajratib olamiz.
        """
        case_data = validated_data.get("case_data") or {}
        tags = validated_data.get("tags")

        # Agar tags kiritilmagan bo'lsa, case_data ichidan yoki bo'sh ro'yxatdan foydalanamiz
        if tags is None and isinstance(case_data, dict):
            maybe_tags = case_data.get("tags")
            if isinstance(maybe_tags, list):
                validated_data["tags"] = maybe_tags

        instance = Case(**validated_data)
        self._sync_structured_fields(instance, case_data)
        instance.save()
        return instance

    def update(self, instance, validated_data):
        """
        Update vaqtida ham strukturali maydonlarni sinxronlashtiramiz.
        """
        case_data = validated_data.get("case_data", instance.case_data)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        self._sync_structured_fields(instance, case_data)
        instance.save()
        return instance
