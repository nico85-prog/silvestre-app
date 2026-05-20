import '../models/order.dart';

/// Restituisce gli ID degli ordini in "standby order overload".
///
/// Un ordine è in overload quando:
///  - è stato creato OGGI
///  - è ancora in stato [OrderStatus.submitted] (ricevuto, non ancora avviato)
///  - è oltre la posizione [dailyLimit] nella lista degli ordini "submitted"
///    di oggi ordinati per [createdAt] ascendente (i primi N rientrano,
///    quelli successivi sono in overload).
///
/// Il flag è derivato in lettura: il giorno dopo, automaticamente,
/// nessun ordine risulterà più in overload (cambia il "today").
Set<String> computeOverloadedOrderIds(
  List<CustomerOrder> all,
  int dailyLimit,
) {
  if (dailyLimit <= 0) return const {};
  final now = DateTime.now();
  bool sameDay(DateTime a) =>
      a.year == now.year && a.month == now.month && a.day == now.day;

  final todaySubmitted = all
      .where((o) =>
          sameDay(o.createdAt) && o.status == OrderStatus.submitted)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  if (todaySubmitted.length <= dailyLimit) return const {};
  return todaySubmitted.skip(dailyLimit).map((o) => o.id).toSet();
}
