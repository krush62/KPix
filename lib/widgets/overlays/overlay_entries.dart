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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/platform_helper.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_size_widget.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_color_picker_widget.dart';
import 'package:kpix/widgets/extra/about_screen_widget.dart';
import 'package:kpix/widgets/extra/change_text_tool_widget.dart';
import 'package:kpix/widgets/extra/controls_widget.dart';
import 'package:kpix/widgets/extra/credits_widget.dart';
import 'package:kpix/widgets/extra/licenses_widget.dart';
import 'package:kpix/widgets/extra/preferences_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/import_widget.dart';
import 'package:kpix/widgets/file/new_project_widget.dart';
import 'package:kpix/widgets/file/project_manager_widget.dart';
import 'package:kpix/widgets/file/save_as_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/overlays/overlay_add_new_layer_menu.dart';
import 'package:kpix/widgets/overlays/overlay_drawing_layer_menu.dart';
import 'package:kpix/widgets/overlays/overlay_drawing_layer_menu_linked.dart';
import 'package:kpix/widgets/overlays/overlay_load_menu.dart';
import 'package:kpix/widgets/overlays/overlay_raster_layer_menu.dart';
import 'package:kpix/widgets/overlays/overlay_reduced_layer_menu.dart';
import 'package:kpix/widgets/overlays/overlay_save_menu.dart';
import 'package:kpix/widgets/overlays/overlay_selection_align_menu.dart';
import 'package:kpix/widgets/palette/palette_adjustment_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_widget.dart';
import 'package:kpix/widgets/palette/save_palette_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';

/// A dismissable layer above the app, such as a popup menu or a dialog.
///
/// While an overlay is shown the hotkey callbacks are deactivated, so typing in a
/// dialog does not trigger tool shortcuts.
class KPixOverlay implements HotkeySuppressor
{
  /// Whether the entry is currently inserted into an [Overlay].
  bool isVisible;

  /// The entry that is inserted into the [Overlay].
  OverlayEntry entry;

  /// Called when Escape is pressed while this is the topmost overlay; null
  /// ignores the key.
  final Function()? onEscape;

  /// Called when Enter is pressed while this is the topmost overlay; null
  /// ignores the key.
  final Function()? onEnter;

  /// The visible overlays, topmost last.
  static final List<KPixOverlay> _shownOverlays = <KPixOverlay>[];

  KPixOverlay({required this.entry, this.onEscape, this.onEnter, this.isVisible = false});

  static bool _handleKeyEvent(final KeyEvent event)
  {
    if (event is! KeyDownEvent || _shownOverlays.isEmpty)
    {
      return false;
    }
    Function()? action;
    if (event.logicalKey == LogicalKeyboardKey.escape)
    {
      action = _shownOverlays.last.onEscape;
    }
    else if ((event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) && !_isEnterTaken())
    {
      action = _shownOverlays.last.onEnter;
    }
    action?.call();
    return action != null;
  }

  /// Whether Enter belongs to someone else: a modifier combination, or a focused
  /// control such as a button or menu entry that activates on it.
  static bool _isEnterTaken()
  {
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed || keyboard.isAltPressed || keyboard.isMetaPressed)
    {
      return true;
    }
    final BuildContext? focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null)
    {
      return false;
    }
    final Action<ActivateIntent>? activate = Actions.maybeFind<ActivateIntent>(focusContext);
    return activate != null && activate.isEnabled(const ActivateIntent());
  }

  @override
  bool get isSuppressing
  {
    return isVisible;
  }

  /// Inserts the entry into the [Overlay] above [context] and deactivates the
  /// hotkey callbacks.
  ///
  /// Does nothing if the overlay is already visible.
  void show({required final BuildContext context})
  {
    if (!isVisible)
    {
      Overlay.of(context).insert(entry);
      isVisible = true;
      if (_shownOverlays.isEmpty)
      {
        HardwareKeyboard.instance.addHandler(_handleKeyEvent);
      }
      _shownOverlays.add(this);
    }
    GetIt.I.get<HotkeyManager>().deactivateCallbacks(source: this);
  }

  /// Removes the entry from the [Overlay] and reactivates the hotkey callbacks.
  ///
  /// Does nothing if the overlay is not visible.
  void hide()
  {
    if (isVisible)
    {
      GetIt.I.get<HotkeyManager>().activateCallbacks(source: this);
      entry.remove();
      isVisible = false;
      _shownOverlays.remove(this);
      if (_shownOverlays.isEmpty)
      {
        HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
      }
    }
  }
}

