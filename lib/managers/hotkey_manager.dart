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
import 'package:kpix/util/helper.dart';

enum HotkeyAction
{
  //GENERAL
  generalNew,
  generalOpen,
  generalSave,
  generalSaveAs,
  generalExport,
  generalExit,
  generalUndo,
  generalRedo,

  //SELECTION
  selectionCopy,
  selectionCopyMerged,
  selectionCut,
  selectionPaste,
  selectionPasteAsNewLayer,
  selectionDelete,
  selectionFlipH,
  selectionFlipV,
  selectionRotate,
  selectionInvert,
  selectionSelectAll,
  selectionDeselect,
  selectionMoveUp,
  selectionMoveDown,
  selectionMoveLeft,
  selectionMoveRight,

  //SELECT TOOL
  selectToolPencil,
  selectToolShape,
  selectToolFill,
  selectToolSelectRectangle,
  selectToolSelectCircle,
  selectToolSelectWand,
  selectToolEraser,
  selectToolText,
  selectToolSprayCan,
  selectToolLine,
  selectToolStamp,
  
  //LAYERS
  layersSwitchVisibility,
  layersSwitchLock,
  layersNewDrawing,
  layersNewShading,
  layersNewGrid,
  layersNewReference,
  layersDuplicate,
  layersDelete,
  layersMerge,
  layersMoveUp,
  layersMoveDown,
  layersSelectAbove,
  layersSelectBelow,

  //SHADING
  shadingToggle,
  shadingCurrentRampOnly,
  shadingDirection,

  //PAN & ZOOM
  panZoomZoomIn,
  panZoomZoomOut,
  panZoomOptimalZoom,
  panZoomSetZoom100,
  panZoomSetZoom200,
  panZoomSetZoom400,
  panZoomSetZoom800,
  panZoomSetZoom1600,
  panZoomSetZoom3200,
  panZoomSetZoom4800,
  panZoomSetZoom6400,
  panZoomSetZoom8000,

  //TIMELINE
  timelinePlay,
  timelineNextFrame,
  timelinePreviousFrame,
  timelineMoveFrameLeft,
  timelineMoveFrameRight,

}

class HotkeyNotifier with ChangeNotifier {void actionPressed() {notifyListeners();}}

class HotkeyManager
{
  final Map<SingleActivator, HotkeyAction> _shortCutMap = <SingleActivator, HotkeyAction>{};
  final Map<HotkeyAction, HotkeyNotifier> _notifierMap = <HotkeyAction, HotkeyNotifier>{};
  final Map<HotkeyAction, VoidCallback> _actionMap = <HotkeyAction, VoidCallback>{};
  final ValueNotifier<Map<SingleActivator, VoidCallback>> _callbackMap = ValueNotifier<Map<SingleActivator, VoidCallback>>(<SingleActivator, VoidCallback>{});
  Map<SingleActivator, VoidCallback> _callbackMapBackup = <SingleActivator, VoidCallback>{};

  final FocusNode textOptionsTextFocus = FocusNode();
  final FocusNode canvasSizeWidthTextFocus = FocusNode();
  final FocusNode canvasSizeHeightTextFocus = FocusNode();
  final FocusNode canvasSizeOffsetXTextFocus = FocusNode();
  final FocusNode canvasSizeOffsetYTextFocus = FocusNode();
  final FocusNode newProjectWidthTextFocus = FocusNode();
  final FocusNode newProjectHeightTextFocus = FocusNode();
  final FocusNode exportFileNameTextFocus = FocusNode();
  final FocusNode saveAsFileNameTextFocus = FocusNode();
  final FocusNode savePaletteNameTextFocus = FocusNode();

  List<FocusNode> _focusNodes = <FocusNode>[];

  final ValueNotifier<bool> _shiftIsPressed = ValueNotifier<bool>(false);
  bool get shiftIsPressed
  {
    return _shiftIsPressed.value;
  }
  ValueNotifier<bool> get shiftNotifier
  {
    return _shiftIsPressed;
  }
  final ValueNotifier<bool> _controlIsPressed = ValueNotifier<bool>(false);
  bool get controlIsPressed
  {
    return _controlIsPressed.value;
  }
  ValueNotifier<bool> get controlNotifier
  {
    return _controlIsPressed;
  }
  final ValueNotifier<bool> _altIsPressed = ValueNotifier<bool>(false);
  bool get altIsPressed
  {
    return _altIsPressed.value;
  }
  ValueNotifier<bool> get altNotifier
  {
    return _altIsPressed;
  }

  Map<SingleActivator, VoidCallback> get callbackMap
  {
    return _callbackMap.value;
  }

  ValueNotifier<Map<SingleActivator, VoidCallback>> get callbackMapNotifier
  {
    return _callbackMap;
  }

  bool noModifierIsPressed()
  {
    return !shiftIsPressed && !altIsPressed && !controlIsPressed;
  }

  HotkeyManager()
  {
    _createShortcuts();
    _createNotifiers();
    _createCallbackMap();
    _createFocusNodeListeners();
  }

