from django.urls import path
from . import views
from rest_framework.routers import DefaultRouter
from .views import ProductViewSet

router = DefaultRouter()
router.register(r'products', ProductViewSet, basename='products')

urlpatterns = [

    path('', views.index, name='index'),
              ] + router.urls
