/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

part of '../../export_functions.dart';

Future<Uint8List?> getPsdData({required final List<KPalRampData> colorRamps, required final LayerCollection layerCollection, required final CoordinateSetI canvasSize, required final SelectionList selection}) async
{
  return buildPsdBytes(layers: layers, opts: opts);
}





Uint8List buildPsdBytes({
  required LayerCollection layers,
  required PsdExportOptions opts,
}) {
  final w = opts.width, h = opts.height;

  // ---- 1) File Header (26 bytes) ----  [1](https://docs.fileformat.com/image/psd/)
  final header = _BytesBE();
  header.ascii('8BPS');    // signature
  header.u16(1);           // version = 1 (PSD)
  header.u32(0); header.u16(0); // 6 reserved bytes (zeros)
  header.u16(3);           // number of channels in merged image (RGB)  [1](https://docs.fileformat.com/image/psd/)
  header.u32(h);           // height
  header.u32(w);           // width
  header.u16(8);           // depth
  header.u16(3);           // color mode = RGB  [1](https://docs.fileformat.com/image/psd/)
  final headerBytes = header.toBytes();

  // ---- 2) Color Mode Data (RGB → length 0) ----  [1](https://docs.fileformat.com/image/psd/)
  final colorModeData = _BytesBE()..u32(0);

  // ---- 3) Image Resources (palette metadata) ----  [2](https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/)[3](https://docs.fileformat.com/image/psd/)
  final imgRes = _buildImageResources(
    indexedCount: opts.palette.length,
    transparencyIndex: opts.transparentPaletteIndex,
  );

  // ---- 4) Layer & Mask Information ----
  final layerInfo = _BytesBE();

  // a) Layer Info subsection
  final layerRecords = _BytesBE();
  final channelDatas = <Uint8List>[];

  // Important: write layers bottom→top (UI order). If your array is top→bottom, reverse it.  [5](https://github.com/webtoon/psd/blob/main/packages/psd/src/sections/LayerAndMaskInformation/readLayerRecordsAndChannels.ts)
  final orderedLayers = layers; // adjust if needed

  // Layer count (positive)
  final layerCount = orderedLayers.length;

  // Build all layer records first (we need their bytes to compute lengths)
  final perLayer = orderedLayers.map((li) =>
      _buildLayerRecordAndChannels(layer: li, width: w, height: h)).toList();

  // Layer Info block: 4-byte length + 2-byte count + records + per-layer channel image data
  final layerInfoContent = BytesBE();
  layerInfoContent.u16(layerCount);
  for (final L in perLayer) {
    layerInfoContent.raw(L.record);
  }
  for (final L in perLayer) {
    // Per spec: channel image data follows, in the same order.  [4](https://github.com/iamgqb/psd-spec-translate/blob/master/The%20Photoshop%20File%20Format/6.Layer%20and%20Mask%20Information%20Section.md)
    for (final ch in L.channelDatas) {
      layerInfoContent.raw(ch);
    }
  }
  // Wrap Layer Info with its length (rounded up to even)
  final licBytes = layerInfoContent.toBytes();
  final licPadded = _BytesBE()..raw(licBytes)..padEven();
  layerRecords.u32(licPadded.length); // 4-byte length (PSB would be 8)  [4](https://github.com/iamgqb/psd-spec-translate/blob/master/The%20Photoshop%20File%20Format/6.Layer%20and%20Mask%20Information%20Section.md)
  layerRecords.raw(licPadded.toBytes());

  // b) Global Layer Mask Info (empty)
  layerRecords.u32(0);

  // c) Additional Layer Information (document-level tagged blocks; none for minimal)
  // (omit)

  // Wrap Layer & Mask Information with its 4-byte section length
  final layerInfoPayload = layerRecords.toBytes();
  final layerAndMask = _BytesBE()..u32(layerInfoPayload.length)..raw(layerInfoPayload);

  // ---- 5) Image Data (merged composite, planar RGB, RAW=0) ----  [1](https://docs.fileformat.com/image/psd/)
  final comp = _buildComposite(w, h, orderedLayers);
  final imageData = _BytesBE();
  imageData.u16(0);              // compression (0=RAW)
  imageData.raw(comp.r);
  imageData.raw(comp.g);
  imageData.raw(comp.b);

  // ---- Concatenate all sections ----
  final out = _BytesBE();
  out.raw(headerBytes);
  out.raw(colorModeData.toBytes());
  out.raw(imgRes);                // already includes 4-byte length
  out.raw(layerAndMask.toBytes()); // includes 4-byte length
  out.raw(imageData.toBytes());

  return out.toBytes();
}






