import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _AdminOverviewTab(),
          _ProductManagementTab(),
          _SalesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() => _tabIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Sales',
          ),
        ],
      ),
    );
  }
}

class _AdminOverviewTab extends StatefulWidget {
  const _AdminOverviewTab();

  @override
  State<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<_AdminOverviewTab> {
  late Future<_AdminOverviewData> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
  }

  Future<_AdminOverviewData> _loadOverview() async {
    final results = await Future.wait<dynamic>([
      sl<SalesRepository>().getTransactions(),
      sl<ProductRepository>().getProducts(),
    ]);

    return _AdminOverviewData(
      transactions: results[0] as List<TransactionRecord>,
      products: results[1] as List<Product>,
    );
  }

  Future<void> _refreshOverview() async {
    setState(() {
      _overviewFuture = _loadOverview();
    });
    await _overviewFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<_AdminOverviewData>(
      future: _overviewFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insights_outlined,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load admin dashboard',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refreshOverview,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refreshOverview,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminHeroCard(data: data),
                const SizedBox(height: 20),
                Text(
                  'Key Performance Indicators',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A live snapshot of sales, basket health, and catalog size.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1100
                        ? 3
                        : constraints.maxWidth >= 700
                        ? 2
                        : 1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.45,
                      children: [
                        _DashboardMetricCard(
                          title: 'Revenue',
                          value: _formatCurrency(data.revenue),
                          detail: 'Today ${_formatCurrency(data.todayRevenue)}',
                          icon: Icons.payments_outlined,
                          accent: colorScheme.primary,
                          background: colorScheme.primaryContainer,
                        ),
                        _DashboardMetricCard(
                          title: 'Orders',
                          value: '${data.transactionCount}',
                          detail: 'This week ${data.weeklyOrders}',
                          icon: Icons.receipt_long_outlined,
                          accent: colorScheme.tertiary,
                          background: colorScheme.tertiaryContainer,
                        ),
                        _DashboardMetricCard(
                          title: 'Avg. order value',
                          value: _formatCurrency(data.averageOrderValue),
                          detail:
                              'Basket size ${data.averageItemsPerOrder.toStringAsFixed(1)} items',
                          icon: Icons.trending_up_rounded,
                          accent: colorScheme.secondary,
                          background: colorScheme.secondaryContainer,
                        ),
                        _DashboardMetricCard(
                          title: 'Items sold',
                          value: '${data.itemsSold}',
                          detail: 'Top product ${data.topProductName}',
                          icon: Icons.shopping_bag_outlined,
                          accent: colorScheme.tertiary,
                          background: colorScheme.tertiaryContainer,
                        ),
                        _DashboardMetricCard(
                          title: 'Catalog health',
                          value: '${data.productCount}',
                          detail:
                              'Avg product price ${_formatCurrency(data.averageProductPrice)}',
                          icon: Icons.inventory_2_outlined,
                          accent: colorScheme.primary,
                          background: colorScheme.primaryContainer,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Visual trends',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Charts that show how the store is moving, not just where it stands.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;

                    final chartCards = [
                      _DashboardPanel(
                        title: 'Revenue trend',
                        subtitle: 'Last 7 days of sales volume.',
                        child: _LineTrendChart(
                          points: data.revenueTrend,
                          accent: colorScheme.primary,
                          labelFormatter: _formatCurrency,
                        ),
                      ),
                      _DashboardPanel(
                        title: 'Payment mix',
                        subtitle: 'Cash vs card orders.',
                        child: _DonutPaymentChart(
                          cashValue: data.cashOrders.toDouble(),
                          cardValue: data.cardOrders.toDouble(),
                          cashLabel: 'Cash',
                          cardLabel: 'Card',
                          cashColor: colorScheme.tertiary,
                          cardColor: colorScheme.primary,
                        ),
                      ),
                      _DashboardPanel(
                        title: 'Orders by day',
                        subtitle: 'Completed orders in the last week.',
                        child: _BarTrendChart(
                          bars: data.orderTrend,
                          accent: colorScheme.secondary,
                          labelFormatter: (value) => value.toStringAsFixed(0),
                        ),
                      ),
                    ];

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: chartCards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: chartCards[1]),
                          const SizedBox(width: 16),
                          Expanded(child: chartCards[2]),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        chartCards[0],
                        const SizedBox(height: 16),
                        chartCards[1],
                        const SizedBox(height: 16),
                        chartCards[2],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumnLayout = constraints.maxWidth >= 980;

                    final salesPanel = _DashboardPanel(
                      title: 'Sales pulse',
                      subtitle: 'Payment split and revenue momentum.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStatTile(
                                  label: 'Today',
                                  value: _formatCurrency(data.todayRevenue),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MiniStatTile(
                                  label: '7 day revenue',
                                  value: _formatCurrency(data.weekRevenue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _ProgressStat(
                            label: 'Card payments',
                            value: data.cardOrders,
                            total: data.transactionCount,
                            tint: colorScheme.primary,
                          ),
                          const SizedBox(height: 10),
                          _ProgressStat(
                            label: 'Cash payments',
                            value: data.cashOrders,
                            total: data.transactionCount,
                            tint: colorScheme.tertiary,
                          ),
                          const SizedBox(height: 16),
                          _InsightRow(
                            label: 'Latest order',
                            value: data.latestTransaction == null
                                ? 'No transactions yet'
                                : '${_formatCurrency(data.latestTransaction!.total)} • ${_formatShortDateTime(context, data.latestTransaction!.createdAt)}',
                          ),
                          const SizedBox(height: 8),
                          _InsightRow(
                            label: 'Top seller',
                            value:
                                '${data.topProductName} • ${data.topProductUnits} units',
                          ),
                        ],
                      ),
                    );

                    final productsPanel = _DashboardPanel(
                      title: 'Top products',
                      subtitle: 'What customers are buying most often.',
                      child: Column(
                        children: data.topProducts.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No product performance data yet.',
                                    ),
                                  ),
                                ),
                              ]
                            : data.topProducts
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _ProductRankTile(
                                        name: item.name,
                                        units: item.unitsSold,
                                        revenue: item.revenue,
                                        tint: colorScheme.secondary,
                                      ),
                                    ),
                                  )
                                  .toList(),
                      ),
                    );

                    final recentPanel = _DashboardPanel(
                      title: 'Recent orders',
                      subtitle: 'Most recent completed transactions.',
                      child: Column(
                        children: data.recentTransactions.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text('No recent sales to show.'),
                                  ),
                                ),
                              ]
                            : data.recentTransactions
                                  .map(
                                    (sale) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _RecentTransactionTile(
                                        transaction: sale,
                                        subtitle: _formatShortDateTime(
                                          context,
                                          sale.createdAt,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                      ),
                    );

                    if (twoColumnLayout) {
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: salesPanel),
                              const SizedBox(width: 16),
                              Expanded(child: productsPanel),
                            ],
                          ),
                          const SizedBox(height: 16),
                          recentPanel,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        salesPanel,
                        const SizedBox(height: 16),
                        productsPanel,
                        const SizedBox(height: 16),
                        recentPanel,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({required this.data});

  final _AdminOverviewData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.96),
            colorScheme.secondary.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin command center',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.86),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep the store moving with a live performance dashboard.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Track revenue, order volume, basket quality, payment mix, and catalog health from one screen.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.dashboard_customize_outlined,
                    color: colorScheme.onPrimary,
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeroChip(
                  label: 'Revenue',
                  value: _formatCurrency(data.revenue),
                ),
                _HeroChip(label: 'Orders', value: '${data.transactionCount}'),
                _HeroChip(label: 'Top seller', value: data.topProductName),
                _HeroChip(
                  label: 'Catalog',
                  value: '${data.productCount} products',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: background.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.48,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.label,
    required this.value,
    required this.total,
    required this.tint,
  });

  final String label;
  final int value;
  final int total;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total == 0 ? 0.0 : value / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              total == 0 ? '0%' : '${(fraction * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: fraction,
            color: tint,
            backgroundColor: tint.withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductRankTile extends StatelessWidget {
  const _ProductRankTile({
    required this.name,
    required this.units,
    required this.revenue,
    required this.tint,
  });

  final String name;
  final int units;
  final double revenue;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.36,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.sell_outlined, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$units units sold',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(revenue),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({
    required this.transaction,
    required this.subtitle,
  });

  final TransactionRecord transaction;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.36,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transaction.paymentMethod.toLowerCase().contains('cash')
                  ? Icons.payments_outlined
                  : Icons.credit_card_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction #${transaction.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.paymentMethod.toUpperCase()} • $subtitle • ${transaction.cart.items.length} items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(transaction.total),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPerformance {
  const _ProductPerformance({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });

  final String name;
  final int unitsSold;
  final double revenue;
}

