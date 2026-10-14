# MEMORY — журнал проекта

Читать в начале каждой сессии. Раздел «Текущее состояние» перезаписывается,
«Журнал» только дополняется. Непроверенное помечено **[не проверено]**.

## Текущее состояние (2026-10-14)

**Этап:** 3 — mock pipeline завершён. P2-09 (системный пикер на реальном
устройстве) всё ещё не проверен. Следующая задача: этап 4, P4-01 (каркас
FastAPI).

### Что реализовано

- Flutter-проект `ai_scene_changer` (iOS 14.0+ и Android), версия `0.1.0+1`.
- Дизайн-система Liquid Glass (`lib/core/widgets/glass/`): `GlassSurface`,
  `GlassButton`, `GlassChip`, `GlassIconButton`, `GlassBackButton`,
  `GlassScaffold` (заголовок, подзаголовок-шаг, плавающие кнопки),
  `GlassTextField`, `GlassSegmented`, `GlassRow`, `SectionCaption`,
  `AmbientBackground`. Токены — `lib/app/theme/app_tokens.dart`.
- Маршруты (все вложены в `/`): `/settings`, `/projects/:id`, `/create`,
  `/create/characters`, `/create/describe`, `/create/review`.
- Мастер создания проекта (4 шага) на `ProjectDraftController`
  (`features/project_creation/application/`), autoDispose; незасохранённый
  черновик удаляет свою папку с медиа.
- Медиа (`lib/core/media/`): `MediaPicker` (image_picker, без запроса
  доступа), `MediaImporter` (копирование в папку проекта, длительность и
  размер через video_player, превью через fc_native_video_thumbnail,
  размер фото через ImageDescriptor), `VideoLimits`/`ImageLimits`.
- Хранилище: `AppStorage` (Documents, относительные пути) +
  `FileProjectsRepository` (project.json на проект, атомарная запись).
- Главный экран: список проектов с превью; экран проекта: видеоплеер
  (создаётся по тапу), описание, персонажи, референсы, параметры, удаление.
- Настройки: режим обработки, AI-обработка, конфиденциальность, версия.
- Доменные модели: `MediaAsset` (в `core/media`), `CharacterReference`
  (+description), `GenerationSettings`, `GenerationRequest` (+validate),
  `GenerationJob`, `GenerationResult`, `Project` (+JSON), `GenerationGateway`.

- Генерация (mock): `features/generation/` — `MockGenerationGateway`
  (статус по времени, задачи в `Documents/mock/jobs.json`),
  `GenerationService`, `JobTracker` (опрос 1 с, backoff до 10 с офлайн),
  экраны `/projects/:id/processing` и `/projects/:id/result` (результат в
  `GlassSheet`). Последний шаг мастера — «Создать видео»: сохраняет и
  запускает. На экране проекта — карточка статуса и главная кнопка по
  состоянию. На главном — живой прогресс активных задач. В Настройках
  (демо) — «Следующая генерация с ошибкой».

### Работает только как заглушка / mock

- Вся генерация — mock: «результат» = исходное видео, помечен
  «Тестовый результат, не AI». Режим `backend` отвечает «Сервер обработки
  ещё не подключён».
- Пока приложение закрыто, статус не обновляется (нет push); догоняет при
  открытии проекта или главного экрана.

### Не реализовано

Этапы 3–7 (см. DEVELOPMENT_PLAN.md). Бэкенда нет. Android
`retrieveLostData` (потеря результата пикера, если система убила Activity).
Редактирование сохранённого проекта.

### Зависимости

| Пакет | Версия | Зачем |
|---|---|---|
| flutter_riverpod | ^3.4.3 | Состояние |
| go_router | ^18.0.2 | Навигация |
| image_picker | ^1.2.4 | Системный выбор фото/видео |
| video_player | ^2.14.1 | Плеер и чтение метаданных видео |
| path_provider | ^2.1.6 | Папка Documents |
| uuid | ^4.6.0 | Идентификаторы |
| fc_native_video_thumbnail | ^3.0.1 | Превью видео |
| clock | ^1.1.2 | Подменяемое время (mock-таймлайн, тесты) |
| integration_test (dev, SDK) | — | Тесты на устройстве |
| fake_async (dev) | ^1.3.3 | Тесты таймеров трекера |

### Окружение (проверено 2026-10-14)

