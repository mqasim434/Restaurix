import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/credit_ledger_service.dart';
import '../providers/credit_customer_providers.dart';

/// After sync, posts ledger charges for tablet credit orders that arrived remotely.
class CreditOrderChargeProcessor {
  CreditOrderChargeProcessor(this._ledger);

  final CreditLedgerService _ledger;

  Future<void> processAfterSync() => _ledger.processPendingOrderCharges();
}

final creditOrderChargeProcessorProvider =
    Provider<CreditOrderChargeProcessor>((ref) {
  return CreditOrderChargeProcessor(ref.watch(creditLedgerServiceProvider));
});
