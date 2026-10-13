# AI Scene Changer

Мобильное приложение (iOS/Android) для AI-трансформации видео: пользователь
загружает исходный ролик, фото людей и текстовое описание, а приложение
заменяет персонажей, одежду, окружение или стиль, по возможности сохраняя
движения, длительность и оригинальный звук.

> Рабочее название. Репозиторий: `ai-scene-redactor`.

## Статус

**MVP: этап 2 (интерфейс) завершён.** AI-генерации пока нет.

| Работает | Ещё нет |
|---|---|
| Дизайн в стиле Liquid Glass (iOS 26) | Генерация, даже mock (этап 3) |
| Мастер из 4 шагов: видео и референсы → персонажи → описание → проверка | Бэкенд (этап 4), реальный AI (этап 5) |
| Выбор видео и фото из галереи, проверка лимитов, превью | Экспорт и «Поделиться» (этап 6) |
| История проектов на устройстве, экран проекта, удаление | Редактирование сохранённого проекта |

Подробно: [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) и [MEMORY.md](MEMORY.md).

## Возможности (цель MVP)

- Выбор исходного видео, фото персонажей и видео-референсов стиля.
- Текстовое описание трансформации и настройки генерации.
- Подтверждение задания, отслеживание статуса, просмотр результата.
- Сохранение в галерею и «Поделиться».
- История проектов на устройстве без регистрации.

## Архитектура

```
Flutter app ──HTTPS──▶ Backend (FastAPI, план) ──▶ AI-провайдеры
GenerationGateway                GenerationProvider: mock / Hugging Face Space / fal.ai
```

- Клиент не знает AI-провайдеров и не хранит ключей.
- Без бюджета: разработка на mock, первые эксперименты — бесплатная квота
  Hugging Face; платные провайдеры — только после согласования.

Документы:

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — компоненты и слои.
- [docs/AI_PIPELINE.md](docs/AI_PIPELINE.md) — провайдеры, лимиты, цены, pipeline.
- [docs/DECISIONS.md](docs/DECISIONS.md) — архитектурные решения.
- [docs/PRIVACY_AND_SAFETY.md](docs/PRIVACY_AND_SAFETY.md) — приватность, согласие, маркировка.

## Технологии

Flutter 3.44 (stable) · Dart 3.12 · Material 3 · flutter_riverpod 3 ·
go_router 18. Бэкенд (план): Python, FastAPI, SQLite, ffmpeg.

## Требования к окружению

Проверено на macOS (Apple Silicon):

- Flutter 3.44.2 stable (Dart 3.12.2)
- Xcode 26.6 + CocoaPods 1.16.2 — для iOS (минимальная версия iOS 14.0)
- Android SDK 36, JDK 21 (из Android Studio) — для Android
- Для бэкенда в будущем: Python 3.12+ и ffmpeg (`brew install ffmpeg`)

## Запуск приложения

```bash
flutter pub get
flutter run                     # выбрать симулятор или устройство
```

Режим генерации задаётся при сборке (секретов на клиенте нет):

```bash
flutter run --dart-define=GENERATION_MODE=mock   # по умолчанию
```

Режим `backend` (`--dart-define=GENERATION_MODE=backend --dart-define=API_BASE_URL=...`)
пока ни к чему не подключён — бэкенда ещё нет.

## Проверки

```bash
dart format lib test integration_test   # форматирование
flutter analyze                         # статический анализ
flutter test                            # unit + widget тесты
```

Интеграционный тест импорта медиа на iOS-симуляторе (нужны свои файлы, в
репозиторий их не кладём; абсолютные пути работают только на симуляторе):

```bash
flutter test integration_test -d <simulator-id> \
  --dart-define=SAMPLE_VIDEO=/abs/path/clip.mov \
  --dart-define=SAMPLE_IMAGE=/abs/path/photo.png
```

## Сборка

```bash
flutter build ios --simulator --debug    # iOS-симулятор
flutter build apk --debug                # Android debug APK
```

Release-сборки и подпись ещё не настроены (P6-06).

## Бэкенд

Пока не реализован (этап 4). Планируемые переменные окружения — в
[.env.example](.env.example). Реальный `.env` в Git не попадает.

## Ограничения текущей версии

- Генерации нет: сохранённый проект можно только просмотреть и удалить.
- Исходное видео — 3–15 секунд и до 200 МБ; фото — от 300×300.
- Системный пикер галереи на реальном устройстве ещё не проверялся.
- Интерфейс только на русском, только тёмная тема.
- На Android не приняты SDK-лицензии (`flutter doctor --android-licenses`).