macOS 26.5.1 arm64 · Flutter 3.44.2 · Dart 3.12.2 · Xcode 26.6 · CocoaPods
1.16.2 · Android SDK 36 / JDK 21 · Python 3.14.0 · Docker 28.5.1 · Git 2.50.1.
Нет: ffmpeg, uv. Android SDK-лицензии не приняты. Симулятор: iPhone Air
(045DAF7C-8774-423B-B8BB-F7626A1EB53F). Git remote — SSH
(`git@github.com:nekiymolla/ai-scene-redactor.git`); HTTPS без учётных данных.

### Как проверять

- `flutter analyze`, `flutter test` (unit + widget, без устройства).
- Импорт медиа на симуляторе (свои файлы, в Git не кладём):
  `flutter test integration_test -d <sim> --dart-define=SAMPLE_VIDEO=/abs/clip.mov --dart-define=SAMPLE_IMAGE=/abs/photo.png`.
  Тестовое видео удобно снять так: `xcrun simctl io <sim> recordVideo --codec=h264 clip.mov`.
- Визуальная проверка без ручных нажатий: временный integration-тест,
  который проходит сценарий и печатает маркеры, плюс
  `xcrun simctl io <sim> screenshot` по маркерам (в репозиторий не коммитился).

### Ключевые решения (подробно — docs/DECISIONS.md, D-001…D-019)

- Монорепо: Flutter в корне, бэкенд будет в `backend/`.
- Клиент говорит только с нашим бэкендом (`GenerationGateway`); AI-провайдеры
  и ключи — только на сервере (`GenerationProvider`).
- Hosted video-editing API вместо собственного ML-pipeline.
- **Free-first** (у автора нет бюджета): Mock → Hugging Face Space →
  fal.ai после согласования.
- Бэкенд MVP: FastAPI + SQLite + локальный диск + asyncio-воркер.
- Без Freezed и кодогенерации.
- Liquid Glass — своя реализация на BackdropFilter (D-011).
- Медиа: пути относительно Documents, проект = папка + JSON (D-013).

### Главные риски

1. Возможности моделей (1 персонаж у Wan, 3–15 с и ≤4 референса у Kling).
2. Деньги и нестабильные бесплатные квоты; защита от злоупотреблений.
3. Права: лица, чужая музыка и видео, правила сторов.
4. Медиа на мобильных: HEVC/HDR/поворот, большие файлы.
5. Долгая обработка: сворачивание приложения, восстановление задачи.

### Открытые вопросы к автору

- Финальное название и bundle id (iOS `com.aiscenechanger.aiSceneChanger`,
  Android `com.aiscenechanger.ai_scene_changer`).
- Видимый водяной знак «AI» на экспорте.
- Срок хранения результатов на сервере (предложено 24 ч).
- Бесплатный аккаунт Hugging Face для этапа 5.

### [не проверено]

- Системный пикер (PHPicker / Android Photo Picker) на реальном устройстве.
- Импорт HEVC/HDR-видео с iPhone и видео на Android.
- Производительность стекла на слабых Android.
- Лицензия Wan 2.2 Animate, квота ZeroGPU, лимиты Runway API, цены.

## Журнал

### 2026-10-14 · Итерация 1 — этап 0 и foundation

- Аудит окружения (`flutter doctor -v`, версии инструментов).
- Веб-исследование провайдеров: fal.ai (Kling O1/O3 Edit, Wan 2.2 Animate
  Replace), Runway (aleph2 pricing), открытые веса Wan, HF ZeroGPU.
- `flutter create --project-name ai_scene_changer --org com.aiscenechanger --platforms ios,android .`
- `git init`, ветка `main`, `origin` = https://github.com/nekiymolla/ai-scene-redactor.git.
- `flutter pub add flutter_riverpod go_router`.
- Создан код foundation (см. «Что реализовано») и тесты:
  `test/features/generation/domain/generation_request_test.dart`,
  `test/features/home/home_screen_test.dart`.
- `flutter analyze` → No issues found. `flutter test` → 11/11 passed.
- `flutter build ios --simulator --debug` → ✓ Built Runner.app (26,5 с).
- `flutter build apk --debug` → ✓ Built app-debug.apk (151 с, первая сборка Gradle).
- Запуск на симуляторе iPhone Air (iOS 26.1) через `xcrun simctl`, скриншот
  Home — отрисовка корректна; уменьшен letterSpacing основного текста.
  Экраны Create/Settings на симуляторе вручную не открывались (покрыты widget-тестом).
