from rest_framework import serializers
from .models import Product, Category

# Serializer for Category
class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name']

# Serializer for Product
class ProductSerializer(serializers.ModelSerializer):
    # This field will display the name of the category instead of just its ID
    category = CategorySerializer(read_only=True)

    # Alternative: To allow POST/PUT requests by ID
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(), source='category', write_only=True
    )

    class Meta:
        model = Product
        fields = ['id', 'name', 'price', 'stock', 'category', 'category_id'] # Include both fields
        read_only_fields = ('category',) # Prevents the full Category object from being written