_Planes buildComposite({required final CoordinateSetI size, required final LayerCollection layers, required final SelectionList selection}) {
  final Uint8List r = Uint8List(size.x * size.y);
  final Uint8List g = Uint8List(size.x * size.y);
  final Uint8List b = Uint8List(size.x * size.y);
  // composite has no alpha channel in header; we still compute A for convenience
  final Uint8List a = Uint8List(size.x * size.y);

  // Traverse from top to bottom (last layer is topmost in UI)
  for (int y = 0; y < size.y; y++)
  {
    for (int x = 0; x < size.x; x++)
    {
      final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
      final int idx = y * size.x + x;
      // find first visible layer with a pixel at (x,y)
      for (int li = 0; li < layers.length; li--)
      {
        final LayerState l = layers.getLayer(index: li);
        if (l is DrawingLayerState && l.visibilityState.value == LayerVisibilityState.visible)
        {

          ColorReference? colAtPos;
          if (li == layers.selectedLayerIndex)
          {
            colAtPos = selection.getColorReference(coord: curCoord);
          }
          colAtPos ??= l.getDataEntry(coord: curCoord, withSettingsPixels: true);

          if (colAtPos != null)
          {
            final int shade = _getShadeForCoord(layerCollection: layers, currentLayerIndex: li, coord: curCoord);
            if (shade != 0)
            {
              final int targetIndex = (colAtPos.colorIndex + shade).clamp(0, colAtPos.ramp.references.length - 1);
              colAtPos = colAtPos.ramp.references[targetIndex];
            }
            final Color c = colAtPos.getIdColor().color;
            r[idx] = (c.r * 255.0).round() & 0xff;
            g[idx] = (c.g * 255.0).round() & 0xff;
            b[idx] = (c.b * 255.0).round() & 0xff;
            a[idx] = 0xFF;
            break;
          }
        }
      }
    }
  }
  return _Planes(r, g, b, a);
}



class LayerBinary {
  final Uint8List record;
  final List<Uint8List> channelDatas;
  LayerBinary(this.record, this.channelDatas);
}