- Созданы README.md, MEMORY.md, DEVELOPMENT_PLAN.md, docs/*.md, .env.example;
  расширен .gitignore (секреты, Python, samples/).
- Автор попросил по возможности использовать бесплатные модели → решение D-007.

### 2026-10-14 · Итерация 2 — дизайн Liquid Glass

- Запрос автора: стиль Liquid Glass как в iOS 26.
- Исследование: официальной поддержки во Flutter нет; `liquid_glass_renderer`
  0.2.0-dev.4 (experimental), `liquid_glass_native` 0.3.1 и `cupertino_native`
  0.1.1 (platform views, только iOS). Версии проверены через pub.dev API.
- Решение D-011: свой `GlassSurface` на `BackdropFilter`.
- Созданы `lib/core/widgets/glass/*`; Home, Create, Settings и `StateView`
  переведены на стекло; главное действие «Новое видео» — плавающая кнопка
  внизу; кнопки в шапке — круглые стеклянные; листы настроек — стекло.
- Тесты: собственная кнопка «Назад» (поиск по tooltip), тест листа
  «Конфиденциальность», тест отсутствия «Назад» на корне; в тестах включён
  режим `disableAnimations`, иначе фон анимируется бесконечно.
- `flutter analyze` → No issues found; `flutter test` → 12/12 passed;
  `flutter build ios --simulator --debug` → ✓.
- Скриншоты Home и Settings на симуляторе iPhone Air; Settings снят с
  временной сборки, где initialLocation=/settings (правка откатана).
- На Android стекло визуально не проверялось.

### 2026-10-14 · Итерация 3 — этап 2 (интерфейс MVP)

- P2-01: пакеты выбраны по pub.dev API (D-012); добавлены image_picker,
  video_player, path_provider, uuid, fc_native_video_thumbnail,
  integration_test (dev).
- `MediaAsset` перенесён в `lib/core/media/`; `localPath` → `relativePath`.
- Реализованы медиа-сервисы, `AppStorage`, `FileProjectsRepository`,
  `ProjectDraftController`, 4 экрана мастера, экран проекта, общие
  стеклянные контролы, `showFailure`/`confirmDestructive`.
- iOS: `NSPhotoLibraryUsageDescription`, deployment target 13.0 → 14.0
  (Podfile + project.pbxproj), появились Podfile/Podfile.lock.
- Тесты нашли реальные переполнения: текст в узких `GlassButton` и строка
  «статус + дата» на экране проекта — исправлено (Flexible/ellipsis).
- `flutter analyze` → No issues; `flutter test` → 34/34 passed.
- `flutter build ios --simulator --debug` ✓, `flutter build apk --debug` ✓.
- Интеграционный тест импорта на симуляторе iPhone Air → 4/4 passed:
  видео 6,66 с, 1260×2736, превью создано; нечитаемый файл и нарушение
  лимитов отклоняются без копирования.
- Визуальный тур по всем экранам на симуляторе (реальный импорт файлов);
  по скриншотам исправлены: затемнение под шапкой, стеклянные чипы,
  компактная строка «Качество», цвет чекбокса.

### 2026-10-14 · Итерация 4 — этап 3 (mock pipeline)

- Добавлены `clock`, `fake_async` (dev).
- Реализованы mock-шлюз с файловым/памятным хранилищем задач,
  `GenerationService`, `JobTracker`, экраны обработки и результата,
  `ProgressRing`, `GlassSheet`, карточка статуса на экране проекта, живой
  прогресс на главном, переключатель сбоя в Настройках. `Project` получил
  `copyWith`, `lastFailureMessage`, `resultIsSynthetic`.
- По просьбе автора экран результата: вместо уменьшения превью — лист.
- Тесты нашли и помогли исправить: переполнение бейджа результата, двойной
  override провайдера в Riverpod 3 (в TestEnv теперь `customGateway`).
- `flutter analyze` → No issues; `flutter test` → 49/49 passed.
- `flutter build ios --simulator --debug` ✓, `flutter build apk --debug` ✓.
- Тур на симуляторе (демо-таймлайн 20 с): загрузка → очередь → 65% →
  результат → проект «Видео готово» → Настройки → сценарий ошибки и экран
  «Ошибка генерации». Скриншоты проверены; лист проверен свёрнутым и
  развёрнутым.
- Временные файлы сессии (scratchpad) однажды были очищены системой —
  тестовые медиа пришлось записать заново (`simctl io recordVideo`).