class _AdminOverviewData {
  const _AdminOverviewData({
    required this.transactions,
    required this.products,
  });

  final List<TransactionRecord> transactions;
  final List<Product> products;

  int get transactionCount => transactions.length;

  int get productCount => products.length;

  double get revenue =>
      transactions.fold<double>(0, (sum, item) => sum + item.total);

  double get subtotal =>
      transactions.fold<double>(0, (sum, item) => sum + item.subtotal);

  double get discountGiven =>
      transactions.fold<double>(0, (sum, item) => sum + item.discountAmount);

  int get itemsSold => transactions.fold<int>(
    0,
    (sum, item) =>
        sum +
        item.cart.items.fold<int>(
          0,
          (count, cartItem) => count + cartItem.quantity,
        ),
  );

  double get averageOrderValue =>
      transactionCount == 0 ? 0 : revenue / transactionCount;

  double get averageItemsPerOrder =>
      transactionCount == 0 ? 0 : itemsSold / transactionCount;

  double get averageProductPrice => productCount == 0
      ? 0
      : products.fold<double>(0, (sum, product) => sum + product.price) /
            productCount;

  int get cashOrders => transactions
      .where(
        (transaction) =>
            transaction.paymentMethod.toLowerCase().contains('cash'),
      )
      .length;

