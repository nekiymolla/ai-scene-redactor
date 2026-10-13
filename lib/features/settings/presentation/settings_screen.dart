import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/config/app_config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          const _SectionHeader('Генерация'),
          ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: const Text('Режим обработки'),
            subtitle: Text(
              config.isMock
                  ? 'Демо-режим: AI не используется, результат — тестовая заглушка'
                  : 'Сервер: ${config.apiBaseUrl ?? 'адрес не задан'}',
            ),
          ),
          const _SectionHeader('О приложении'),
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
            onTap: () => _showInfo(context, 'Конфиденциальность', _privacyInfo),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Версия'),
            subtitle: Text('0.1.0 · MVP в разработке'),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

const _aiInfo =
    'При подключённом сервере видео, фото и описание отправляются на наш '
    'сервер, а оттуда — внешней AI-модели генерации видео. Результат создаётся нейросетью и может '
    'отличаться от исходника: движения, мимика, монтаж и звук сохраняются '
    'не всегда.\n\n'
    'Сгенерированные ролики — синтетический контент. Не выдавайте их за '
    'реальную съёмку.';

const _privacyInfo =
    'Приложение работает без регистрации. Проекты хранятся только на этом '
    'устройстве.\n\n'
    'Загружайте только те видео, музыку и фотографии, на использование '
    'которых у вас есть права, и фотографии людей только с их согласия.\n\n'
    'В демо-режиме файлы не покидают устройство. Правила хранения файлов на '
    'сервере будут опубликованы здесь до подключения настоящей AI-обработки.';