/// The layout values shared by all popup menus.
abstract final class OverlayEntrySubMenuOptions
{
  static const double offsetX = 0.0;
  static const double offsetXLeft = -128.0;
  static const double offsetY = 32.0;
  static const double buttonSpacing = 8.0;
  static const double width = 160.0;
  static const double buttonHeight = 24.0;
  static const int smokeOpacity = 128;
  static const int animationLengthMs = 150;
}

/// The layout values shared by all dialogs.
abstract final class OverlayEntryAlertDialogOptions
{
  static const int smokeOpacity = 128;
  static const double minWidth = 200.0;
  static const double minHeight = 150.0;
  static const double maxWidth = 600.0;
  static const double maxHeight = 500.0;
  static const double padding = 8.0;
  static const double borderWidth = 2.0;
  static const double borderRadius = 8.0;
  static const double iconSize = 32.0;
  static const double elevation = 8.0;
}


/// How long the smoke behind an overlay takes to fade in.
///
/// Matched to the content animations of [KPixAnimationWidget] and the anchored
/// menus, so the barrier and the overlay above it arrive together.
const int _barrierFadeMs = OverlayEntrySubMenuOptions.animationLengthMs;

/// Builds an overlay holding [content] above a smoke coloured [ModalBarrier].
///
/// The smoke fades in from fully transparent to [smokeOpacity] while [content]
/// plays its own entry animation. The barrier blocks pointer events for the whole
/// fade, so the overlay below can never be reached during it.
///
/// [onDismiss] is called when the barrier is tapped; a null [onDismiss] makes the
/// barrier swallow taps, so the overlay can only be left through its own controls.
/// [onEscape] and [onEnter] are called when Escape or Enter is pressed; null
/// ignores the key.
KPixOverlay _barrierOverlay({
  required final WidgetBuilder content,
  final Function()? onDismiss,
  final Function()? onEscape,
  final Function()? onEnter,
  required final int smokeOpacity,
})
{
  return KPixOverlay(
    onEscape: onEscape,
    onEnter: onEnter,
    entry: OverlayEntry(
      //text fields forward Escape as a DismissIntent; the key is handled by KPixOverlay
      builder: (final BuildContext context) => Actions(
        actions: <Type, Action<Intent>>{DismissIntent: CallbackAction<DismissIntent>(onInvoke: (final DismissIntent _) => null)},
        child: Stack(
          children: <Widget>[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: _barrierFadeMs),
              curve: Curves.easeInOutCubic,
              builder: (final BuildContext context, final double fade, final Widget? child) => ModalBarrier(
                color: Theme.of(context).primaryColorDark.withAlpha((smokeOpacity * fade).round()),
                onDismiss: onDismiss,
              ),
            ),
            content(context),
          ],
        ),
      ),
    ),
  );
}

/// Centres [child] on desktop and aligns it to the top everywhere else.
Widget _centeredOnDesktop({required final Widget child})
{
  return isDesktop(includingWeb: true)
      ? Center(child: child)
      : Align(alignment: Alignment.topCenter, child: child);
}

