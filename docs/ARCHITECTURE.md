# Архитектура

## Обзор

```
┌──────────────────────┐   HTTPS (REST)   ┌───────────────────────────────┐
│ Flutter app          │ ───────────────▶ │ Backend (FastAPI)             │
│                      │                  │                               │
│ GenerationGateway    │                  │ API: /jobs, /uploads          │
│  ├ MockGateway       │                  │ JobService ─ SQLite (MVP)     │
│  └ BackendGateway ───┼──────────────────│ Storage ─ локальный диск (MVP)│
│                      │                  │ Worker (asyncio, in-process)  │
│ ProjectsRepository   │                  │ MediaService ─ ffmpeg/ffprobe │
│  └ JSON на устройстве│                  │ GenerationProvider            │
└──────────────────────┘                  │  ├ MockProvider               │
                                          │  ├ HuggingFaceSpaceProvider   │
                                          │  └ FalProvider (позже, платно)│
                                          └──────────────┬────────────────┘
                                                         │ API-ключи только здесь
                                                         ▼
                                          AI-провайдеры (HF Spaces, fal.ai, …)
```

Статус: реализован клиент до этапа 2 включительно (мастер создания,
медиа, локальное хранение). Генерации и бэкенда пока нет (этапы 3–4).

## Клиент (Flutter)

Структура feature-first:

```
lib/
  main.dart                 ProviderScope + App
  app/
    app.dart                MaterialApp.router
    router/                 GoRouter, константы маршрутов
    theme/                  токены дизайн-системы и ThemeData
  core/
    config/                 AppConfig из --dart-define (без секретов)
    errors/                 sealed AppFailure — типизированные ошибки
    media/                  MediaAsset, MediaPicker, MediaImporter, лимиты
    storage/                AppStorage — корень Documents, относительные пути
    utils/                  форматирование дат, длительностей, размеров
    widgets/                стекло (glass/), медиа (media/), состояния, диалоги
  features/
    home/presentation/
    project_creation/{application,presentation}/   черновик + 4 шага мастера
    generation/domain/      GenerationRequest, GenerationJob, GenerationGateway
    projects/{domain,data,application,presentation}/
    settings/presentation/
```

Правила:

- **presentation** — виджеты; читают состояние только через Riverpod.
- **application** — Riverpod-провайдеры и контроллеры сценариев.
- **domain** — чистые Dart-модели и интерфейсы, без Flutter и без IO.
- **data** — реализации интерфейсов (файлы, HTTP); ловят низкоуровневые
  исключения и превращают их в `AppFailure`.
- Слои создаются, только когда в них появляется код.

### Почему `GenerationGateway`, а не `GenerationProvider` на клиенте

Клиент не знает об AI-провайдерах — он говорит только с нашим бэкендом.
Абстракция провайдера (`GenerationProvider`) живёт на сервере, где хранятся
ключи. На клиенте — шлюз `GenerationGateway` с двумя реализациями: mock (для
UI без сети) и backend. Название также не путается с Riverpod-провайдерами.

### Состояние задания

```
uploading → queued → processing → succeeded
                 ↘        ↘
                  failed / cancelled
```

`GenerationJob.isSynthetic` = true для mock-результатов; UI обязан их
маркировать.

## Бэкенд (план, этап 4)

| Компонент | Выбор для MVP | Почему не больше | Когда менять |
|---|---|---|---|
| Фреймворк | Python + FastAPI | Экосистема для видео/AI, async, OpenAPI | — |
| БД | SQLite (SQLAlchemy) | Один процесс, без отдельного сервера | Несколько инстансов, аккаунты → PostgreSQL |
| Хранилище | Локальный диск за интерфейсом `Storage` | Нет облака — нет счетов | Деплой → S3-совместимое (R2/S3) |
| Очередь | asyncio-воркер в процессе API | Тяжёлая работа у провайдера, мы только опрашиваем | Много задач / несколько воркеров → Redis + arq/Celery |
| Медиа | ffmpeg/ffprobe (CLI) | Стандарт индустрии | — |

Контракт провайдера (Python, концепт):

```python
class GenerationProvider(Protocol):
    name: str
    capabilities: ProviderCapabilities   # макс. длительность, кол-во персонажей, звук

    async def submit(self, job: PreparedJob) -> ProviderTaskRef: ...
    async def get_status(self, ref: ProviderTaskRef) -> ProviderStatus: ...
    async def cancel(self, ref: ProviderTaskRef) -> bool: ...   # best effort
    async def get_result(self, ref: ProviderTaskRef) -> ProviderResult: ...
```

`capabilities` отдаётся клиенту через API, чтобы форма показывала только
поддерживаемые настройки.

## Задел на будущее (не реализуется в MVP)

- **Аккаунты:** у моделей нет `ownerId`; при появлении аккаунтов владение
  хранится на бэкенде, локальные проекты мигрируются. HTTP-клиент получит
  interceptor для токена; токены — в `flutter_secure_storage`.
- **Облачная история/синхронизация:** вторая реализация `ProjectsRepository`.
- **Кредиты и оплата:** проверка баланса — в `JobService` перед `submit`.