  int get cardOrders => transactions.length - cashOrders;

  double get todayRevenue {
    final today = _dateOnly(DateTime.now());
    return transactions
        .where((transaction) => _dateOnly(transaction.createdAt) == today)
        .fold<double>(0, (sum, item) => sum + item.total);
  }

  double get weekRevenue {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return transactions
        .where((transaction) => transaction.createdAt.isAfter(start))
        .fold<double>(0, (sum, item) => sum + item.total);
  }

  int get weeklyOrders {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return transactions
        .where((transaction) => transaction.createdAt.isAfter(start))
        .length;
  }

  TransactionRecord? get latestTransaction {
    if (transactions.isEmpty) {
      return null;
    }

    final sorted = [...transactions]
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return sorted.first;
  }

  List<TransactionRecord> get recentTransactions {
    final sorted = [...transactions]
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return sorted.take(5).toList();
  }

  List<_TrendPoint> get revenueTrend {
    final byDay = _lastSevenDays.map((day) {
      final total = transactions
          .where((transaction) => _dateOnly(transaction.createdAt) == day)
          .fold<double>(0, (sum, item) => sum + item.total);
      return _TrendPoint(label: _shortWeekday(day), value: total);
    }).toList();

    return byDay;
  }

  List<_TrendPoint> get orderTrend {
    final byDay = _lastSevenDays.map((day) {
      final total = transactions
          .where((transaction) => _dateOnly(transaction.createdAt) == day)
          .length
          .toDouble();
      return _TrendPoint(label: _shortWeekday(day), value: total);
    }).toList();

    return byDay;
  }

  List<_PaymentSlice> get paymentBreakdown => [
    _PaymentSlice(
      label: 'Cash',
      value: cashOrders.toDouble(),
      colorName: 'cash',
    ),
    _PaymentSlice(
      label: 'Card',
      value: cardOrders.toDouble(),
      colorName: 'card',
    ),
  ];