/// One of the buttons in the row below the message of a [_messageDialog].
class _DialogAction
{
  const _DialogAction({required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final Function() onPressed;

  /// Resolved when the dialog is built, so a cached dialog follows a locale
  /// change like its message does.
  final LocalizedMessageFn tooltip;
}

/// Builds a dialog showing [message] above a row of [actions].
///
/// [onBarrierDismiss] is called when the barrier is tapped; null makes the barrier
/// swallow taps, so one of the [actions] is the only way out.
KPixOverlay _messageDialog({
  required final LocalizedMessageFn message,
  required final List<_DialogAction> actions,
  final Function()? onBarrierDismiss,
  final Function()? onEscape,
  final Function()? onEnter,
})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onDismiss: onBarrierDismiss,
    onEscape: onEscape,
    onEnter: onEnter,
    content: (final BuildContext context)
    {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      return Center(
        child: KPixAnimationWidget(
          constraints: const BoxConstraints(
            minHeight: OverlayEntryAlertDialogOptions.minHeight,
            minWidth: OverlayEntryAlertDialogOptions.minWidth,
            maxHeight: OverlayEntryAlertDialogOptions.maxHeight,
            maxWidth: OverlayEntryAlertDialogOptions.maxWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                  child: Text(message(l10n), style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  for (final _DialogAction action in actions)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                        child: IconButton.outlined(
                          tooltip: action.tooltip(l10n),
                          icon: Icon(action.icon),
                          onPressed: action.onPressed,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// An overlay holding the [OverlayLoadMenu] anchored at [anchorKey].
///
/// [onDismiss] is called when the barrier behind the menu is tapped.
KPixOverlay getLoadMenu({
  required final Function() onDismiss,
  required final Function() onNewFile,
  required final Function() onLoadFile,
  required final Function() onImportFile,
  required final GlobalKey anchorKey,
})
{
  return _barrierOverlay(
    onDismiss: onDismiss,
    onEscape: onDismiss,
    smokeOpacity: OverlayEntrySubMenuOptions.smokeOpacity,
    content: (final BuildContext context) => OverlayLoadMenu(anchorKey: anchorKey, onNewFile: onNewFile, onImportFile: onImportFile, onLoadFile: onLoadFile),
  );
}

/// An overlay holding the [OverlaySaveMenu] anchored at [anchorKey].
///
/// [onDismiss] is called when the barrier behind the menu is tapped.
KPixOverlay getSaveMenu({
  required final Function() onDismiss,
  required final Function() onSaveFile,
  required final Function() onSaveAsFile,
  required final Function() onExportFile,
  required final GlobalKey anchorKey,
})
{
  return _barrierOverlay(
    onDismiss: onDismiss,
    onEscape: onDismiss,
    smokeOpacity: OverlayEntrySubMenuOptions.smokeOpacity,
    content: (final BuildContext context) => OverlaySaveMenu(anchorKey: anchorKey, onSaveFile: onSaveFile, onSaveAsFile: onSaveAsFile, onExportFile: onExportFile),
  );
}

/// An overlay holding the [OverlayDrawingLayerMenu] anchored at [anchorKey].
///
/// [onDismiss] is called when the barrier behind the menu is tapped.
KPixOverlay getDrawingLayerMenu({
  required final Function() onDismiss,
  required final Function() onDelete,
  required final Function() onMergeDown,
  required final Function() onDuplicate,
  required final GlobalKey anchorKey,
})
{
  return _barrierOverlay(
    onDismiss: onDismiss,
    onEscape: onDismiss,
    smokeOpacity: OverlayEntrySubMenuOptions.smokeOpacity,
    content: (final BuildContext context) => OverlayDrawingLayerMenu(onDelete: onDelete, onMergeDown: onMergeDown, onDuplicate: onDuplicate, anchorKey: anchorKey),
  );
}

/// An overlay holding the [OverlayDrawingLayerMenuLinked] anchored at [anchorKey].
///
/// [onDismiss] is called when the barrier behind the menu is tapped.
KPixOverlay getDrawingLayerMenuLinked({
  required final Function() onDismiss,
  required final Function() onDelete,
  required final Function() onUnlink,
  required final Function() onDuplicate,
  required final GlobalKey anchorKey,
})
{
  return _barrierOverlay(
    onDismiss: onDismiss,
    onEscape: onDismiss,
    smokeOpacity: OverlayEntrySubMenuOptions.smokeOpacity,
    content: (final BuildContext context) => OverlayDrawingLayerMenuLinked(onDelete: onDelete, onUnlink: onUnlink, onDuplicate: onDuplicate, anchorKey: anchorKey),
  );
}

/// An overlay holding the [OverlayReducedLayerMenu] anchored at [anchorKey].
///
/// [onDismiss] is called when the barrier behind the menu is tapped.
KPixOverlay getReducedLayerMenu({
  required final Function() onDismiss,
  required final Function() onDelete,
  required final Function() onDuplicate,
  required final GlobalKey anchorKey,
})
{
  return _barrierOverlay(
    onDismiss: onDismiss,
    onEscape: onDismiss,
    smokeOpacity: OverlayEntrySubMenuOptions.smokeOpacity,
    content: (final BuildContext context) => OverlayReducedLayerMenu(onDelete: onDelete, onDuplicate: onDuplicate, anchorKey: anchorKey),
  );
}

/// An overlay holding the [OverlayRasterLayerMenu] anchored at [anchorKey].
///
/// [onDismiss] is called when the barrier behind the menu is tapped.
KPixOverlay getRasterLayerMenu({
  required final Function() onDismiss,
  required final Function() onDelete,
  required final Function() onDuplicate,
  required final Function() onRaster,
  required final GlobalKey anchorKey,
})
{
  return _barrierOverlay(
    onDismiss: onDismiss,
    onEscape: onDismiss,
    smokeOpacity: OverlayEntrySubMenuOptions.smokeOpacity,
    content: (final BuildContext context) => OverlayRasterLayerMenu(anchorKey: anchorKey, onDuplicate: onDuplicate, onDelete: onDelete, onRaster: onRaster),
  );
}

/// An overlay holding the [OverlayAddNewLayerMenu] anchored at [anchorKey].
///
/// [onDismiss] is called when the barrier behind the menu is tapped.
KPixOverlay getAddNewLayerMenu({
  required final Function() onDismiss,
  required final Function() onNewDrawingLayer,
  required final Function() onNewReferenceLayer,
  required final Function() onNewGridLayer,
  required final Function() onNewShadingLayer,
  required final Function() onNewDitherLayer,
  required final GlobalKey anchorKey,
})
{
  return _barrierOverlay(
    onDismiss: onDismiss,
    onEscape: onDismiss,
    smokeOpacity: OverlayEntrySubMenuOptions.smokeOpacity,
    content: (final BuildContext context) => OverlayAddNewLayerMenu(
      anchorKey: anchorKey,
      onNewDrawingLayer: onNewDrawingLayer,
      onNewReferenceLayer: onNewReferenceLayer,
      onNewGridLayer: onNewGridLayer,
      onNewShadingLayer: onNewShadingLayer,
      onNewDitherLayer: onNewDitherLayer,
    ),
  );
}

/// An overlay holding the [OverlaySelectionAlignMenu] anchored at [anchorKey].
///
/// [onDismiss] is called when the barrier behind the menu is tapped. The menu
/// stays open after an alignment, so several can be applied in a row.
KPixOverlay getSelectionAlignMenu({
  required final Function() onDismiss,
  required final Function() onAlignLeft,
  required final Function() onAlignRight,
  required final Function() onAlignTop,
  required final Function() onAlignBottom,
  required final Function() onAlignCenterH,
  required final Function() onAlignCenterV,
  required final GlobalKey anchorKey,
})
{
  return _barrierOverlay(
    onDismiss: onDismiss,
    onEscape: onDismiss,
    smokeOpacity: OverlayEntrySubMenuOptions.smokeOpacity,
    content: (final BuildContext context) => OverlaySelectionAlignMenu(
      anchorKey: anchorKey,
      onDismiss: onDismiss,
      onAlignLeft: onAlignLeft,
      onAlignRight: onAlignRight,
      onAlignTop: onAlignTop,
      onAlignBottom: onAlignBottom,
      onAlignCenterH: onAlignCenterH,
      onAlignCenterV: onAlignCenterV,
    ),
  );
}

/// An overlay holding the editor for [colorRamp].
///
/// [onAccept] receives the edited ramp, [onDelete] removes it, and [usage]
/// tells the editor how many pixels currently use the ramp. The barrier ignores
/// taps, so the editor can only be left through its own buttons; Escape discards
/// the changes and Enter accepts them.
KPixOverlay getKPal({
  required final ColorRampUpdateFn onAccept,
  required final ColorRampFn onDelete,
  required final KPalRampData colorRamp,
  required final RampPixelUsage usage,
})
{
  final GlobalKey<KPalState> kPalKey = GlobalKey<KPalState>();
  return _barrierOverlay(
    smokeOpacity: KPalWidgetOptions.smokeOpacity,
    onEscape: () => kPalKey.currentState?.discardChange(),
    onEnter: () => kPalKey.currentState?.acceptChange(),
    content: (final BuildContext context) => Padding(
      padding: const EdgeInsets.all(KPalWidgetOptions.outsidePadding),
      child: KPal(
        key: kPalKey,
        accept: onAccept,
        delete: onDelete,
        colorRamp: colorRamp,
        usage: usage,
      ),
    ),
  );
}

/// An overlay holding a dialog with a yes, a no and a cancel button.
///
/// [message] is shown above the buttons. Tapping the barrier calls [onCancel]
/// when [outsideCancelable] is set and is ignored otherwise. Escape always calls
/// [onCancel].
KPixOverlay getThreeButtonDialog({
  required final Function() onYes,
  required final Function() onNo,
  required final Function() onCancel,
  required final bool outsideCancelable,
  required final LocalizedMessageFn message,
})
{
  return _messageDialog(
    message: message,
    onBarrierDismiss: outsideCancelable ? onCancel : null,
    onEscape: onCancel,
    actions: <_DialogAction>[
      _DialogAction(icon: TablerIcons.check, onPressed: onYes, tooltip: (final AppLocalizations l10n) => l10n.yes),
      _DialogAction(icon: TablerIcons.x, onPressed: onNo, tooltip: (final AppLocalizations l10n) => l10n.no),
      _DialogAction(icon: TablerIcons.ban, onPressed: onCancel, tooltip: (final AppLocalizations l10n) => l10n.cancel),
    ],
  );
}

/// An overlay holding a dialog with a yes and a no button.
///
/// [message] is shown above the buttons. Tapping the barrier calls [onNo] when
/// [outsideCancelable] is set and is ignored otherwise. Escape always calls [onNo].
KPixOverlay getTwoButtonDialog({
  required final Function() onYes,
  required final Function() onNo,
  required final bool outsideCancelable,
  required final LocalizedMessageFn message,
})
{
  return _messageDialog(
    message: message,
    onBarrierDismiss: outsideCancelable ? onNo : null,
    onEscape: onNo,
    actions: <_DialogAction>[
      _DialogAction(icon: TablerIcons.check, onPressed: onYes, tooltip: (final AppLocalizations l10n) => l10n.yes),
      _DialogAction(icon: TablerIcons.x, onPressed: onNo, tooltip: (final AppLocalizations l10n) => l10n.no),
    ],
  );
}

/// An overlay holding a dialog with a single confirming button.
///
/// [message] is shown above the button. The barrier ignores taps, so [onAction]
/// is the only way out; Enter calls it too.
KPixOverlay getSingleButtonDialog({
  required final Function() onAction,
  required final LocalizedMessageFn message,
})
{
  return _messageDialog(
    message: message,
    onEnter: onAction,
    actions: <_DialogAction>[
      _DialogAction(icon: TablerIcons.check, onPressed: onAction, tooltip: (final AppLocalizations l10n) => l10n.close),
    ],
  );
}

/// An overlay holding a dialog that asks the user to open the Android
/// "All files access" system settings page.
///
/// [message] is shown above the buttons. Unlike the other dialogs, this one
/// closes itself, so the caller only has to show it.
KPixOverlay getAllFilesAccessDialog({required final LocalizedMessageFn message})
{
  late final KPixOverlay dialog;
  return dialog = getTwoButtonDialog(
    onYes: () {
      dialog.hide();
      openAllFilesAccessSettings();
    },
    onNo: () {
      dialog.hide();
    },
    outsideCancelable: false,
    message: message,
  );
}

/// An overlay holding the dialog for exporting images, animations and palettes.
///
/// The dialog is centred on desktop and aligned to the top everywhere else.
/// Enter exports, but never over an existing file.
KPixOverlay getExportDialog({
  required final Function() onDismiss,
  required final ImageExportDataFn onAcceptImage,
  required final PaletteExportDataFn onAcceptPalette,
  required final AnimationExportDataFn onAcceptAnimation,
})
{
  final GlobalKey<ExportWidgetState> exportKey = GlobalKey<ExportWidgetState>();
  final ExportWidget exportWidget = ExportWidget(key: exportKey, acceptFile: onAcceptImage, acceptPalette: onAcceptPalette, acceptAnimation: onAcceptAnimation, dismiss: onDismiss);
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    onEnter: () => exportKey.currentState?.accept(allowOverwrite: false),
    content: (final BuildContext context) => _centeredOnDesktop(child: exportWidget),
  );
}

/// An overlay holding the dialog for importing an image.
KPixOverlay getImportDialog({
  required final Function() onDismiss,
  required final ImportImageFn onAcceptImage,
})
{
  final GlobalKey<ImportWidgetState> importKey = GlobalKey<ImportWidgetState>();
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    onEnter: () => importKey.currentState?.accept(),
    content: (final BuildContext context) => Center(
      child: ImportWidget(key: importKey, dismiss: onDismiss, import: onAcceptImage,),
    ),
  );
}

/// An overlay holding the dialog for saving the current palette.
///
/// The dialog is centred on desktop and aligned to the top everywhere else.
/// Enter saves, but never over an existing palette.
KPixOverlay getPaletteSaveDialog({
  required final Function() onDismiss,
  required final PaletteExportDataFn onAccept,
})
{
  final GlobalKey<SavePaletteWidgetState> savePaletteKey = GlobalKey<SavePaletteWidgetState>();
  final SavePaletteWidget savePaletteWidget = SavePaletteWidget(key: savePaletteKey, accept: onAccept, dismiss: onDismiss);
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    onEnter: () => savePaletteKey.currentState?.accept(allowOverwrite: false),
    content: (final BuildContext context) => _centeredOnDesktop(child: savePaletteWidget),
  );
}

/// An overlay holding the dialog for saving the project under a new name.
///
/// [callback] is handed on to the [SaveAsWidget]. The dialog is centred on
/// desktop and aligned to the top everywhere else. Enter saves, but never over
/// an existing project.
KPixOverlay getSaveAsDialog({
  required final Function() onDismiss,
  required final SaveFileFn onAccept,
  final Function()? callback,
})
{
  final GlobalKey<SaveAsWidgetState> saveAsKey = GlobalKey<SaveAsWidgetState>();
  final SaveAsWidget saveAsWidget = SaveAsWidget(key: saveAsKey, accept: onAccept, dismiss: onDismiss, callback: callback);
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    onEnter: () => saveAsKey.currentState?.accept(allowOverwrite: false),
    content: (final BuildContext context) => _centeredOnDesktop(child: saveAsWidget),
  );
}

/// An overlay holding the dialog for editing the text of the text tool.
///
/// The input starts out with [initialText] and is limited to [maxLength]
/// characters, or unlimited when that is `null`.
KPixOverlay getChangeTextToolDialog({
  required final Function() onDismiss,
  required final ChangeTextToolFn onAccept,
  required final String initialText,
  final int? maxLength,
})
{
  final GlobalKey<ChangeTextToolWidgetState> changeTextKey = GlobalKey<ChangeTextToolWidgetState>();
  final ChangeTextToolWidget changeTextToolWidget = ChangeTextToolWidget(key: changeTextKey, dismiss: onDismiss, accept: onAccept, initialText: initialText, maxStringLength: maxLength,);
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onDismiss: onDismiss,
    onEscape: onDismiss,
    onEnter: () => changeTextKey.currentState?.accept(),
    content: (final BuildContext context) => _centeredOnDesktop(child: changeTextToolWidget),
  );
}

/// An overlay holding the about screen.
KPixOverlay getAboutDialog({
  required final Function() onDismiss,
})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    content: (final BuildContext context) => Center(
      child: AboutScreenWidget(onDismiss: onDismiss),
    ),
  );
}

/// An overlay holding the licenses of the used packages.
KPixOverlay getLicensesDialog({
  required final Function() onDismiss,
})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    content: (final BuildContext context) => Center(
      child: LicensesWidget(onDismiss: onDismiss),
    ),
  );
}

