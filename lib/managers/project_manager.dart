/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/project_manager_data.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

/// What the background indexing of the project directory is currently doing.
enum ProjectIndexState
{
  idle,
  indexing,
  error,
}

/// Layout independent options for [ProjectManager].
abstract final class _ProjectManagerOptions
{
  /// How long to wait for the file system to go quiet before reacting.
  ///
  /// A single save writes the project and its thumbnail, and a sync tool writes
  /// a temporary file before renaming it, so events arrive in bursts.
  static const Duration watchDebounce = Duration(milliseconds: 300);

  /// How often to re-scan while the manager is open and watching is unreliable.
  static const Duration pollInterval = Duration(seconds: 5);

  /// How many entries to collect before pushing an intermediate result to the UI.
  static const int publishBatchSize = 8;
}

/// Keeps a cached, up to date view of the project directory.
///
/// The directory is indexed in the background and then watched for changes, so
/// opening the project manager never has to read the file system first.
/// Thumbnails are decoded once and reused until the file behind them changes on
/// disk, which is what makes reopening the manager instant.
///
/// This manager owns the decoded thumbnails and disposes them when an entry is
/// replaced or drops out of the directory.
class ProjectManager
{
  /// All known projects, in directory order. Filtering and sorting is up to the
  /// widget showing them.
  final ValueNotifier<List<ProjectManagerEntryData>> projects = ValueNotifier<List<ProjectManagerEntryData>>(<ProjectManagerEntryData>[]);

  /// Whether an index run is in progress. Drives the progress indicator.
  final ValueNotifier<ProjectIndexState> indexState = ValueNotifier<ProjectIndexState>(ProjectIndexState.idle);

  /// The selected project, kept as a path so a re-index does not drop it.
  final ValueNotifier<String?> selectedPath = ValueNotifier<String?>(null);

  final Map<String, ProjectManagerEntryData> _cache = <String, ProjectManagerEntryData>{};
  final Set<String> _pendingPaths = <String>{};
  final List<ui.Image> _imagesToRetire = <ui.Image>[];

  /// Bumped whenever the cache is invalidated wholesale, so work that is still
  /// in flight for the previous directory can drop what it produced.
  int _generation = 0;

  /// How many open views need the cache to stay fresh.
  int _retainCount = 0;

  bool _started = false;
  bool _watchFailed = false;
  bool _disposed = false;
  String _watchedDir = "";
  StreamSubscription<FileSystemEvent>? _watchSub;
  Timer? _debounceTimer;
  Timer? _pollTimer;

  /// Serializes every mutation of the cache, so a re-index and a single file
  /// update can never interleave.
  Future<void> _queue = Future<void>.value();

  /// Starts indexing and watching the current project directory.
  ///
  /// Returns as soon as the first index run is done; callers that do not want to
  /// wait for it can simply not await it.
  Future<void> start() async
  {
    if (kIsWeb || _started || _disposed)
    {
      return;
    }
    _started = true;
    GetIt.I.get<AppPaths>().projectsDirNotifier.addListener(_onProjectsDirChanged);
    await reindex();
    _startWatch();
  }

  /// Re-reads the whole project directory and updates the cache.
  ///
  /// Unchanged projects keep their decoded thumbnail, so repeated runs are cheap.
  Future<void> reindex() async
  {
    if (kIsWeb || _disposed)
    {
      return;
    }
    //set right away and not only once the queued run starts, so that a view
    //opening on a cold cache shows the spinner instead of "no files found"
    indexState.value = ProjectIndexState.indexing;
    await _enqueue(action: _runFullScan);
  }

  /// Registers an open view of the project list.
  ///
  /// Opening a view re-scans once, because a file system watch can miss changes
  /// made by other applications, and keeps a poll running while it is needed.
  void retain()
  {
    _retainCount++;
    if (_retainCount == 1 && !kIsWeb && !_disposed)
    {
      if (_watchFailed && _watchSub == null)
      {
        //the directory may not have existed when the watch was first set up
        _startWatch();
      }
      unawaited(reindex());
      _updatePolling();
    }
  }

