from django.contrib import admin
from .models import Case

@admin.register(Case)
class CaseAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'status', 'created_at', 'updated_at')
    list_filter = ('status', 'created_at', 'updated_at')
    search_fields = ('title', 'description', 'user__username', 'user__email')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-updated_at',)
    
    fieldsets = (
        ('Asosiy Ma\'lumotlar', {
            'fields': ('user', 'title', 'description', 'status')
        }),
        ('AI Tahlillari', {
            'fields': ('case_data', 'participants', 'analysis_result', 'simulation_data'),
            'classes': ('collapse',),
        }),
        ('Fayllar', {
            'fields': ('files_data',),
            'classes': ('collapse',),
        }),
        ('Vaqtlar', {
            'fields': ('created_at', 'updated_at')
        }),
    )
