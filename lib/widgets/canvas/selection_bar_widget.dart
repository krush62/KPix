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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/overlays/overlay_selection_align_menu.dart';

class SelectionBarWidgetOptions
{
  final double iconHeight;
  final double padding;
  final int opacityDuration;

  SelectionBarWidgetOptions({required this.iconHeight, required this.padding, required this.opacityDuration});
}

class SelectionBarWidget extends StatefulWidget
{
  const SelectionBarWidget({super.key});

  @override
  State<SelectionBarWidget> createState() => _SelectionBarWidgetState();

}

class _SelectionBarWidgetState extends State<SelectionBarWidget>
{
  final SelectionBarWidgetOptions _options = GetIt.I.get<PreferenceManager>().selectionBarWidgetOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final SelectionState _selectionState = GetIt.I.get<AppState>().selectionState;
  final AppState _appState = GetIt.I.get<AppState>();
  final BehaviorPreferenceContent _behaviorOptions = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent;
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _alignmentController = OverlayPortalController();


  @override
  void initState()
  {
    super.initState();
  }

  void _alignDismiss()
  {
    _alignmentController.hide();
  }

  void _alignCenterHPressed()
  {
    _selectionState.centerSelectionH();
  }

  void _alignCenterVPressed()
  {
    _selectionState.centerSelectionV();
  }

  void _alignLeftPressed()
  {
    _selectionState.alignSelectionLeft();
  }

  void _alignRightPressed()
  {
    _selectionState.alignSelectionRight();
  }

  void _alignTopPressed()
  {
    _selectionState.alignSelectionTop();
  }

  void _alignBottomPressed()
  {
    _selectionState.alignSelectionBottom();
  }


  void _pasteNewPressed()
  {
    _appState.addNewDrawingLayer(select: _behaviorOptions.selectLayerAfterInsert.value, content: _appState.selectionState.clipboard);
  }

  @override
  Widget build(final BuildContext context) {
    return ListenableBuilder(
      listenable: _selectionState,
      builder: (final BuildContext context, final Widget? child){
        return Material(
          color: Theme.of(context).primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Select All${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionSelectAll)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selectAll,
                    icon: Icon(
                        TablerIcons.select_all,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Deselect${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionDeselect)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                      onPressed: _selectionState.selection.isEmpty ? null : (){return _selectionState.deselect(addToHistoryStack: true);},
                      icon: Icon(
                        TablerIcons.deselect,
                        size: _options.iconHeight,
                      ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Inverse Selection${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionInvert)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                      onPressed: _selectionState.selection.isEmpty ? null : _selectionState.inverse,
                      icon: Icon(
                        TablerIcons.percentage_50,
                        size: _options.iconHeight,
                      ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Copy${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionCopy)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty ? null : _selectionState.copy,
                    icon: Icon(
                      TablerIcons.copy,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Copy Merged${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionCopyMerged)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty ? null : _selectionState.copyMerged,
                    icon: Icon(
                      TablerIcons.copy_plus,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Cut${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionCut)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty ? null : _selectionState.cut,
                    icon: Icon(
                      TablerIcons.scissors,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Paste${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionPaste)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.clipboard == null ? null : _selectionState.paste,
                    icon: Icon(
                      TablerIcons.clipboard,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Paste As New Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionPasteAsNewLayer)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.clipboard == null ? null : _pasteNewPressed,
                    icon: Icon(
                      TablerIcons.clipboard_plus,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Horizontal Flip${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionFlipH)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty ? null : _selectionState.flipH,
                    icon: Icon(
                      TablerIcons.flip_vertical,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Vertical Flip${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionFlipV)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty ? null : _selectionState.flipV,
                    icon: Icon(
                      TablerIcons.flip_horizontal,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Rotate 90° Clockwise${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionRotate)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty ? null : _selectionState.rotate,
                    icon: Icon(
                      TablerIcons.rotate_clockwise_2,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: Tooltip(
                    message: "Align...",
                    waitDuration: AppState.toolTipDuration,
                    child: OverlayPortal(
                      controller: _alignmentController,
                      overlayChildBuilder: (final BuildContext bcontext) {
                        final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
                        return Stack(
                          children: <Widget>[
                            ModalBarrier(
                              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
                              onDismiss: _alignDismiss,
                            ),
                            OverlaySelectionAlignMenu(
                              layerLink: _layerLink,
                              onDismiss: _alignDismiss,
                              onAlignCenterH: _alignCenterHPressed,
                              onAlignCenterV: _alignCenterVPressed,
                              onAlignLeft: _alignLeftPressed,
                              onAlignRight: _alignRightPressed,
                              onAlignTop: _alignTopPressed,
                              onAlignBottom: _alignBottomPressed,
                            ),
                          ],
                        );
                      },
                      child: IconButton.outlined(
                        onPressed: _selectionState.selection.isEmpty ? null : _alignmentController.show,
                        icon: Icon(
                          TablerIcons.keyframe_align_center,
                          size: _options.iconHeight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Delete${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionDelete)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty ? null : _selectionState.delete,
                    icon: Icon(
                      TablerIcons.trash,
                      size: _options.iconHeight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
