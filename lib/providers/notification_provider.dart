import 'package:fawran/providers/contractsProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hasUnconfirmedContractsProvider = Provider<bool>((ref) {
  final contracts = ref.watch(contractsProvider);

  final hasUnconfirmedPermanent = contracts.permanent.any(
    (c) => c['status_id'] == 1 || c['status'].toLowerCase() == "not confirmed",
  );

  final hasUnconfirmedHourly = contracts.hourly.any(
    (c) => c['status_id'] == 1 || c['status'].toLowerCase() == "not confirmed",
  );

  return hasUnconfirmedPermanent || hasUnconfirmedHourly;
});
