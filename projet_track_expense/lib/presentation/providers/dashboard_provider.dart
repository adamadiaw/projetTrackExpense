import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:projet_track_expense/presentation/providers/repository_providers.dart';

final getDashboardDataUseCaseProvider = Provider<GetDashboardDataUseCase>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return GetDashboardDataUseCase(repo);
});

// Provider pour les données du Dashboard
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final useCase = ref.watch(getDashboardDataUseCaseProvider);
  return await useCase();
});