import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/google_maps_service.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../settings/providers/settings_providers.dart';

final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService();
});

final deliveryLocationResolverProvider =
    Provider<DeliveryLocationResolver>((ref) {
  return DeliveryLocationResolver(ref.watch(googleMapsServiceProvider));
});

/// Rider-friendly address lines + distance for a Live Order.
final deliveryLocationInfoProvider = FutureProvider.autoDispose
    .family<DeliveryLocationInfo, String>((ref, orderId) async {
  final order = await ref.watch(orderRepositoryProvider).findById(orderId);
  if (order == null) return const DeliveryLocationInfo.empty();

  final settings = await ref.watch(appSettingRepositoryProvider).loadSettings();
  return ref.watch(deliveryLocationResolverProvider).resolve(
        line1: order.deliveryAddressLine1,
        line2: order.deliveryAddressLine2,
        city: order.deliveryCity,
        postcode: order.deliveryPostcode,
        deliveryNotes: order.deliveryNotes,
        businessAddress: settings.businessAddress,
      );
});
