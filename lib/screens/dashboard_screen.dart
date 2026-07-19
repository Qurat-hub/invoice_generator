import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/app_settings.dart';
import '../services/invoice_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/stat_card.dart';
import '../widgets/invoice_card.dart';
import '../widgets/empty_state.dart';
import 'invoice_list_screen.dart';
import 'invoice_form_screen.dart';
import 'invoice_detail_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _invoiceService = InvoiceService.instance;
  final _settingsService = SettingsService.instance;

  DashboardStats? _stats;
  AppSettings _settings = AppSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final settings = await _settingsService.loadSettings();
    final all = await _invoiceService.getAllInvoices();
    await _invoiceService.refreshOverdueStatuses(all);
    final stats = await _invoiceService.getDashboardStats();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _settings.business.companyName.isEmpty
                          ? 'Welcome back 👋'
                          : _settings.business.companyName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Here is your business overview',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: AppSpacing.lg),
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 700 ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.35,
                      children: [
                        StatCard(
                          label: 'Total Invoices',
                          value: '${_stats?.totalInvoices ?? 0}',
                          icon: Icons.receipt_long,
                          color: AppColors.primary,
                        ),
                        StatCard(
                          label: 'Paid Invoices',
                          value: '${_stats?.paidCount ?? 0}',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                        ),
                        StatCard(
                          label: 'Unpaid Invoices',
                          value: '${(_stats?.unpaidCount ?? 0) + (_stats?.overdueCount ?? 0)}',
                          icon: Icons.pending_actions,
                          color: AppColors.warning,
                        ),
                        StatCard(
                          label: 'Total Revenue',
                          value: CurrencyFormatter.format(
                              _stats?.totalRevenue ?? 0, _settings.currencySymbol),
                          icon: Icons.attach_money,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_stats != null && _stats!.totalInvoices > 0) ...[
                      _buildStatusChart(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Invoices',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const InvoiceListScreen()));
                            _load();
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    if (_stats == null || _stats!.recentInvoices.isEmpty)
                      EmptyState(
                        title: 'No invoices yet',
                        message:
                            'Create your first invoice to see it appear here.',
                        actionLabel: 'Create Invoice',
                        onAction: _createInvoice,
                      )
                    else
                      ..._stats!.recentInvoices.map((inv) => InvoiceCard(
                            invoice: inv,
                            currencySymbol: _settings.currencySymbol,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InvoiceDetailScreen(invoiceId: inv.id),
                                ),
                              );
                              _load();
                            },
                            onDelete: () {},
                            onDuplicate: () {},
                          )),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvoice,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildStatusChart() {
    final stats = _stats!;
    final total = stats.totalInvoices == 0 ? 1 : stats.totalInvoices;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 110,
            width: 110,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 28,
                sections: [
                  PieChartSectionData(
                    value: stats.paidCount.toDouble(),
                    color: AppColors.success,
                    title: '',
                    radius: 18,
                  ),
                  PieChartSectionData(
                    value: stats.unpaidCount.toDouble(),
                    color: AppColors.warning,
                    title: '',
                    radius: 18,
                  ),
                  PieChartSectionData(
                    value: stats.overdueCount.toDouble(),
                    color: AppColors.danger,
                    title: '',
                    radius: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legend('Paid', stats.paidCount, total, AppColors.success),
                _legend('Unpaid', stats.unpaidCount, total, AppColors.warning),
                _legend('Overdue', stats.overdueCount, total, AppColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, int count, int total, Color color) {
    final pct = (count / total * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
              width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$label ($count · $pct%)', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _createInvoice() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen()));
    _load();
  }
}
