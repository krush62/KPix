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
    final LoadPaletteSet palSet = await _loadKPalFile(path: filePath, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, fileData: byteData, sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints);
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
    final LoadPaletteSet palSet = await _loadKPalFile(path: filePath, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, fileData: null, sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints);
    if (palSet.rampData != null)
    {
      paletteData.add(PaletteManagerEntryData(name: extractFilenameFromPath(path: filePath, keepExtension: false), isLocked: false, rampDataList: palSet.rampData!, path: filePath));
    }
  }
  return paletteData;
}

Future<LoadPaletteSet> _loadKPalFile({required Uint8List? fileData, required final String path, required final KPalConstraints constraints, required final KPalSliderConstraints sliderConstraints}) async
{
  fileData ??= await File(path).readAsBytes();
  final ByteData byteData = fileData.buffer.asByteData();
  int offset = 0;

  //skip options
  final int optionCount = byteData.getUint8(offset++);
  offset += optionCount * 2;

  final int rampCount = byteData.getUint8(offset++);
  if (rampCount <= 0) return LoadPaletteSet(status: "no ramp found");
  final List<KPalRampData> rampList = <KPalRampData>[];
  for (int i = 0; i < rampCount; i++)
  {
    final KPalRampSettings kPalRampSettings = KPalRampSettings(constraints: constraints);
    final int nameLength = byteData.getUint8(offset++);
    offset += nameLength;
    kPalRampSettings.colorCount = byteData.getUint8(offset++);
    if (kPalRampSettings.colorCount < constraints.colorCountMin || kPalRampSettings.colorCount > constraints.colorCountMax) return LoadPaletteSet(status: "Invalid color count in palette $i: ${kPalRampSettings.colorCount}");
    kPalRampSettings.baseHue = byteData.getInt16(offset, Endian.little);
    offset+=2;
    if (kPalRampSettings.baseHue < constraints.baseHueMin || kPalRampSettings.baseHue > constraints.baseHueMax) return LoadPaletteSet(status: "Invalid base hue value in palette $i: ${kPalRampSettings.baseHue}");
    kPalRampSettings.baseSat = byteData.getInt16(offset, Endian.little);
    offset+=2;
    if (kPalRampSettings.baseSat < constraints.baseSatMin || kPalRampSettings.baseSat > constraints.baseSatMax) return LoadPaletteSet(status: "Invalid base sat value in palette $i: ${kPalRampSettings.baseSat}");
    kPalRampSettings.hueShift = byteData.getInt8(offset++);
    if (kPalRampSettings.hueShift < constraints.hueShiftMin || kPalRampSettings.hueShift > constraints.hueShiftMax) return LoadPaletteSet(status: "Invalid hue shift value in palette $i: ${kPalRampSettings.hueShift}");
    kPalRampSettings.hueShiftExp = byteData.getFloat32(offset, Endian.little);
    offset += 4;
    if (kPalRampSettings.hueShiftExp < (constraints.hueShiftExpMin - _floatDelta) || kPalRampSettings.hueShiftExp > (constraints.hueShiftExpMax + _floatDelta)) return LoadPaletteSet(status: "Invalid hue shift exp value in palette $i: ${kPalRampSettings.hueShiftExp}");
    kPalRampSettings.hueShiftExp = kPalRampSettings.hueShiftExp.clamp(constraints.hueShiftExpMin, constraints.hueShiftExpMax);
    kPalRampSettings.satShift = byteData.getInt8(offset++);
    if (kPalRampSettings.satShift < constraints.satShiftMin || kPalRampSettings.satShift > constraints.satShiftMax) return LoadPaletteSet(status: "Invalid sat shift value in palette $i: ${kPalRampSettings.satShift}");
    kPalRampSettings.satShiftExp = byteData.getFloat32(offset, Endian.little);
    offset += 4;
    if (kPalRampSettings.satShiftExp < (constraints.satShiftExpMin - _floatDelta) || kPalRampSettings.satShiftExp > (constraints.satShiftExpMax + _floatDelta)) return LoadPaletteSet(status: "Invalid sat shift exp value in palette $i: ${kPalRampSettings.satShiftExp}");
    kPalRampSettings.satShiftExp = kPalRampSettings.satShiftExp.clamp(constraints.satShiftExpMin, constraints.satShiftExpMax);
    kPalRampSettings.valueRangeMin = byteData.getUint8(offset++);
    kPalRampSettings.valueRangeMax = byteData.getUint8(offset++);
    if (kPalRampSettings.valueRangeMin < constraints.valueRangeMin || kPalRampSettings.valueRangeMax > constraints.valueRangeMax || kPalRampSettings.valueRangeMax < kPalRampSettings.valueRangeMin) return LoadPaletteSet(status: "Invalid value range in palette $i: ${kPalRampSettings.valueRangeMin}-${kPalRampSettings.valueRangeMax}");

    final List<HistoryShiftSet> shifts = <HistoryShiftSet>[];
    for (int j = 0; j < kPalRampSettings.colorCount; j++)
    {
      final int hueShift = byteData.getInt8(offset++);
      final int satShift = byteData.getInt8(offset++);
      final int valShift = byteData.getInt8(offset++);
      if (hueShift > sliderConstraints.maxHue || hueShift < sliderConstraints.minHue) return LoadPaletteSet(status: "Invalid Hue Shift in Ramp $i, color $j: $hueShift");
      if (satShift > sliderConstraints.maxSat || satShift < sliderConstraints.minSat) return LoadPaletteSet(status: "Invalid Sat Shift in Ramp $i, color $j: $satShift");
      if (valShift > sliderConstraints.maxVal || valShift < sliderConstraints.minVal) return LoadPaletteSet(status: "Invalid Val Shift in Ramp $i, color $j: $valShift");
      final HistoryShiftSet shiftSet = HistoryShiftSet(hueShift: hueShift, satShift: satShift, valShift: valShift);
      shifts.add(shiftSet);
    }
    final int rampOptionCount = byteData.getInt8(offset++);
    for (int j = 0; j < rampOptionCount; j++)
    {
      final int optionType = byteData.getInt8(offset++);
      if (optionType == 1) //sat curve
          {
        final int satCurveVal = byteData.getInt8(offset);
        kPalRampSettings.satCurve = _kpalKpixSatCurveMap[satCurveVal]?? SatCurve.noFlat;
      }
      offset++;
    }
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: kPalRampSettings, historyShifts: shifts));
  }
  return LoadPaletteSet(status: "loading okay", rampData: rampList);

}
