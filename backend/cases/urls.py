from rest_framework.routers import DefaultRouter
from .views import CaseViewSet

router = DefaultRouter()
router.register(r'', CaseViewSet, basename='cases')

urlpatterns = router.urls
