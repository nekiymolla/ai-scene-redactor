import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../generation/application/generation_providers.dart';
import '../../generation/data/mock_generation_gateway.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return GlassScaffold(
      title: 'Настройки',
      leading: const GlassBackButton(),
      slivers: [
        _Section(
          title: 'Генерация',
          children: [
            ListTile(
              leading: const Icon(Icons.memory_outlined),
              title: const Text('Режим обработки'),
              subtitle: Text(
                config.isMock
                    ? 'Демо-режим: AI не используется, результат — тестовая заглушка'
                    : 'Сервер: ${config.apiBaseUrl ?? 'адрес не задан'}',
              ),
            ),
          ],
        ),
        if (config.isMock)
          _Section(
            title: 'Демо-режим',
            children: [
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.bug_report_outlined),
                title: const Text('Следующая генерация с ошибкой'),
                subtitle: const Text(
                  'Чтобы посмотреть, как приложение показывает сбои',
                ),
                activeTrackColor: AppColors.primary,
                value: ref.watch(mockScenarioProvider) == MockScenario.failure,
                onChanged: (v) => ref
                    .read(mockScenarioProvider.notifier)
                    .set(v ? MockScenario.failure : MockScenario.success),
              ),
            ],
          ),
        _Section(
          title: 'О приложении',
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Как работает AI-обработка'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showInfo(context, 'AI-обработка', _aiInfo),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Конфиденциальность'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  _showInfo(context, 'Конфиденциальность', _privacyInfo),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Версия'),
              subtitle: Text('0.1.0 · MVP в разработке'),
            ),
          ],
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: GlassSurface(
          floating: true,
          shape: const RoundedSuperellipseBorder(borderRadius: AppRadii.hero),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  Text(body, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS-style inset grouped section on glass.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: AppSpacing.page.copyWith(bottom: AppSpacing.lg),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            GlassSurface(
              // Ink ripples need a Material above the glass, not the
              // Scaffold's one below the backdrop filter.
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: AppGlass.divider,
                        ),
                      children[i],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _aiInfo =
    'При подключённом сервере видео, фото и описание отправляются на наш '
    'сервер, а оттуда — внешней AI-модели генерации видео. Результат '
    'создаётся нейросетью и может отличаться от исходника: движения, мимика, '
    'монтаж и звук сохраняются не всегда.\n\n'
    'Сгенерированные ролики — синтетический контент. Не выдавайте их за '
    'реальную съёмку.';

const _privacyInfo =
    'Приложение работает без регистрации. Проекты хранятся только на этом '
    'устройстве.\n\n'
    'Загружайте только те видео, музыку и фотографии, на использование '
    'которых у вас есть права, и фотографии людей только с их согласия.\n\n'
    'В демо-режиме файлы не покидают устройство. Правила хранения файлов на '
    'сервере будут опубликованы здесь до подключения настоящей AI-обработки.';
