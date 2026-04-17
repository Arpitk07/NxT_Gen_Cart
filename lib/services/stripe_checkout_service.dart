import 'package:cloud_functions/cloud_functions.dart';

import '../models/cart_item_model.dart';

class StripeCheckoutService {
  StripeCheckoutService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<String> createCheckoutSession({
    required List<CartItem> items,
    required String trolleyId,
    required String currency,
  }) async {
    if (items.isEmpty) {
      throw StateError('Cannot start payment for an empty cart.');
    }

    final callable = _functions.httpsCallable('createCheckoutSession');
    final payload = <String, dynamic>{
      'trolleyId': trolleyId,
      'currency': currency,
      'items': items
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'name': item.name,
              'unitAmount': (item.price * 100).round(),
              'quantity': item.quantity,
            },
          )
          .toList(),
    };

    final result = await callable.call<Map<String, dynamic>>(payload);
    final url = result.data['url']?.toString();
    if (url == null || url.isEmpty) {
      throw StateError('Stripe Checkout URL was not returned by backend.');
    }
    return url;
  }
}
