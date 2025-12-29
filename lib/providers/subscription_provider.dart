import 'package:flutter/material.dart';
import '../services/stripe_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final StripeService _stripeService = StripeService();

  bool _isPremium = false;
  String _subscriptionStatus = 'inactive';
  DateTime? _subscriptionEndDate;
  bool _isLoading = false;

  bool get isPremium => _isPremium;
  String get subscriptionStatus => _subscriptionStatus;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;
  bool get isLoading => _isLoading;

  // Check subscription status
  Future<void> checkSubscriptionStatus(String? email) async {
    if (email == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final status = await _stripeService.getSubscriptionStatus(email);
      if (status != null) {
        _isPremium = status['isPremium'] ?? false;
        _subscriptionStatus = status['subscriptionStatus'] ?? 'inactive';
        if (status['subscriptionEndDate'] != null) {
          _subscriptionEndDate = DateTime.parse(status['subscriptionEndDate']);
        }
      }
    } catch (e) {
      print('Error checking subscription status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create checkout session and return URL
  Future<String?> createCheckoutSession(String email) async {
    try {
      final result = await _stripeService.createCheckoutSession(email);
      if (result != null && result['url'] != null) {
        return result['url'];
      }
      return null;
    } catch (e) {
      print('Error creating checkout session: $e');
      return null;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _stripeService.cancelSubscription(email);
      if (success) {
        await checkSubscriptionStatus(email);
      }
      return success;
    } catch (e) {
      print('Error canceling subscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update premium status (called after successful payment)
  void updatePremiumStatus(bool isPremium) {
    _isPremium = isPremium;
    notifyListeners();
  }

  // Reset subscription data
  void reset() {
    _isPremium = false;
    _subscriptionStatus = 'inactive';
    _subscriptionEndDate = null;
    notifyListeners();
  }
}
