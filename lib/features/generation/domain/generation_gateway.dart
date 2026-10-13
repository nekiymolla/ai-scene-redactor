import 'generation_job.dart';
import 'generation_request.dart';

/// The client's only entry point to video generation.
///
/// The app never talks to AI providers directly: a backend implementation
/// forwards to our server, which owns provider keys and selects a
/// `GenerationProvider` (see docs/ARCHITECTURE.md). A mock implementation
/// simulates the lifecycle for UI development without any paid API.
///
/// Methods throw `AppFailure` subclasses on error.
abstract interface class GenerationGateway {
  Future<GenerationJob> submit(GenerationRequest request);

  Future<GenerationJob> getStatus(String jobId);

  /// Best effort: not every provider can stop a running generation.
  Future<void> cancel(String jobId);

  /// Valid only once the job has [GenerationStatus.succeeded].
  Future<GenerationResult> getResult(String jobId);
}
