import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class StripeService {
  // Create checkout session
  Future<Map<String, dynamic>?> createCheckoutSession(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/stripe/create-checkout-session'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating checkout session: $e');
      return null;
    }
  }

  // Get subscription status
  Future<Map<String, dynamic>?> getSubscriptionStatus(String email) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Constants.baseUrl}/api/stripe/subscription-status?email=$email',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting subscription status: $e');
      return null;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/stripe/cancel-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling subscription: $e');
      return false;
    }
  }
}