/// An overlay holding the credits.
KPixOverlay getCreditsDialog({
  required final Function() onDismiss,
})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    content: (final BuildContext context) => Center(
      child: CreditsWidget(onDismiss: onDismiss),
    ),
  );
}

/// An overlay holding the list of controls and shortcuts.
KPixOverlay getControlsDialog({
  required final Function() onDismiss,
})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    content: (final BuildContext context) => Center(
      child: ControlsWidget(onDismiss: onDismiss),
    ),
  );
}

/// An overlay holding the dialog for changing the canvas size.
///
/// The dialog is centred on desktop and aligned to the top everywhere else.
KPixOverlay getCanvasSizeDialog({
  required final Function() onDismiss,
  required final CanvasSizeFn onAccept,
})
{
  final GlobalKey<CanvasSizeWidgetState> canvasSizeKey = GlobalKey<CanvasSizeWidgetState>();
  final CanvasSizeWidget canvasSizeWidget = CanvasSizeWidget(key: canvasSizeKey, accept: onAccept, dismiss: onDismiss);
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    onEnter: () => canvasSizeKey.currentState?.accept(),
    content: (final BuildContext context) => _centeredOnDesktop(child: canvasSizeWidget),
  );
}

/// An overlay holding the preferences.
KPixOverlay getPreferencesDialog({
  required final Function() onDismiss,
  required final Function() onAccept,
})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    onEnter: onAccept,
    content: (final BuildContext context) => Center(
      child: PreferencesWidget(dismiss: onDismiss, accept: onAccept),
    ),
  );
}

