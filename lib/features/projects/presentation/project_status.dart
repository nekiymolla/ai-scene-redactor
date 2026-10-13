import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../generation/domain/generation_job.dart';

String projectStatusLabel(GenerationStatus? status) => switch (status) {
  null => 'Черновик',
  GenerationStatus.uploading => 'Загрузка',
  GenerationStatus.queued => 'В очереди',
  GenerationStatus.processing => 'Обработка',
  GenerationStatus.succeeded => 'Готово',
  GenerationStatus.failed => 'Ошибка',
  GenerationStatus.cancelled => 'Отменено',
};

class ProjectStatusChip extends StatelessWidget {
  const ProjectStatusChip({super.key, required this.status});

  final GenerationStatus? status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      GenerationStatus.succeeded => AppColors.success,
      GenerationStatus.failed => AppColors.error,
      null || GenerationStatus.cancelled => AppColors.textSecondary,
      _ => AppColors.primary,
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: color.withValues(alpha: 0.18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          projectStatusLabel(status),
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}
