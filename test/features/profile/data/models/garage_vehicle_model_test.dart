import 'package:autolab_customer/features/profile/data/models/garage_vehicle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps is_default from Supabase', () {
    final vehicle = GarageVehicleModel.fromMap({
      'id': 'vehicle-1',
      'license_plate': 'ABC123',
      'is_default': true,
      'image_path': 'user-1/vehicle-1/vehicle-image',
    }, imageUrl: 'https://example.com/signed-image');

    expect(vehicle.isDefault, isTrue);
    expect(vehicle.imagePath, 'user-1/vehicle-1/vehicle-image');
    expect(vehicle.imageUrl, 'https://example.com/signed-image');
  });
}