/// An overlay holding the dialog for setting up a new project.
///
/// [onOpen] switches over to opening an existing project instead. [onDismiss] is
/// `null` when there is no project to return to, which leaves the dialog without
/// a way to cancel. Escape is ignored, as the dismiss button exits the app; Enter
/// creates the project.
KPixOverlay getNewProjectDialog({
  required final Function()? onDismiss,
  required final NewFileFn onAccept,
  required final Function() onOpen,
})
{
  final GlobalKey<NewProjectWidgetState> newProjectKey = GlobalKey<NewProjectWidgetState>();
  final NewProjectWidget newProjectWidget = NewProjectWidget(key: newProjectKey, accept: onAccept, dismiss: onDismiss, open: onOpen);
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEnter: () => newProjectKey.currentState?.accept(),
    content: (final BuildContext context) => _centeredOnDesktop(child: newProjectWidget),
  );
}

/// An overlay holding the palette manager.
KPixOverlay getPaletteManagerDialog({required final Function() onDismiss})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    content: (final BuildContext context) => Center(
      child: PaletteManagerWidget(dismiss: onDismiss,),
    ),
  );
}

/// An overlay holding the palette adjustments.
///
/// The barrier ignores taps, so the dialog can only be left through its own
/// buttons; a tap outside would leave the adjusted palette behind without the
/// user ever having accepted it. Escape reverts the adjustments, Enter applies
/// them.
KPixOverlay getPaletteAdjustmentDialog({required final Function() onDismiss})
{
  final GlobalKey<PaletteAdjustmentWidgetState> adjustmentKey = GlobalKey<PaletteAdjustmentWidgetState>();
  return _barrierOverlay(
    smokeOpacity: PaletteAdjustmentWidgetOptions.smokeOpacity,
    onEscape: () => adjustmentKey.currentState?.cancel(),
    onEnter: () => adjustmentKey.currentState?.accept(),
    content: (final BuildContext context) => Padding(
      padding: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.outsidePadding),
      child: PaletteAdjustmentWidget(key: adjustmentKey, dismiss: onDismiss),
    ),
  );
}

