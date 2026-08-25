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

part of '../file_handler.dart';

//original kpal uses a different id mapping
const Map<int, SatCurve> _kpalKpixSatCurveMap =
<int, SatCurve>{
  1:SatCurve.noFlat,
  0:SatCurve.darkFlat,
  3:SatCurve.brightFlat,
  2: SatCurve.linear,
};

Future<List<PaletteManagerEntryData>> loadPalettesFromAssets() async
{
  final List<PaletteManagerEntryData> paletteData = <PaletteManagerEntryData>[];
  final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final List<String> imageAssetsList = assetManifest.listAssets().where((final String string) => string.startsWith("${PreferenceManager.ASSET_PATH_PALETTES}/") && string.endsWith(".$fileExtensionKpal")).toList();
  for (final String filePath in imageAssetsList)
  {
    final ByteData bytes = await rootBundle.load(filePath);
    final Uint8List byteData = bytes.buffer.asUint8List();
    final LoadPaletteSet palSet = await _loadKPalFile(path: filePath, fileData: byteData);
    if (palSet.rampData != null)
    {
      paletteData.add(PaletteManagerEntryData(name: extractFilenameFromPath(path: filePath, keepExtension: false), isLocked: true, rampDataList: palSet.rampData!, path: filePath));
    }
  }
  return paletteData;
}

Future<List<PaletteManagerEntryData>> loadPalettesFromInternal() async
{
  final List<PaletteManagerEntryData> paletteData = <PaletteManagerEntryData>[];
  final Directory dir = Directory(p.join(GetIt.I.get<AppState>().internalDir, palettesSubDirName));
  final List<String> filesWithExtension = <String>[];
  if (await dir.exists())
  {
    dir.listSync(followLinks: false).forEach((final FileSystemEntity entity)
    {
      if (entity is File && entity.path.endsWith(".$fileExtensionKpal"))
      {
        filesWithExtension.add(entity.absolute.path);
      }
    });
  }
  for (final String filePath in filesWithExtension)
  {
    final LoadPaletteSet palSet = await _loadKPalFile(path: filePath, fileData: null);
    if (palSet.rampData != null)
    {
      paletteData.add(PaletteManagerEntryData(name: extractFilenameFromPath(path: filePath, keepExtension: false), isLocked: false, rampDataList: palSet.rampData!, path: filePath));
    }
  }
  return paletteData;
}

