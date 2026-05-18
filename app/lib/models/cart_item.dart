class CartItem {
  final String id;
  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final int quantity;
  final double unitPrice;
  final String? designId;
  final List<String> photoUrls;
  // Photobook design: list of pages, each {templateId, photoUrls: [url|null]}
  final List<Map<String, dynamic>>? photobookPages;

  const CartItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
    this.designId,
    this.photoUrls = const [],
    this.photobookPages,
  });

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity, List<String>? photoUrls}) => CartItem(
        id: id,
        productId: productId,
        variantId: variantId,
        productName: productName,
        variantName: variantName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        designId: designId,
        photoUrls: photoUrls ?? this.photoUrls,
        photobookPages: photobookPages,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'productId': productId,
        'variantId': variantId,
        'productName': productName,
        'variantName': variantName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'designId': designId,
        'photoUrls': photoUrls,
        'photobookPages': photobookPages,
      };

  factory CartItem.fromFirestore(Map<String, dynamic> data) => CartItem(
        id: data['id'] as String,
        productId: data['productId'] as String,
        variantId: data['variantId'] as String,
        productName: data['productName'] as String,
        variantName: data['variantName'] as String,
        quantity: (data['quantity'] as num).toInt(),
        unitPrice: (data['unitPrice'] as num).toDouble(),
        designId: data['designId'] as String?,
        photoUrls: (data['photoUrls'] as List?)?.cast<String>() ?? const [],
        photobookPages: (data['photobookPages'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