  List<_ProductPerformance> get topProducts {
    if (transactions.isEmpty) {
      return const <_ProductPerformance>[];
    }

    final performance = <String, _ProductPerformanceAccumulator>{};

    for (final transaction in transactions) {
      for (final item in transaction.cart.items) {
        final key = item.product.id;
        final current =
            performance[key] ??
            _ProductPerformanceAccumulator(item.product.name);
        performance[key] = current.copyWith(
          unitsSold: current.unitsSold + item.quantity,
          revenue: current.revenue + item.lineTotal,
        );
      }
    }

    final sorted = performance.values.toList()
      ..sort((left, right) => right.unitsSold.compareTo(left.unitsSold));

    return sorted
        .take(5)
        .map(
          (item) => _ProductPerformance(
            name: item.name,
            unitsSold: item.unitsSold,
            revenue: item.revenue,
          ),
        )
        .toList();
  }

  String get topProductName =>
      topProducts.isEmpty ? 'No sales yet' : topProducts.first.name;

  int get topProductUnits =>
      topProducts.isEmpty ? 0 : topProducts.first.unitsSold;
}

class _ProductPerformanceAccumulator {
  const _ProductPerformanceAccumulator(
    this.name, {
    this.unitsSold = 0,
    this.revenue = 0,
  });

  final String name;
  final int unitsSold;
  final double revenue;

  _ProductPerformanceAccumulator copyWith({int? unitsSold, double? revenue}) {
    return _ProductPerformanceAccumulator(
      name,
      unitsSold: unitsSold ?? this.unitsSold,
      revenue: revenue ?? this.revenue,
    );
  }
}

String _formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';

String _shortWeekday(DateTime dateTime) => const [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
][dateTime.weekday - 1];

List<DateTime> get _lastSevenDays {
  final today = _dateOnly(DateTime.now());
  return List<DateTime>.generate(
    7,
    (index) => today.subtract(Duration(days: 6 - index)),
  );
}

String _formatShortDateTime(BuildContext context, DateTime dateTime) {
  final localizations = MaterialLocalizations.of(context);
  final timeOfDay = TimeOfDay.fromDateTime(dateTime);

  return '${localizations.formatShortDate(dateTime)} • ${localizations.formatTimeOfDay(timeOfDay, alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat)}';
}

DateTime _dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

class _TrendPoint {
  const _TrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class _PaymentSlice {
  const _PaymentSlice({
    required this.label,
    required this.value,
    required this.colorName,
  });

  final String label;
  final double value;
  final String colorName;
}

class _LineTrendChart extends StatelessWidget {
  const _LineTrendChart({
    required this.points,
    required this.accent,
    required this.labelFormatter,
  });

  final List<_TrendPoint> points;
  final Color accent;
  final String Function(double value) labelFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = points.fold<double>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );

    return AspectRatio(
      aspectRatio: 1.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomPaint(
              painter: _LineTrendPainter(
                points: points,
                accent: accent,
                gridColor: theme.colorScheme.outlineVariant,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                points.isEmpty ? 'No data' : 'Max ${labelFormatter(maxValue)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                points.isEmpty ? '7 days' : '${points.length} points',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineTrendPainter extends CustomPainter {
  _LineTrendPainter({
    required this.points,
    required this.accent,
    required this.gridColor,
  });

  final List<_TrendPoint> points;
  final Color accent;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.28),
          accent.withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.24)
      ..strokeWidth = 1;

    const gridLines = 3;
    for (var index = 1; index <= gridLines; index++) {
      final y = size.height / (gridLines + 1) * index;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    final maxValue = points.fold<double>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );
    final safeMax = maxValue == 0 ? 1 : maxValue;
    final stepX = points.length == 1
        ? size.width
        : size.width / (points.length - 1);

    final linePath = Path();
    final areaPath = Path();

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = stepX * index;
      final y =
          size.height - ((point.value / safeMax) * (size.height - 24)) - 8;

      if (index == 0) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = accent);
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(linePath, paint);
  }

  @override
  bool shouldRepaint(covariant _LineTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accent != accent ||
        oldDelegate.gridColor != gridColor;
  }
}