  void handleRawKeyboardEvent(final KeyEvent? evt)
  {
    if (evt != null && (evt is KeyUpEvent || evt is KeyDownEvent))
    {
      if (evt.logicalKey == LogicalKeyboardKey.shiftLeft || evt.logicalKey == LogicalKeyboardKey.shiftRight || evt.logicalKey == LogicalKeyboardKey.shift)
      {
        _shiftIsPressed.value = evt is KeyDownEvent;
      }
      else if (evt.logicalKey == LogicalKeyboardKey.controlLeft || evt.logicalKey == LogicalKeyboardKey.controlRight || evt.logicalKey == LogicalKeyboardKey.control)
      {
        _controlIsPressed.value = evt is KeyDownEvent;
      }
      else if (evt.logicalKey == LogicalKeyboardKey.altLeft || evt.logicalKey == LogicalKeyboardKey.altRight || evt.logicalKey == LogicalKeyboardKey.alt)
      {
        _altIsPressed.value = evt is KeyDownEvent;
      }

      //ARROW KEY HANDLING
      HotkeyAction? action;
      if (evt is KeyUpEvent && !_altIsPressed.value && !_controlIsPressed.value && !_shiftIsPressed.value)
      {
        if (evt.logicalKey == LogicalKeyboardKey.arrowLeft)
        {
          action = _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowLeft)];
        }
        else if (evt.logicalKey == LogicalKeyboardKey.arrowRight)
        {
          action = _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowRight)];
        }
        else if (evt.logicalKey == LogicalKeyboardKey.arrowUp)
        {
          action = _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowUp)];
        }
        else if (evt.logicalKey == LogicalKeyboardKey.arrowDown)
        {
          action = _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowDown)];
        }
        if (action != null)
        {
          triggerShortcut(action: action);
        }
      }
    }

  }


  void addListener({required final VoidCallback func, required final HotkeyAction action})
  {
    _notifierMap[action]?.addListener(func);
  }


  String getShortcutString({required final HotkeyAction action, final bool precededNewLine = true, final bool showSquareBrackets = true})
  {
    String result = "";
    if (isDesktop())
    {
      final Iterable<SingleActivator> activators = _shortCutMap.keys.where((final SingleActivator x) => _shortCutMap[x] == action);
      if (activators.isNotEmpty)
      {
        for (int i = 0; i < activators.length; i++)
        {
          if (i > 0 || precededNewLine)
          {
            result += "\n";
          }
          if (showSquareBrackets)
          {
            result += "[";
          }
          final SingleActivator activator = activators.elementAt(i);
          if (activator.shift)
          {
            result += "${LogicalKeyboardKey.shift.keyLabel} + ";
          }
          if (activator.control)
          {
            result += "${LogicalKeyboardKey.control.keyLabel} + ";
          }
          if (activator.alt)
          {
            result += "${LogicalKeyboardKey.alt.keyLabel} + ";
          }
          if (activator.trigger == LogicalKeyboardKey.space)
          {
            result += "space";
          }
          else
          {
            result += activator.trigger.keyLabel;
          }
          if (showSquareBrackets)
          {
            result += "]";
          }
        }
      }
    }
    return result;
  }

  void triggerShortcut({required final HotkeyAction action})
  {
    final Iterable<SingleActivator> foundActivators = _shortCutMap.keys.where((final SingleActivator e) => _shortCutMap[e] == action);
    for (final SingleActivator act in foundActivators)
    {
      final VoidCallback? f = _callbackMap.value[act];
      if (f != null)
      {
        f();
      }
    }
  }

  void _createShortcuts()
  {
    _shortCutMap.clear();

    //GENERAL
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyN, control: true)] = HotkeyAction.generalNew;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyO, control: true)] = HotkeyAction.generalOpen;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyS, control: true)] = HotkeyAction.generalSave;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true)] = HotkeyAction.generalSaveAs;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyE, control: true)] = HotkeyAction.generalExport;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.f4, alt: true)] = HotkeyAction.generalExit;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyQ, control: true)] = HotkeyAction.generalExit;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyZ, control: true)] = HotkeyAction.generalUndo;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyY, control: true)] = HotkeyAction.generalRedo;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true)] = HotkeyAction.generalRedo;

    //SELECTION
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyC, control: true)] = HotkeyAction.selectionCopy;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true)] = HotkeyAction.selectionCopyMerged;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyX, control: true)] = HotkeyAction.selectionCut;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyV, control: true)] = HotkeyAction.selectionPaste;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true)] = HotkeyAction.selectionPasteAsNewLayer;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.delete)] = HotkeyAction.selectionDelete;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyH, shift: true)] = HotkeyAction.selectionFlipH;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyV, shift: true)] = HotkeyAction.selectionFlipV;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyR, control: true)] = HotkeyAction.selectionRotate;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyI, control: true)] = HotkeyAction.selectionInvert;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyA, control: true)] = HotkeyAction.selectionSelectAll;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyD, control: true)] = HotkeyAction.selectionDeselect;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.escape)] = HotkeyAction.selectionDeselect;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowUp, control: true)] = HotkeyAction.selectionMoveUp;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowDown, control: true)] = HotkeyAction.selectionMoveDown;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true)] = HotkeyAction.selectionMoveLeft;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowRight, control: true)] = HotkeyAction.selectionMoveRight;

    //SELECT TOOL
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyB)] = HotkeyAction.selectToolPencil;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyU)] = HotkeyAction.selectToolShape;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyG)] = HotkeyAction.selectToolFill;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyM)] = HotkeyAction.selectToolSelectRectangle;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyC)] = HotkeyAction.selectToolSelectCircle;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyW)] = HotkeyAction.selectToolSelectWand;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyE)] = HotkeyAction.selectToolEraser;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyT)] = HotkeyAction.selectToolText;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyS)] = HotkeyAction.selectToolSprayCan;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyL)] = HotkeyAction.selectToolLine;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyP)] = HotkeyAction.selectToolStamp;
    
    //LAYERS
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyX, shift: true)] = HotkeyAction.layersSwitchVisibility;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyL, shift: true)] = HotkeyAction.layersSwitchLock;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyN, shift: true)] = HotkeyAction.layersNewDrawing;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyR, shift: true)] = HotkeyAction.layersNewReference;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyS, shift: true)] = HotkeyAction.layersNewShading;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyG, shift: true)] = HotkeyAction.layersNewGrid;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyD, shift: true)] = HotkeyAction.layersDuplicate;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.delete, shift: true)] = HotkeyAction.layersDelete;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyM, shift: true)] = HotkeyAction.layersMerge;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true)] = HotkeyAction.layersMoveUp;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true)] = HotkeyAction.layersMoveDown;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowUp)] = HotkeyAction.layersSelectAbove;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowDown)] = HotkeyAction.layersSelectBelow;

    //SHADING
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.space)] = HotkeyAction.shadingToggle;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyX)] = HotkeyAction.shadingCurrentRampOnly;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.keyD)] = HotkeyAction.shadingDirection;

    //PAN & ZOOM
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpadAdd)] = HotkeyAction.panZoomZoomIn;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpadSubtract)] = HotkeyAction.panZoomZoomOut;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad0)] = HotkeyAction.panZoomOptimalZoom;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad1)] = HotkeyAction.panZoomSetZoom100;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad2)] = HotkeyAction.panZoomSetZoom200;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad3)] = HotkeyAction.panZoomSetZoom400;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad4)] = HotkeyAction.panZoomSetZoom800;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad5)] = HotkeyAction.panZoomSetZoom1600;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad6)] = HotkeyAction.panZoomSetZoom3200;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad7)] = HotkeyAction.panZoomSetZoom4800;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad8)] = HotkeyAction.panZoomSetZoom6400;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.numpad9)] = HotkeyAction.panZoomSetZoom8000;

    //TIMELINE
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.enter)] = HotkeyAction.timelinePlay;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowRight)] = HotkeyAction.timelineNextFrame;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowLeft)] = HotkeyAction.timelinePreviousFrame;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true)] = HotkeyAction.timelineMoveFrameLeft;
    _shortCutMap[const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true)] = HotkeyAction.timelineMoveFrameRight;


  }

  void _createNotifiers()
  {
    _notifierMap.clear();
    for (final HotkeyAction action in HotkeyAction.values)
    {
      final HotkeyNotifier notifier = HotkeyNotifier();
      _notifierMap[action] = notifier;
      _actionMap[action] = notifier.actionPressed;
    }
  }

  void _createCallbackMap()
  {
    final Map<SingleActivator, VoidCallback> cbMap = <SingleActivator, VoidCallback>{};
    for (final MapEntry<SingleActivator, HotkeyAction> shortCutEntry in _shortCutMap.entries)
    {
      if (_actionMap[shortCutEntry.value] != null)
      {
        cbMap[shortCutEntry.key] = _actionMap[shortCutEntry.value]!;
      }
    }
    _callbackMap.value = cbMap;
  }

  void _createFocusNodeListeners()
  {
    _focusNodes = <FocusNode>[
      textOptionsTextFocus,
      canvasSizeWidthTextFocus,
      canvasSizeHeightTextFocus,
      canvasSizeOffsetXTextFocus,
      canvasSizeOffsetYTextFocus,
      newProjectWidthTextFocus,
      newProjectHeightTextFocus,
      exportFileNameTextFocus,
      saveAsFileNameTextFocus,
      savePaletteNameTextFocus,
    ];

    for (final FocusNode fn in _focusNodes)
    {
      fn.addListener(_checkListeners);
    }
  }

  void _checkListeners()
  {
    if (_focusNodes.where((final FocusNode node) => node.hasFocus).isNotEmpty)
    {
      _deactivateCallbacks();
    }
    else
    {
      _activateCallbacks();
    }
  }

  void _deactivateCallbacks()
  {
    _callbackMapBackup = _callbackMap.value;
    _callbackMap.value = <SingleActivator, VoidCallback>{};
  }

  void _activateCallbacks()
  {
    _callbackMap.value = _callbackMapBackup;
  }


}
