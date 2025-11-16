from rest_framework import viewsets,response
from .models import Product
from .serializer import ProductSerializer, CategorySerializer
from django.shortcuts import render

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = CategorySerializer
def index(request):
    return render(request, 'home.html')