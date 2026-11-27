import 'package:flutter/material.dart';

import '../../shared/format.dart';
import '../../shared/theme.dart';
import '../../shared/view_model_scope.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/grouped.dart';
import '../../shared/widgets/ride_row.dart';
import '../ride_detail/ride_detail_screen.dart';
import './history_view_model.dart';
import 'report_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelScope<HistoryViewModel>(
      create: (scope) => HistoryViewModel(rides: scope.rides, settings: scope.settings),
      builder: (context, vm) => HistoryView(viewModel: vm),
    );
  }
}

class HistoryView extends StatelessWidget {
  const HistoryView({super.key, required this.viewModel});

  final HistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final units = vm.units;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: context.resolve(AppColors.groupedBackground),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(Spacing.md, top + 44, Spacing.md, 60),
            children: [
              LargeTitle(
                'History',
                subtitle:
                    '${vm.rides.length} ${vm.rides.length == 1 ? 'ride' : 'rides'} · ${formatDistance(vm.totalKm, units)} ${distanceUnit(units)}',
              ),
              if (vm.rides.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Column(
                    children: [
                      AppText('No Rides Yet', style: TextStyles.title3),
                      SizedBox(height: Spacing.xs),
                      AppText(
                        'Start a ride from Home. It will be saved here when you finish.',
                        style: TextStyles.subheadline,
                        color: AppColors.secondaryLabel,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final group in vm.groups) ...[
                const SizedBox(height: 20),
                SectionHeader(group.title),
                InsetList(
                  children: [
                    for (final ride in group.rides)
                      RideRow(
                        ride: ride,
                        units: units,
                        showAverage: true,
                        onTap: () => Navigator.of(context, rootNavigator: true).push(RideDetailScreen.route(ride.id)),
                      ),
                  ],
                ),
              ],
            ],
          ),
          if (vm.rides.isNotEmpty)
            Positioned(
              top: top + 2,
              right: Spacing.md,
              child: CircleIconButton(
                icon: Icons.description_outlined,
                label: 'Ride report',
                onPressed: () => _showReport(context, vm),
              ),
            ),
        ],
      ),
    );
  }

  void _showReport(BuildContext context, HistoryViewModel vm) =>
      Navigator.of(context, rootNavigator: true).push(ReportScreen.route());
}
