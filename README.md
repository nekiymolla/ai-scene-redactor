# AI Scene Changer

Мобильное приложение (iOS/Android) для AI-трансформации видео: пользователь
загружает исходный ролик, фото людей и текстовое описание, а приложение
заменяет персонажей, одежду, окружение или стиль, по возможности сохраняя
движения, длительность и оригинальный звук.

> Рабочее название. Репозиторий: `ai-scene-redactor`.

## Статус

**Ранний MVP: этап 1 (Flutter foundation).** AI-генерации пока нет.

| Работает | Ещё нет |
|---|---|
| Каркас приложения, тёмная тема, навигация | Выбор медиа из галереи (этап 2) |
| Главный экран с недавними проектами (в памяти) | Сохранение проектов между запусками (P2-08) |
| Настройки: режим обработки, AI-обработка, конфиденциальность | Mock-генерация, экраны Processing/Result (этап 3) |
| Доменные модели и валидация запроса | Бэкенд (этап 4), реальный AI (этап 5) |

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
- Xcode 26.6 + CocoaPods 1.16.2 — для iOS
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
dart format lib test            # форматирование
flutter analyze                 # статический анализ
flutter test                    # unit + widget тесты
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

- Экран «Новый проект» — заглушка, честно помеченная «в разработке».
- Проекты хранятся только в памяти и пропадают при перезапуске.
- AI-генерация не подключена ни в каком виде.
- Интерфейс только на русском, только тёмная тема.
- На Android не приняты SDK-лицензии (`flutter doctor --android-licenses`).