Future<LoadPaletteSet> _loadKPalFile({required Uint8List? fileData, required final String path}) async
{
  fileData ??= await File(path).readAsBytes();
  final FileByteReader reader = FileByteReader(fileData);

  //skip options
  final int optionCount = reader.getUint8();
  reader.moveOffset(optionCount * 2);

  final int rampCount = reader.getUint8();
  if (rampCount <= 0) return LoadPaletteSet(status: "no ramp found");
  final List<KPalRampData> rampList = <KPalRampData>[];
  for (int i = 0; i < rampCount; i++)
  {
    final KPalRampSettings kPalRampSettings = KPalRampSettings();
    final int nameLength = reader.getUint8();
    reader.moveOffset(nameLength);
    kPalRampSettings.colorCount = reader.getUint8();
    if (kPalRampSettings.colorCount < KPalConstraints.colorCountMin || kPalRampSettings.colorCount > KPalConstraints.colorCountMax) return LoadPaletteSet(status: "Invalid color count in palette $i: ${kPalRampSettings.colorCount}");
    kPalRampSettings.baseHue = reader.getInt16(Endian.little);
    if (kPalRampSettings.baseHue < KPalConstraints.baseHueMin || kPalRampSettings.baseHue > KPalConstraints.baseHueMax) return LoadPaletteSet(status: "Invalid base hue value in palette $i: ${kPalRampSettings.baseHue}");
    kPalRampSettings.baseSat = reader.getInt16(Endian.little);
    if (kPalRampSettings.baseSat < KPalConstraints.baseSatMin || kPalRampSettings.baseSat > KPalConstraints.baseSatMax) return LoadPaletteSet(status: "Invalid base sat value in palette $i: ${kPalRampSettings.baseSat}");
    kPalRampSettings.hueShift = reader.getInt8();
    if (kPalRampSettings.hueShift < KPalConstraints.hueShiftMin || kPalRampSettings.hueShift > KPalConstraints.hueShiftMax) return LoadPaletteSet(status: "Invalid hue shift value in palette $i: ${kPalRampSettings.hueShift}");
    kPalRampSettings.hueShiftExp = reader.getFloat32(Endian.little);
    if (kPalRampSettings.hueShiftExp < (KPalConstraints.hueShiftExpMin - _floatDelta) || kPalRampSettings.hueShiftExp > (KPalConstraints.hueShiftExpMax + _floatDelta)) return LoadPaletteSet(status: "Invalid hue shift exp value in palette $i: ${kPalRampSettings.hueShiftExp}");
    kPalRampSettings.hueShiftExp = kPalRampSettings.hueShiftExp.clamp(KPalConstraints.hueShiftExpMin, KPalConstraints.hueShiftExpMax);
    kPalRampSettings.satShift = reader.getInt8();
    if (kPalRampSettings.satShift < KPalConstraints.satShiftMin || kPalRampSettings.satShift > KPalConstraints.satShiftMax) return LoadPaletteSet(status: "Invalid sat shift value in palette $i: ${kPalRampSettings.satShift}");
    kPalRampSettings.satShiftExp = reader.getFloat32(Endian.little);
    if (kPalRampSettings.satShiftExp < (KPalConstraints.satShiftExpMin - _floatDelta) || kPalRampSettings.satShiftExp > (KPalConstraints.satShiftExpMax + _floatDelta)) return LoadPaletteSet(status: "Invalid sat shift exp value in palette $i: ${kPalRampSettings.satShiftExp}");
    kPalRampSettings.satShiftExp = kPalRampSettings.satShiftExp.clamp(KPalConstraints.satShiftExpMin, KPalConstraints.satShiftExpMax);
    kPalRampSettings.valueRangeMin = reader.getUint8();
    kPalRampSettings.valueRangeMax = reader.getUint8();
    if (kPalRampSettings.valueRangeMin < KPalConstraints.valueRangeMin || kPalRampSettings.valueRangeMax > KPalConstraints.valueRangeMax || kPalRampSettings.valueRangeMax < kPalRampSettings.valueRangeMin) return LoadPaletteSet(status: "Invalid value range in palette $i: ${kPalRampSettings.valueRangeMin}-${kPalRampSettings.valueRangeMax}");

    final List<HistoryShiftSet> shifts = <HistoryShiftSet>[];
    for (int j = 0; j < kPalRampSettings.colorCount; j++)
    {
      final int hueShift = reader.getInt8();
      final int satShift = reader.getInt8();
      final int valShift = reader.getInt8();
      if (hueShift > KPalSliderConstraints.maxHue || hueShift < KPalSliderConstraints.minHue) return LoadPaletteSet(status: "Invalid Hue Shift in Ramp $i, color $j: $hueShift");
      if (satShift > KPalSliderConstraints.maxSat || satShift < KPalSliderConstraints.minSat) return LoadPaletteSet(status: "Invalid Sat Shift in Ramp $i, color $j: $satShift");
      if (valShift > KPalSliderConstraints.maxVal || valShift < KPalSliderConstraints.minVal) return LoadPaletteSet(status: "Invalid Val Shift in Ramp $i, color $j: $valShift");
      final HistoryShiftSet shiftSet = HistoryShiftSet(hueShift: hueShift, satShift: satShift, valShift: valShift);
      shifts.add(shiftSet);
    }
    final int rampOptionCount = reader.getInt8();
    for (int j = 0; j < rampOptionCount; j++)
    {
      final int optionType = reader.getInt8();
      if (optionType == 1) //sat curve
      {
        final int satCurveVal = reader.getInt8();
        kPalRampSettings.satCurve = _kpalKpixSatCurveMap[satCurveVal]?? SatCurve.noFlat;
      }
      else
      {
        reader.moveOffset(1);
      }
    }
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: kPalRampSettings, historyShifts: shifts));
  }
  return LoadPaletteSet(status: "loading okay", rampData: rampList);

}
