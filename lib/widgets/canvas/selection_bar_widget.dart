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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/widgets/overlays/overlay_anchor.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/overlays/overlay_selection_align_menu.dart';

/// Layout options for the [SelectionBarWidget].
abstract final class _SelectionBarWidgetOptions
{
  static const double iconHeight = 20.0;
  static const double padding = 4.0;
}

/// Widget for all selection related operations (copy, paste, transform, ...).
class SelectionBarWidget extends StatefulWidget
{
  const SelectionBarWidget({super.key});

  @override
  State<SelectionBarWidget> createState() => _SelectionBarWidgetState();

}

class _SelectionBarWidgetState extends State<SelectionBarWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final SelectionState _selectionState = GetIt.I.get<DocumentState>().selectionState;
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final BehaviorPreferenceContent _behaviorOptions = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent;
  final GlobalKey _alignAnchorKey = GlobalKey();
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
    GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: _behaviorOptions.selectLayerAfterInsert.value, content: _documentState.selectionState.clipboard);
  }

  Padding _createBarButton({required final String tooltip, required final IconData icon, required final void Function() onPressedFunc, final bool isEnabled = true})
  {
    return Padding(
      padding: const EdgeInsets.all(_SelectionBarWidgetOptions.padding),
      child: Tooltip(
        message: tooltip,
        waitDuration: AppState.toolTipDuration,
        child: IconButton.outlined(
          onPressed: isEnabled ? onPressedFunc : null,
          icon: Icon(icon, size: _SelectionBarWidgetOptions.iconHeight),
        ),
      ),
    );
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
              _createBarButton(
                  tooltip: "Select All${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionSelectAll)}",
                  icon: TablerIcons.select_all,
                  onPressedFunc: _selectionState.selectAll,
              ),
              _createBarButton(
                tooltip: "Deselect${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionDeselect)}",
                icon: TablerIcons.deselect,
                onPressedFunc: _selectionState.deselectWithHistory,
                isEnabled: !_selectionState.selection.isEmpty,
              ),
              _createBarButton(
                tooltip: "Inverse Selection${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionInvert)}",
                icon: TablerIcons.percentage_50,
                onPressedFunc: _selectionState.inverse,
                isEnabled: !_selectionState.selection.isEmpty,
              ),
              _createBarButton(
                tooltip: "Copy${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionCopy)}",
                icon: TablerIcons.copy,
                onPressedFunc: _selectionState.copy,
                isEnabled: !_selectionState.selection.isEmpty,
              ),
              _createBarButton(
                tooltip: "Copy Merged${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionCopyMerged)}",
                icon: TablerIcons.copy_plus,
                onPressedFunc: _selectionState.copyMerged,
                isEnabled: !_selectionState.selection.isEmpty,
              ),
              _createBarButton(
                tooltip: "Cut${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionCut)}",
                icon: TablerIcons.scissors,
                onPressedFunc: _selectionState.cut,
                isEnabled: !_selectionState.selection.isEmpty,
              ),
              _createBarButton(
                tooltip: "Paste${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionPaste)}",
                icon: TablerIcons.clipboard,
                onPressedFunc: _selectionState.paste,
                isEnabled: _selectionState.clipboard != null,
              ),
              _createBarButton(
                tooltip: "Paste As New Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionPasteAsNewLayer)}",
                icon: TablerIcons.clipboard_plus,
                onPressedFunc: _pasteNewPressed,
                isEnabled: _selectionState.clipboard != null,
              ),
              _createBarButton(
                tooltip: "Horizontal Flip${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionFlipH)}",
                icon: TablerIcons.flip_vertical,
                onPressedFunc: _selectionState.flipH,
                isEnabled: !_selectionState.selection.isEmpty,
              ),
              _createBarButton(
                tooltip: "Vertical Flip${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionFlipV)}",
                icon: TablerIcons.flip_horizontal,
                onPressedFunc: _selectionState.flipV,
                isEnabled: !_selectionState.selection.isEmpty,
              ),
              _createBarButton(
                tooltip: "Rotate 90° Clockwise${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionRotate)}",
                icon: TablerIcons.rotate_clockwise_2,
                onPressedFunc: _selectionState.rotate,
                isEnabled: !_selectionState.selection.isEmpty,
              ),
              Padding(
                padding: const EdgeInsets.all(_SelectionBarWidgetOptions.padding),
                child: OverlayAnchor(
                  anchorKey: _alignAnchorKey,
                  child: Tooltip(
                    message: "Align...",
                    waitDuration: AppState.toolTipDuration,
                    child: OverlayPortal(
                      controller: _alignmentController,
                      overlayChildBuilder: (final BuildContext bcontext) {
                        return Stack(
                          children: <Widget>[
                            ModalBarrier(
                              color: Theme.of(context).primaryColorDark.withAlpha(OverlayEntrySubMenuOptions.smokeOpacity),
                              onDismiss: _alignDismiss,
                            ),
                            OverlaySelectionAlignMenu(
                              anchorKey: _alignAnchorKey,
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
                        icon: const Icon(
                          TablerIcons.keyframe_align_center,
                          size: _SelectionBarWidgetOptions.iconHeight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(_SelectionBarWidgetOptions.padding),
                child: Tooltip(
                  message: "Delete${_hotkeyManager.getShortcutString(action: HotkeyAction.selectionDelete)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty ? null : _selectionState.delete,
                    icon: const Icon(
                      TablerIcons.trash,
                      size: _SelectionBarWidgetOptions.iconHeight,
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
