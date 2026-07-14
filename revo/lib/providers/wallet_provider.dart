import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  double _balance = 0;
  List<Map<String, dynamic>> _transactions = [];

  bool get loading => _loading;
  String? get error => _error;
  double get balance => _balance;
  List<Map<String, dynamic>> get transactions => _transactions;

  // ─── Load balance ──────────────────────────────────────────────────────────
  Future<void> loadBalance() async {
    _loading = true;
    notifyListeners();
    final res = await WalletService.getBalance();
    _loading = false;
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      _balance = (data['balance'] as num?)?.toDouble() ?? 0;
    }
    notifyListeners();
  }

  // ─── Load transaction history ──────────────────────────────────────────────
  Future<void> loadHistory() async {
    _loading = true;
    notifyListeners();
    final res = await WalletService.getHistory();
    _loading = false;
    if (res['success'] == true && res['data'] != null) {
      final raw = res['data'];
      if (raw is List) {
        _transactions = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _transactions = [];
      }
    }
    notifyListeners();
  }

  // ─── Topup (dummy — no real gateway) ──────────────────────────────────────
  Future<Map<String, dynamic>> topup(double amount) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final res = await WalletService.topup(amount);
    _loading = false;
    if (res['success'] == true) {
      // Update local balance from response
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        _balance = (data['new_balance'] as num?)?.toDouble() ?? _balance;
      }
      loadHistory();
    } else {
      _error = res['message'] as String?;
    }
    notifyListeners();
    return res;
  }

  // ─── Atomic checkout: place order + wallet deduction in one DB tx ──────────
  Future<Map<String, dynamic>> placeAndPay(
      List<Map<String, dynamic>> items) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final res = await WalletService.placeAndPayWithWallet(items);
    _loading = false;
    if (res['success'] == true) {
      // Refresh balance from server response (most accurate)
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        _balance = (data['wallet_balance'] as num?)?.toDouble() ?? _balance;
      }
      loadHistory();
    } else {
      _error = res['message'] as String?;
    }
    notifyListeners();
    return res;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
