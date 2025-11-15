from rest_framework import viewsets
from .models import Product
from .serializer import ProductSerializer
from django.shortcuts import render,HttpResponse
class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