LayerBinary _buildLayerRecordAndChannels({
  required final DrawingLayerState layer,
  required final LayerCollection layerCollection,
  required final CoordinateSetI size,
  required final SelectionList selection,
}) {
  // Rasterize planes
  final _Planes planes = _rasterizeLayer(size: size, layerCollection: layerCollection, layerState: layer, selection: selection);

  // Encode channels (RAW): order R(0), G(1), B(2), Transparency(-1)
  final Uint8List chR = _encodeChannelRaw(plane: planes.r);
  final Uint8List chG = _encodeChannelRaw(plane: planes.g);
  final Uint8List chB = _encodeChannelRaw(plane: planes.b);
  final Uint8List chA = _encodeChannelRaw(plane: planes.a);
  final List<Uint8List> channelDatas = <Uint8List>[chR, chG, chB, chA];

  // Layer record
  final _BytesBE lb = _BytesBE();

  // Bounds: full canvas for your case (all layers same size)
  lb.i32(0);            // top
  lb.i32(0);            // left
  lb.i32(size.y);       // bottom
  lb.i32(size.x);        // right

  // Channel count
  lb.u16(4);

  // Channel info entries: (id, length-of-channel-data)
  // Length is compressed length INCLUDING 2-byte compression field.  [5](https://github.com/webtoon/psd/blob/main/packages/psd/src/sections/LayerAndMaskInformation/readLayerRecordsAndChannels.ts)
  void chanInfo(final int id, final Uint8List data) {
    lb.i16(id);
    lb.u32(data.length);
  }
  chanInfo(0, chR);     // red
  chanInfo(1, chG);     // green
  chanInfo(2, chB);     // blue
  chanInfo(-1, chA);    // transparency

  // Blend mode signature & key
  lb.ascii('8BIM');     // signature
  lb.ascii('norm');     // key = normal  [4](https://github.com/iamgqb/psd-spec-translate/blob/master/The%20Photoshop%20File%20Format/6.Layer%20and%20Mask%20Information%20Section.md)

  // Opacity
  lb.u8(255);

  // Clipping: 0 = base
  lb.u8(0);

  // Flags: bit0 protect transparency, bit1 hidden
  int flags = 0;
  if (layer.lockState.value == LayerLockState.transparency) flags |= 0x01;
  if (layer.visibilityState.value == LayerVisibilityState.hidden) flags |= 0x02; // (hidden bit)
  lb.u8(flags);

  // Filler
  lb.u8(0);

  // ---- Extra data ----
  final _BytesBE extra = _BytesBE();

  // Layer mask data (empty)
  extra.u32(0);

  // Blending ranges (empty): write length=0
  extra.u32(0);

  // Layer name (Pascal, padded to 4)
  final String layerName = "LAYER_ ${layerCollection.getLayerPosition(state: layer)!}";
  final Uint8List nameBytes = Uint8List.fromList(layerName.codeUnits);
  final int nameLen = nameBytes.length > 255 ? 255 : nameBytes.length;
  extra.u8(nameLen);
  extra.raw(nameBytes.sublist(0, nameLen));
  extra.pad4(); // name block padded to 4 bytes  [5](https://github.com/webtoon/psd/blob/main/packages/psd/src/sections/LayerAndMaskInformation/readLayerRecordsAndChannels.ts)

  // (Optional) Additional Layer Information blocks could go here.

  // Write extra length
  lb.u32(extra.length);
  lb.raw(extra.toBytes());

  return LayerBinary(lb.toBytes(), channelDatas);
}


Uint8List _buildImageResources({
  required final int indexedCount,
  final int? transparencyIndex,
}) {
  final _BytesBE resources = _BytesBE();

  // Helper: one resource block
  Uint8List resBlock(final int id, final Uint8List namePascal, final Uint8List data) {
    final _BytesBE bb = _BytesBE();
    bb.ascii('8BIM');       // signature  [3](https://docs.fileformat.com/image/psd/)
    bb.u16(id);
    bb.raw(namePascal);
    // pad name to even
    final Uint8List tmpName = bb.toBytes();
    final _BytesBE namePadded = _BytesBE()..raw(tmpName)..padEven();

    final _BytesBE out = _BytesBE();
    out.raw(namePadded.toBytes());
    final _BytesBE size = _BytesBE()..u32(data.length);
    out.raw(size.toBytes());
    out.raw(data);
    // pad data to even
    final Uint8List tmpData = out.toBytes();
    final _BytesBE dataPadded = _BytesBE()..raw(tmpData)..padEven();
    return dataPadded.toBytes();
  }

  // Empty Pascal name (length=0 → 1 byte 0, then pad to even)
  final Uint8List emptyPascal = Uint8List.fromList(<int>[0]);

  // 1046: Indexed Color Table Count (2 bytes)
  final ByteData count2 = ByteData(2)..setUint16(0, indexedCount);
  resources.raw(resBlock(1046, emptyPascal, count2.buffer.asUint8List()));

  // 1047: Transparency Index (optional, 2 bytes)
  if (transparencyIndex != null) {
    final ByteData ti2 = ByteData(2)..setUint16(0, transparencyIndex);
    resources.raw(resBlock(1047, emptyPascal, ti2.buffer.asUint8List()));
  }

  // Wrap with 4-byte section length
  final Uint8List payload = resources.toBytes();
  final _BytesBE out = _BytesBE()..u32(payload.length)..raw(payload);
  return out.toBytes();
}