class _BarTrendChart extends StatelessWidget {
  const _BarTrendChart({
    required this.bars,
    required this.accent,
    required this.labelFormatter,
  });

  final List<_TrendPoint> bars;
  final Color accent;
  final String Function(double value) labelFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = bars.fold<double>(
      0,
      (max, bar) => bar.value > max ? bar.value : max,
    );
    final safeMax = maxValue == 0 ? 1 : maxValue;

    return AspectRatio(
      aspectRatio: 1.45,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in bars)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            labelFormatter(bar.value),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 180,
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: bar.value / safeMax,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accent.withValues(alpha: 0.96),
                                      accent.withValues(alpha: 0.55),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(bar.label, style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPaymentChart extends StatelessWidget {
  const _DonutPaymentChart({
    required this.cashValue,
    required this.cardValue,
    required this.cashLabel,
    required this.cardLabel,
    required this.cashColor,
    required this.cardColor,
  });

  final double cashValue;
  final double cardValue;
  final String cashLabel;
  final String cardLabel;
  final Color cashColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = cashValue + cardValue;
    final cashRatio = total == 0 ? 0.5 : cashValue / total;
    final cardRatio = total == 0 ? 0.5 : cardValue / total;

    return AspectRatio(
      aspectRatio: 1.45,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: [cashRatio, cardRatio],
                    colors: [cashColor, cardColor],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(cardRatio * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'card share',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _LegendPill(label: cashLabel, value: cashValue, color: cashColor),
              _LegendPill(label: cardLabel, value: cardValue, color: cardColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 12;
    final strokeWidth = radius * 0.28;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final safeTotal = total == 0 ? 1 : total;

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    var startAngle = -1.57079632679;
    for (var index = 0; index < values.length; index++) {
      final sweep = (values[index] / safeTotal) * 6.28318530718;
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ${value.toStringAsFixed(0)}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductManagementTab extends StatefulWidget {
  const _ProductManagementTab();

  @override
  State<_ProductManagementTab> createState() => _ProductManagementTabState();
}

class _ProductManagementTabState extends State<_ProductManagementTab> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController(
    text: Product.defaultCategory,
  );
  bool _loading = false;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = sl<ProductRepository>().getProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <Product>[];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading ? null : () => _addProduct(context),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} • \$${product.price.toStringAsFixed(2)}',
                      ),
                      trailing: IconButton(
                        onPressed: () async {
                          await sl<ProductRepository>().deleteProduct(
                            product.id,
                          );
                          if (context.mounted) {
                            setState(() {
                              _productsFuture = sl<ProductRepository>()
                                  .getProducts();
                            });
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addProduct(BuildContext context) async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final category = _categoryController.text.trim();

    if (name.isEmpty || price == null || price <= 0 || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid product data.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await sl<ProductRepository>().upsertProduct(
        Product(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          price: price,
          category: category,
        ),
      );

      if (!context.mounted) {
        return;
      }

      _nameController.clear();
      _priceController.clear();
      _categoryController.text = Product.defaultCategory;
      setState(() {
        _productsFuture = sl<ProductRepository>().getProducts();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product added.')));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $error')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TransactionRecord>>(
      future: sl<SalesRepository>().getTransactions(),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? const <TransactionRecord>[];

        if (sales.isEmpty) {
          return const Center(child: Text('No sales yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sales.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final sale = sales[index];
            return ListTile(
              title: Text('Transaction #${sale.id}'),
              subtitle: Text(
                '${sale.paymentMethod} • ${sale.createdAt.toLocal()}\nItems: ${sale.cart.items.length} • Discount: ${sale.discountAmount > 0 ? sale.discountType.displayName : 'none'}',
              ),
              trailing: Text('\$${sale.total.toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }
}