/// An overlay holding the project manager.
///
/// [onSave] and [onLoad] are handed on to the [ProjectManagerWidget].
KPixOverlay getProjectManagerDialog({required final Function() onDismiss, required final SaveKnownFileFn onSave, required final Function() onLoad})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    content: (final BuildContext context) => Center(
      child: ProjectManagerWidget(dismiss: onDismiss, saveKnownFileFn: onSave, fileLoad: onLoad,),
    ),
  );
}

/// An overlay holding the stamp manager.
///
/// [onLoad] is handed on to the [StampManagerWidget].
KPixOverlay getStampManagerDialog({required final Function() onDismiss, required final StampEntryDataFn onLoad})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    content: (final BuildContext context) => Center(
      child: StampManagerWidget(dismiss: onDismiss, fileLoad: onLoad,),
    ),
  );
}

/// An overlay holding [message] on top of a barrier that ignores taps.
///
/// Shown while long running work blocks the app, so it has to be taken down with
/// [KPixOverlay.hide].
KPixOverlay getLoadingDialog({required final LocalizedMessageFn message, final TextStyle? textStyle})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    content: (final BuildContext context) => Center(
      child: KPixAnimationWidget(
        constraints: const BoxConstraints(
          maxHeight: OverlayEntryAlertDialogOptions.maxHeight / 4.0,
          maxWidth: OverlayEntryAlertDialogOptions.maxWidth / 1.5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              message(AppLocalizations.of(context)!),
              style: textStyle ?? Theme.of(context).textTheme.headlineLarge,
            ),
            CircularProgressIndicator(
              color: Theme.of(context).primaryColorLight,
            ),
          ],
        ),
      ),
    ),
  );
}

/// An overlay holding a color picker for the colors of [ramps].
///
/// [title] is shown above the colors; null falls back to the localized default.
KPixOverlay getColorPickerDialog({required final Function() onDismiss, required final ColorReferenceSelectedFn onColorSelected, required final List<KPalRampData> ramps, final String? title})
{
  return _barrierOverlay(
    smokeOpacity: OverlayEntryAlertDialogOptions.smokeOpacity,
    onEscape: onDismiss,
    content: (final BuildContext context) => Center(
      child: KPixAnimationWidget(
        constraints: const BoxConstraints(
          maxHeight: OverlayEntryAlertDialogOptions.maxHeight,
          maxWidth: OverlayEntryAlertDialogOptions.maxWidth,
        ),
        child: KPixColorPickerWidget(
          dismiss: onDismiss,
          colorSelected: onColorSelected,
          ramps: ramps,
          title: title,
        ),
      ),
    ),
  );
}