Uint8List _encodeChannelRaw({required final Uint8List plane}) {
  final _BytesBE bb = _BytesBE();
  bb.u16(0);            // compression = 0 (RAW)
  bb.raw(plane);        // raw scanlines
  return bb.toBytes();
}


class _Planes {
  final Uint8List r;
  final Uint8List g;
  final Uint8List b;
  final Uint8List a;
  _Planes(this.r, this.g, this.b, this.a);
}

_Planes _rasterizeLayer({required final CoordinateSetI size, required final LayerCollection layerCollection, required final DrawingLayerState layerState, required final SelectionList selection})
{
  final Uint8List r = Uint8List(size.x * size.y);
  final Uint8List g = Uint8List(size.x * size.y);
  final Uint8List b = Uint8List(size.x * size.y);
  final Uint8List a = Uint8List(size.x * size.y); // 0 transparent, 255 opaque

  for (int y = 0; y < size.y; y++)
  {
    for (int x = 0; x < size.x; x++)
    {
      final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
      ColorReference? colAtPos;
      if (layerCollection.getSelectedLayer() == layerState)
      {
        colAtPos = selection.getColorReference(coord: curCoord);
      }



      colAtPos ??= layerState.getDataEntry(coord: curCoord, withSettingsPixels: true);

      if (colAtPos != null)
      {
        final int shade = _getShadeForCoord(layerCollection: layerCollection, currentLayerIndex: layerCollection.getLayerPosition(state: layerState)!, coord: curCoord);
        if (shade != 0)
        {
          final int targetIndex = (colAtPos.colorIndex + shade).clamp(0, colAtPos.ramp.references.length - 1);
          colAtPos = colAtPos.ramp.references[targetIndex];
        }
        final Color c = colAtPos.getIdColor().color;
        final int idx = y * size.x + x;
        r[idx] = (c.r * 255.0).round() & 0xff;
        g[idx] = (c.g * 255.0).round() & 0xff;
        b[idx] = (c.b * 255.0).round() & 0xff;
        a[idx] = 0xFF;


      }
    }
  }
  return _Planes(r, g, b, a);
}


class _BytesBE {
  final BytesBuilder _bb = BytesBuilder();

  void u8(final int v) => _bb.add(<int>[v & 0xFF]);
  void i16(final int v) {
    final ByteData bd = ByteData(2)..setInt16(0, v);
    _bb.add(bd.buffer.asUint8List());
  }
  void u16(final int v) {
    final ByteData bd = ByteData(2)..setUint16(0, v);
    _bb.add(bd.buffer.asUint8List());
  }
  void i32(final int v) {
    final ByteData bd = ByteData(4)..setInt32(0, v);
    _bb.add(bd.buffer.asUint8List());
  }
  void u32(final int v) {
    final ByteData bd = ByteData(4)..setUint32(0, v);
    _bb.add(bd.buffer.asUint8List());
  }
  void ascii(final String s) => _bb.add(Uint8List.fromList(s.codeUnits));
  void raw(final Uint8List data) => _bb.add(data);

  // pad to even length by adding 1 zero byte if needed
  void padEven() {
    final Uint8List bytes = _bb.toBytes();
    if (bytes.length.isOdd) _bb.add(<int>[0]);
  }

  // pad to 4-byte boundary (used for layer name block)
  void pad4() {
    final int len = _bb.length;
    final int rem = len % 4;
    if (rem != 0) _bb.add(Uint8List(rem == 0 ? 0 : 4 - rem));
  }

  Uint8List toBytes() => _bb.toBytes();
  int get length => _bb.length;
}
