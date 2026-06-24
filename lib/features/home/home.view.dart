import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'home.service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeService service = HomeService();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return PageFrame(
      child: RefreshIndicator(
        onRefresh: service.refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppTopBar(),
            const SizedBox(height: 30),
            const Text(
              'Vue d’ensemble',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Voici ce qui bouge sur votre marché cette semaine.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: service.metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: wide ? 1.3 : 1.05,
              ),
              itemBuilder: (context, index) => _MetricCard(
                metric: service.metrics[index],
                icon: const [
                  Icons.remove_red_eye_outlined,
                  Icons.article_outlined,
                  Icons.campaign_outlined,
                  Icons.insights_rounded,
                ][index],
              ),
            ),
            const SizedBox(height: 18),
            const _ImportantAlert(),
            const SizedBox(height: 18),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 3, child: _TrendPanel()),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _ActivityPanel(activities: service.activities),
                  ),
                ],
              )
            else ...[
              const _TrendPanel(),
              const SizedBox(height: 16),
              _ActivityPanel(activities: service.activities),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final DashboardMetric metric;
  final IconData icon;
  const _MetricCard({required this.metric, required this.icon});

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.blue, size: 21),
            ),
            const Spacer(),
            Text(
              metric.trend,
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          metric.value,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        Text(
          metric.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.muted,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}

class _ImportantAlert extends StatelessWidget {
  const _ImportantAlert();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3F2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF6C7C3)),
    ),
    child: const Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Color(0xFFD92D20)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '2 alertes importantes',
                style: TextStyle(
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Des mouvements pourraient affecter votre positionnement.',
                style: TextStyle(color: Color(0xFFD92D20)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TrendPanel extends StatelessWidget {
  const _TrendPanel();

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Évolution de la visibilité',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 190,
          width: double.infinity,
          child: CustomPaint(painter: _TrendPainter()),
        ),
      ],
    ),
  );
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = AppColors.line;
    for (var i = 0; i < 4; i++) {
      final y = i * (size.height - 20) / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final values = [.18, .3, .46, .42, .64, .72, .94];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(
        i * size.width / (values.length - 1),
        size.height - 22 - values[i] * (size.height - 38),
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.blue
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActivityPanel extends StatelessWidget {
  final List<MarketActivity> activities;
  const _ActivityPanel({required this.activities});

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité des concurrents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final item in activities)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              item.company,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(item.activity),
            trailing: Text(
              item.impact,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    ),
  );
}
