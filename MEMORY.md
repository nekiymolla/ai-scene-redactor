# MEMORY — журнал проекта

Читать в начале каждой сессии. Раздел «Текущее состояние» перезаписывается,
«Журнал» только дополняется. Непроверенное помечено **[не проверено]**.

## Текущее состояние (2026-10-14)

**Этап:** 1 — Flutter foundation завершён (CI P1-10 отложен). Следующая
задача: P2-01 (выбор медиа-пакетов) → P2-02 (выбор исходного видео).

### Что реализовано

- Flutter-проект `ai_scene_changer` (iOS + Android), org `com.aiscenechanger`,
  версия `0.1.0+1`, отображаемое имя «AI Scene Changer».
- Тёмная Material 3 тема на токенах (`lib/app/theme/`) + дизайн-система
  **Liquid Glass** (`lib/core/widgets/glass/`): `GlassSurface`, `GlassButton`,
  `GlassIconButton`, `GlassBackButton`, `GlassScaffold`, `AmbientBackground`.
  Все экраны строятся на `GlassScaffold` (см. D-011).
- GoRouter: `/` Home, `/create` (заглушка «в разработке»), `/settings`.
- Riverpod: `appConfigProvider`, `routerProvider`,
  `projectsRepositoryProvider`, `recentProjectsProvider`.
- `AppConfig` из `--dart-define` (`GENERATION_MODE`, `API_BASE_URL`).
- sealed `AppFailure` (Network/Validation/Media/Permission/Generation/Storage/Unexpected).
- Доменные модели: `MediaAsset`, `CharacterReference`, `GenerationSettings`,
  `GenerationRequest` (+`validate()`), `GenerationStatus`, `GenerationJob`
  (`isSynthetic`), `GenerationResult`, `Project`; интерфейс `GenerationGateway`.
- `InMemoryProjectsRepository` — **временный**, данные теряются при перезапуске.
- Home: карточка «Новое видео», недавние проекты с состояниями loading/error/empty.
- Settings: режим обработки, листы «AI-обработка» и «Конфиденциальность», версия.

### Работает только как заглушка / mock

- Экран создания проекта — заглушка.
- Генерации нет ни в каком виде (mock-шлюз — P3-01).

### Не реализовано

Этапы 2–7 целиком (см. DEVELOPMENT_PLAN.md). Бэкенда нет.

### Зависимости

| Пакет | Версия | Зачем |
|---|---|---|
| flutter_riverpod | ^3.4.3 | Состояние |
| go_router | ^18.0.2 | Навигация |
| flutter_lints | (шаблон) | Линтер |

### Окружение (проверено 2026-10-14)

macOS 26.5.1 arm64 · Flutter 3.44.2 · Dart 3.12.2 · Xcode 26.6 · CocoaPods
1.16.2 · Android SDK 36 / JDK 21 · Python 3.14.0 · Docker 28.5.1 · Git 2.50.1.
Нет: ffmpeg, uv. Android SDK-лицензии не приняты (`flutter doctor --android-licenses`).
Устройства: iOS-симулятор iPhone Air, два iPhone по Wi-Fi.

### Ключевые решения (подробно — docs/DECISIONS.md)

- Монорепо: Flutter в корне, бэкенд будет в `backend/`.
- Клиент → только наш бэкенд (`GenerationGateway`); AI-провайдеры и ключи —
  только на сервере (`GenerationProvider`).
- Hosted video-editing API вместо собственного ML-pipeline; ffmpeg на
  бэкенде для звука и нарезки.
- **Free-first** (у автора нет бюджета): Mock → Hugging Face Space (Wan 2.2
  Animate, бесплатная квота, только эксперименты) → fal.ai (Wan Replace ≈
  $0.04/с 480p, Kling O3 Edit ≈ $0.252/с) после согласования.
- Бэкенд MVP: FastAPI + SQLite + локальный диск + asyncio-воркер; без
  PostgreSQL/Redis/S3 до реальной необходимости.
- Без Freezed и кодогенерации Riverpod на старте.
- Liquid Glass — собственная реализация на `BackdropFilter`, без
  экспериментальных пакетов; шейдерное преломление — спайк P1-12.

### Главные риски

1. **Возможности моделей.** Ни одна модель не делает всё сразу: Wan Replace —
   один персонаж; Kling O3 Edit — до 4 референсов, 3–15 с; длинные ролики
   требуют нарезки и дадут швы. Сохранение мимики/монтажа не подтверждено.
2. **Деньги и бесплатные квоты.** Бесплатный путь (HF ZeroGPU) маленький и
   нестабильный; платная генерация стоит денег за каждую секунду; без
   аккаунтов сложно ограничить злоупотребления.
3. **Право и безопасность.** Лица реальных людей (deepfake), чужая музыка и
   видео (трендовые ролики), правила App Store/Google Play, safety-фильтры
   провайдеров могут отклонять запросы.
4. **Медиа на мобильных.** HEVC/HDR/поворот видео с iPhone, большие файлы,
   прерванная загрузка → нужна нормализация через ffmpeg на сервере и
   устойчивая загрузка.
5. **Долгая обработка (минуты).** Приложение сворачивают → нужно
   восстановление задачи по id, позже — push-уведомления.

### Открытые вопросы к автору

- Финальное название продукта и bundle id (сейчас iOS `com.aiscenechanger.aiSceneChanger`, Android `com.aiscenechanger.ai_scene_changer`).
- Видимый водяной знак «AI» на экспортируемом видео — да/нет.
- Срок хранения результатов на сервере (предложено 24 ч).
- Готовность завести бесплатный аккаунт Hugging Face для этапа 5.

### [не проверено]

- Лицензия Wan 2.2 Animate для коммерческого использования.
- Размер бесплатной квоты ZeroGPU и доступность публичного Space с Wan Animate.
- Лимиты Runway `aleph2` API.
- Цены провайдеров (взяты со страниц, не подтверждены счетами).

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
