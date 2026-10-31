import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class MyStatsChart extends StatefulWidget {
  const MyStatsChart({super.key});

  @override
  State<MyStatsChart> createState() => _MyStatsChartState();
}

class _MyStatsChartState extends State<MyStatsChart> {
  late Future<ApiResponse<dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = ApiClient().get(ApiEndpoints.myStats);
  }

  void _reload() {
    setState(() => _statsFuture = ApiClient().get(ApiEndpoints.myStats));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiResponse<dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final response = snapshot.data;
        if (snapshot.hasError || response == null || !response.success) {
          return Card(
            child: ListTile(
              title: const Text('个人统计暂不可用'),
              trailing: IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }

        final data = Map<String, dynamic>.from(response.data as Map);
        final monthly = _asMaps(data['monthly']);
        final distribution = _asMaps(data['fishDistribution']);
        return Column(
          children: [
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '近半年渔获与重量趋势',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (monthly.isEmpty)
                      const SizedBox(
                        height: 150,
                        child: Center(child: Text('还没有可展示的渔获数据')),
                      )
                    else
                      SizedBox(
                        height: 180,
                        child: LineChart(_buildMonthlyChart(monthly)),
                      ),
                    const SizedBox(height: 8),
                    const Wrap(
                      spacing: 16,
                      children: [
                        _ChartLegend(color: AppColors.primary, label: '渔获数量'),
                        _ChartLegend(
                          color: AppColors.secondary,
                          label: '总重量 kg',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '鱼种分布',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (distribution.isEmpty)
                      const SizedBox(
                        height: 150,
                        child: Center(child: Text('还没有鱼种分布数据')),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: PieChart(_buildDistributionChart(distribution)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _asMaps(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  LineChartData _buildMonthlyChart(List<Map<String, dynamic>> monthly) {
    final counts = monthly
        .map((item) => (item['catch_count'] as num?)?.toDouble() ?? 0)
        .toList();
    final weights = monthly
        .map((item) => (item['total_weight'] as num?)?.toDouble() ?? 0)
        .toList();
    final maximum = [
      ...counts,
      ...weights,
    ].fold<double>(1, (current, value) => value > current ? value : current);
    return LineChartData(
      minY: 0,
      maxY: maximum + 1,
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= monthly.length) {
                return const SizedBox.shrink();
              }
              final month = monthly[index]['month'] as String? ?? '';
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  month.substring(month.length > 2 ? month.length - 2 : 0),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            counts.length,
            (index) => FlSpot(index.toDouble(), counts[index]),
          ),
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
        LineChartBarData(
          spots: List.generate(
            weights.length,
            (index) => FlSpot(index.toDouble(), weights[index]),
          ),
          isCurved: true,
          color: AppColors.secondary,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }

  PieChartData _buildDistributionChart(
    List<Map<String, dynamic>> distribution,
  ) {
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 28,
      sections: List.generate(distribution.length, (index) {
        final item = distribution[index];
        final count = (item['count'] as num?)?.toDouble() ?? 0;
        return PieChartSectionData(
          value: count,
          title: '${item['name'] ?? '鱼种'}\n${count.toInt()}',
          color: Colors.primaries[index % Colors.primaries.length],
          radius: 82,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
