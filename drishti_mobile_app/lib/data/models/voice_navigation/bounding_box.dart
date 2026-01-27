/// Bounding box for detected objects in vision analysis
class BoundingBox {
  /// X coordinate (normalized 0.0-1.0)
  final double x;
  
  /// Y coordinate (normalized 0.0-1.0)
  final double y;
  
  /// Width (normalized 0.0-1.0)
  final double width;
  
  /// Height (normalized 0.0-1.0)
  final double height;
  
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  
  /// Center X coordinate
  double get centerX => x + width / 2;
  
  /// Center Y coordinate
  double get centerY => y + height / 2;
  
  /// Area of the bounding box
  double get area => width * height;
  
  @override
  String toString() => 'BoundingBox(x: $x, y: $y, w: $width, h: $height)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBox &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;
  
  @override
  int get hashCode =>
      x.hashCode ^ y.hashCode ^ width.hashCode ^ height.hashCode;
}