  /// Drops an open view registered with [retain].
  void release()
  {
    if (_retainCount > 0)
    {
      _retainCount--;
    }
    if (_retainCount == 0)
    {
      //the next view starts without a selection, the way a freshly built list did
      selectedPath.value = null;
      _updatePolling();
    }
  }

  /// Stops watching and releases every cached thumbnail.
  void dispose()
  {
    if (_disposed)
    {
      return;
    }
    _disposed = true;
    _generation++;
    _stopWatch();
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_started)
    {
      GetIt.I.get<AppPaths>().projectsDirNotifier.removeListener(_onProjectsDirChanged);
    }
    for (final ProjectManagerEntryData entry in _cache.values)
    {
      entry.thumbnail?.dispose();
    }
    _cache.clear();
    for (final ui.Image image in _imagesToRetire)
    {
      image.dispose();
    }
    _imagesToRetire.clear();
  }

  //--------------------------------------------------------------------------
  // indexing
  //--------------------------------------------------------------------------

  Future<void> _runFullScan() async
  {
    final int generation = _generation;
    final String dir = GetIt.I.get<AppPaths>().projectsDir;
    //everything a queued single file update would have done is covered by a
    //full scan of the same directory
    _pendingPaths.clear();

    final List<ProjectFileStat> stats;
    try
    {
      stats = await runOffThread<List<ProjectFileStat>>(
        work: () => scanProjectDirectory(dir: dir),
        debugLabel: "scanProjectDirectory",
      );
    }
    catch (e, s)
    {
      GetIt.I.get<Logger>().w("Error scanning the project directory $dir.", error: e, stackTrace: s);
      if (generation == _generation)
      {
        indexState.value = ProjectIndexState.error;
      }
      return;
    }

    if (generation != _generation)
    {
      return;
    }

    final Set<String> seenKeys = <String>{};
    int sinceLastPublish = 0;
    for (final ProjectFileStat stat in stats)
    {
      seenKeys.add(_keyFor(path: stat.kpixPath));
      final bool changed = await _applyStat(stat: stat, generation: generation);
      if (generation != _generation)
      {
        return;
      }
      if (changed)
      {
        sinceLastPublish++;
        if (sinceLastPublish >= _ProjectManagerOptions.publishBatchSize)
        {
          sinceLastPublish = 0;
          _publish();
        }
      }
    }

    final List<String> goneKeys = _cache.keys.where((final String key) => !seenKeys.contains(key)).toList();
    for (final String key in goneKeys)
    {
      _removeKey(key: key);
    }

    _publish();
  }

  /// Brings the cache entry for a single project file in line with the disk.
  ///
  /// Returns whether the cache actually changed.
  Future<bool> _applyStat({required final ProjectFileStat stat, required final int generation}) async
  {
    final String key = _keyFor(path: stat.kpixPath);
    final ProjectManagerEntryData? cached = _cache[key];
    if (cached != null && cached.canReuseFor(other: stat))
    {
      //keeping the decoded thumbnail is what makes reopening the manager instant
      return false;
    }

    final ui.Image? thumbnail = stat.hasThumbnailFile ? await loadThumbnail(thumbnailPath: stat.thumbnailPath) : null;
    if (generation != _generation)
    {
      thumbnail?.dispose();
      return false;
    }

    _putEntry(
      key: key,
      entry: ProjectManagerEntryData(
        name: extractFilenameFromPath(path: stat.kpixPath, keepExtension: false),
        path: stat.kpixPath,
        thumbnail: thumbnail,
        dateTime: stat.lastModified,
        stat: stat,
      ),
    );
    return true;
  }

  Future<void> _refreshPaths({required final List<String> paths}) async
  {
    final int generation = _generation;
    bool changed = false;
    for (final String path in paths)
    {
      final ProjectFileStat? stat = await statProjectFile(kpixPath: path);
      if (generation != _generation)
      {
        return;
      }
      if (stat == null)
      {
        changed = _removeKey(key: _keyFor(path: path)) || changed;
      }
      else
      {
        changed = await _applyStat(stat: stat, generation: generation) || changed;
      }
      if (generation != _generation)
      {
        return;
      }
    }
    if (changed)
    {
      _publish();
    }
  }

  //--------------------------------------------------------------------------
  // cache bookkeeping
  //--------------------------------------------------------------------------

  String _keyFor({required final String path})
  {
    return p.canonicalize(path);
  }

  void _putEntry({required final String key, required final ProjectManagerEntryData entry})
  {
    final ProjectManagerEntryData? previous = _cache[key];
    _cache[key] = entry;
    if (previous?.thumbnail != null && !identical(previous!.thumbnail, entry.thumbnail))
    {
      _retireImage(image: previous.thumbnail!);
    }
  }

  bool _removeKey({required final String key})
  {
    final ProjectManagerEntryData? removed = _cache.remove(key);
    if (removed == null)
    {
      return false;
    }
    if (removed.thumbnail != null)
    {
      _retireImage(image: removed.thumbnail!);
    }
    final String? selected = selectedPath.value;
    if (selected != null && _keyFor(path: selected) == key)
    {
      selectedPath.value = null;
    }
    return true;
  }

  /// Disposes [image] once the current frame has been painted.
  ///
  /// A [RawImage] that is still in the widget tree holds the handle until the
  /// frame which removes it has been drawn, and disposing before that trips an
  /// assertion in the engine.
  void _retireImage({required final ui.Image image})
  {
    _imagesToRetire.add(image);
    if (_imagesToRetire.length > 1)
    {
      //a flush has already been scheduled and will pick this one up as well
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      final List<ui.Image> images = List<ui.Image>.of(_imagesToRetire);
      _imagesToRetire.clear();
      for (final ui.Image image in images)
      {
        image.dispose();
      }
    });
    //nothing else may be dirty, in which case no frame would ever be produced
    SchedulerBinding.instance.scheduleFrame();
  }

  void _publish()
  {
    projects.value = List<ProjectManagerEntryData>.unmodifiable(_cache.values);
  }

  /// Runs [action] once every earlier queued action has finished.
  ///
  /// Everything that touches the cache goes through here, so a full re-index and
  /// a single file update can never interleave. This also owns the busy state:
  /// an action which failed leaves the error behind, anything else ends idle.
  Future<void> _enqueue({required final Future<void> Function() action}) async
  {
    final Completer<void> completer = Completer<void>();
    final Future<void> previous = _queue;
    _queue = completer.future;
    await previous;
    try
    {
      if (!_disposed)
      {
        indexState.value = ProjectIndexState.indexing;
        await action();
        if (!_disposed && indexState.value == ProjectIndexState.indexing)
        {
          indexState.value = ProjectIndexState.idle;
        }
      }
    }
    catch (e, s)
    {
      GetIt.I.get<Logger>().w("Error updating the project index.", error: e, stackTrace: s);
      indexState.value = ProjectIndexState.error;
    }
    finally
    {
      completer.complete();
    }
  }

  //--------------------------------------------------------------------------
  // directory observation
  //--------------------------------------------------------------------------

  void _onProjectsDirChanged()
  {
    if (kIsWeb || _disposed)
    {
      return;
    }
    //drop everything that belongs to the previous directory
    _generation++;
    _stopWatch();
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingPaths.clear();
    final List<String> keys = _cache.keys.toList();
    for (final String key in keys)
    {
      _removeKey(key: key);
    }
    _publish();
    unawaited(reindex().then((final void _) {_startWatch();}));
  }

  void _startWatch()
  {
    if (kIsWeb || _disposed)
    {
      return;
    }
    //never leave a previous subscription behind, a second directory change while
    //the first one is still re-indexing would otherwise leak it
    _stopWatch();
    final String dir = GetIt.I.get<AppPaths>().projectsDir;
    _watchedDir = dir;
    _watchFailed = false;
    if (!FileSystemEntity.isWatchSupported)
    {
      GetIt.I.get<Logger>().i("Watching the project directory is not supported on this platform, falling back to polling.");
      _watchFailed = true;
      _updatePolling();
      return;
    }
    try
    {
      //watch is not recursive by default, only the project directory itself matters
      _watchSub = Directory(dir).watch().listen(
        _onFileSystemEvent,
        onError: _onWatchError,
        cancelOnError: true,
      );
    }
    catch (e, s)
    {
      GetIt.I.get<Logger>().w("Could not watch the project directory $dir, falling back to polling.", error: e, stackTrace: s);
      _watchFailed = true;
    }
    _updatePolling();
  }

  void _onWatchError(final Object error, final StackTrace stackTrace)
  {
    GetIt.I.get<Logger>().w("The project directory watch failed, falling back to polling.", error: error, stackTrace: stackTrace);
    _stopWatch();
    _watchFailed = true;
    _updatePolling();
  }

  void _stopWatch()
  {
    unawaited(_watchSub?.cancel());
    _watchSub = null;
  }

  void _onFileSystemEvent(final FileSystemEvent event)
  {
    _queueEventPath(path: event.path);
    if (event is FileSystemMoveEvent && event.destination != null)
    {
      _queueEventPath(path: event.destination!);
    }
  }

  void _queueEventPath({required final String path})
  {
    if (!_isRelevantPath(path: path))
    {
      return;
    }
    _pendingPaths.add(_projectPathFor(path: path));
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_ProjectManagerOptions.watchDebounce, _processPendingPaths);
  }

  /// Whether an event for [path] can affect the project list.
  ///
  /// Only project files and thumbnails directly inside the watched directory
  /// matter. Names starting with a dot or a tilde are skipped because that is
  /// how sync tools name the temporary files they write before renaming.
  bool _isRelevantPath({required final String path})
  {
    if (!p.equals(p.dirname(path), _watchedDir))
    {
      return false;
    }
    final String name = p.basename(path);
    if (name.startsWith(".") || name.startsWith("~"))
    {
      return false;
    }
    final String extension = p.extension(path).toLowerCase();
    return extension == ".$fileExtensionKpix" || extension == ".$thumbnailExtension";
  }

  /// Maps a thumbnail path back to the project it belongs to.
  String _projectPathFor({required final String path})
  {
    return p.extension(path).toLowerCase() == ".$thumbnailExtension" ? p.setExtension(path, ".$fileExtensionKpix") : path;
  }

  void _processPendingPaths()
  {
    _debounceTimer = null;
    if (_pendingPaths.isEmpty || _disposed)
    {
      return;
    }
    final List<String> paths = _pendingPaths.toList();
    _pendingPaths.clear();
    unawaited(_enqueue(action: () => _refreshPaths(paths: paths)));
  }

  void _updatePolling()
  {
    //Android reports writes made by other applications unreliably on shared
    //storage, so a sync tool dropping a project into the directory can go
    //unnoticed even when the watch itself works
    final bool watchIsUnreliable = _watchFailed || (!kIsWeb && Platform.isAndroid);
    final bool shouldPoll = watchIsUnreliable && _retainCount > 0 && !_disposed;
    if (shouldPoll)
    {
      _pollTimer ??= Timer.periodic(_ProjectManagerOptions.pollInterval, (final Timer _) {unawaited(reindex());});
    }
    else
    {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }
}

/// Tells the project cache that the project at [path] was written or deleted.
///
/// The cache re-reads the file itself, so the caller does not have to say which
/// of the two happened. This is a no-op when no manager is registered, which
/// keeps the file handling functions usable from tests.
void notifyProjectFileChanged({required final String path})
{
  if (kIsWeb || !GetIt.I.isRegistered<ProjectManager>())
  {
    return;
  }
  final ProjectManager manager = GetIt.I.get<ProjectManager>();
  unawaited(manager._enqueue(action: () => manager._refreshPaths(paths: <String>[path])));
}
