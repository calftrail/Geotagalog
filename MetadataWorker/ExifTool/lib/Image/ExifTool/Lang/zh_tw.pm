#------------------------------------------------------------------------------
# File:         zh_tw.pm
#
# Description:  ExifTool Traditional Chinese language translations
#
# Notes:        This file generated automatically by Image::ExifTool::TagInfoXML
#------------------------------------------------------------------------------

package Image::ExifTool::Lang::zh_tw;

use vars qw($VERSION);

$VERSION = '1.01';

%Image::ExifTool::Lang::zh_tw::Translate = (
   'Aperture' => '光圈',
   'ApertureValue' => '光圈',
   'Artist' => '影像建立者',
   'Author' => '作者',
   'BatteryLevel' => '電池容量',
   'BitsPerSample' => '每個元件 bits 組成的數量',
   'BrightnessValue' => '亮度',
   'CFAPattern' => '彩色濾鏡陣列圖',
   'CFAPattern2' => 'CFA 模式 2',
   'CFARepeatPatternDim' => 'CFA 重複模式尺寸',
   'CellLength' => '元件長度',
   'CellWidth' => '元件寬度',
   'ColorMap' => '色彩地圖',
   'ColorResponseUnit' => '顏色反應單位',
   'ColorSpace' => {
      Description => '色彩空間',
      PrintConv => {
        'Uncalibrated' => '未校準',
      },
    },
   'Comment' => '註解',
   'ComponentsConfiguration' => '每個組成部分的意義',
   'CompressedBitsPerPixel' => '影像壓縮模式',
   'Compression' => {
      Description => '壓縮方式',
      PrintConv => {
        'Epson ERF Compressed' => 'Epson ERF 壓縮',
        'JPEG (old-style)' => 'JPEG (舊式)',
        'Kodak DCR Compressed' => 'Kodak DCR 壓縮',
        'Kodak KDC Compressed' => 'Kodak KDC 壓縮',
        'Next' => 'NeXT 2-bit 編碼',
        'Nikon NEF Compressed' => 'Nikon NEF 壓縮',
        'Pentax PEF Compressed' => 'Pentax PEF 壓縮',
        'SGILog' => 'SGI 32-bit Log Luminance 編碼',
        'SGILog24' => 'SGI 24-bit Log Luminance 編碼',
        'Sony ARW Compressed' => 'Sony ARW 壓縮',
        'Thunderscan' => 'ThunderScan 4-bit 編碼',
        'Uncompressed' => '未壓縮',
      },
    },
   'Contrast' => {
      Description => '對比',
      PrintConv => {
        'High' => '硬',
        'Low' => '軟',
        'Normal' => '標準',
      },
    },
   'Copyright' => '版權擁有人',
   'CreateDate' => '數位化的日期時間',
   'CreationDate' => '建立日期',
   'CustomRendered' => {
      Description => '自訂影像處理',
      PrintConv => {
        'Custom' => '自訂程序',
        'Normal' => '正常程序',
      },
    },
   'DateTimeOriginal' => '原始影像日期時間',
   'DeviceSettingDescription' => '裝備設定說明',
   'DigitalZoomRatio' => '數位變焦比率',
   'DocumentName' => '文件名稱',
   'ExifImageHeight' => '影像高度',
   'ExifImageWidth' => '影像寬度',
   'ExifVersion' => 'Exif 版本',
   'ExpandFilm' => '展開相片',
   'ExpandFilterLens' => '展開濾鏡',
   'ExpandFlashLamp' => '展開閃光燈',
   'ExpandLens' => '展開鏡頭',
   'ExpandScanner' => '展開掃描器',
   'ExpandSoftware' => '展開軟體',
   'ExposureCompensation' => '曝光補償',
   'ExposureIndex' => '曝光指數',
   'ExposureMode' => {
      Description => '曝光模式',
      PrintConv => {
        'Auto' => '自動曝光',
        'Auto bracket' => '自動包圍曝光',
        'Manual' => '手動曝光',
      },
    },
   'ExposureProgram' => {
      Description => '拍攝模式',
      PrintConv => {
        'Action (High speed)' => '動態模式 (高速快門)',
        'Aperture-priority AE' => '光圈優先',
        'Creative (Slow speed)' => '景深優先',
        'Landscape' => '風景模式',
        'Manual' => '手動',
        'Not Defined' => '未定義',
        'Portrait' => '肖像模式 (背景在焦距以外的特寫照片)',
        'Program AE' => '正常',
        'Shutter speed priority AE' => '快門優先',
      },
    },
   'ExposureTime' => '曝光時間',
   'ExtraSamples' => '額外的樣本',
   'FNumber' => '光圈',
   'FaxRecvParams' => '傳真接收參數',
   'FaxRecvTime' => '傳真接收時間',
   'FaxSubAddress' => '傳真附屬地址',
   'FileName' => '檔案名稱',
   'FileSize' => '檔案大小',
   'FileSource' => {
      Description => '檔案來源',
      PrintConv => {
        'Digital Camera' => '數位相機',
        'Film Scanner' => '底片掃描器',
        'Reflection Print Scanner' => '反射列印掃描器',
      },
    },
   'FileType' => '檔案格式',
   'FillOrder' => '填寫訂單',
   'Flash' => {
      Description => '閃光燈',
      PrintConv => {
        'Auto, Did not fire' => '閃光燈未擊發, 自動模式',
        'Auto, Did not fire, Red-eye reduction' => '自動, 閃光燈未擊發, 防紅眼模式',
        'Auto, Fired' => '閃光燈擊發, 自動模式',
        'Auto, Fired, Red-eye reduction' => '閃光燈擊發, 自動模式, 防紅眼模式',
        'Auto, Fired, Red-eye reduction, Return detected' => '閃光燈擊發, 自動模式, 偵測到反射光, 防紅眼模式',
        'Auto, Fired, Red-eye reduction, Return not detected' => '閃光燈擊發, 自動模式, 未偵測到反射光, 防紅眼模式',
        'Auto, Fired, Return detected' => '閃光燈擊發, 自動模式, 偵測到反射光',
        'Auto, Fired, Return not detected' => '閃光燈擊發, 自動模式, 未偵測到反射光',
        'Fired' => '閃光燈擊發',
        'Fired, Red-eye reduction' => '閃光燈擊發, 防紅眼模式',
        'Fired, Red-eye reduction, Return detected' => '閃光燈擊發, 防紅眼模式, 偵測到反射光',
        'Fired, Red-eye reduction, Return not detected' => '閃光燈擊發, 防紅眼模式, 未偵測到反射光',
        'Fired, Return detected' => '偵測到 Strobe 反射光',
        'Fired, Return not detected' => '未偵測到 Strobe 反射光',
        'No Flash' => '閃光燈未擊發',
        'No flash function' => '沒有閃光功能',
        'Off, Did not fire' => '閃光燈未擊發, 強制閃光模式',
        'Off, Did not fire, Return not detected' => '關閉, 閃光燈未擊發, 反射未偵測',
        'Off, No flash function' => '關閉, 沒有閃光功能',
        'Off, Red-eye reduction' => '關閉, 防紅眼模式',
        'On, Did not fire' => '開啟, 閃光燈未擊發',
        'On, Fired' => '閃光燈擊發, 強制閃光模式',
        'On, Red-eye reduction' => '閃光燈擊發, 強制閃光模式, 防紅眼模式',
        'On, Red-eye reduction, Return detected' => '閃光燈擊發, 強制閃光模式, 防紅眼模式, 偵測到反射光',
        'On, Red-eye reduction, Return not detected' => '閃光燈擊發, 強制閃光模式, 防紅眼模式, 未偵測到反射光',
        'On, Return detected' => '閃光燈擊發, 強制閃光模式, 偵測到反射光',
        'On, Return not detected' => '閃光燈擊發, 強制閃光模式, 未偵測到反射光',
      },
    },
   'FlashEnergy' => '閃光能量',
   'FlashpixVersion' => '支援 Flashpix 版本',
   'FocalLength' => '焦距',
   'FocalLengthIn35mmFormat' => '35mm 相機等效焦距',
   'FocalPlaneResolutionUnit' => {
      Description => '焦平面分辨率單位',
      PrintConv => {
        'None' => '無',
        'inches' => '英吋',
        'um' => 'µm (微米)',
      },
    },
   'FocalPlaneXResolution' => 'X軸焦平面分辨率',
   'FocalPlaneYResolution' => 'Y軸焦平面分辨率',
   'FocusMode' => '對焦模式',
   'GPSAltitude' => '海拔高度',
   'GPSAltitudeRef' => {
      Description => '海拔高度參考',
      PrintConv => {
        'Above Sea Level' => '海平面',
        'Below Sea Level' => '海平面參考(負值)',
      },
    },
   'GPSAreaInformation' => 'GPS區域名稱',
   'GPSDOP' => '測量精度',
   'GPSDateStamp' => 'GPS 日期',
   'GPSDestBearing' => '目的地方位',
   'GPSDestBearingRef' => {
      Description => '目的地方位依據',
      PrintConv => {
        'Magnetic North' => '磁性的方位',
        'True North' => '真實的方位',
      },
    },
   'GPSDestDistance' => '目的地距離',
   'GPSDestDistanceRef' => {
      Description => '目的地距離依據',
      PrintConv => {
        'Kilometers' => '公里',
        'Miles' => '英里',
        'Nautical Miles' => '節',
      },
    },
   'GPSDestLatitude' => '目的地緯度',
   'GPSDestLatitudeRef' => {
      Description => '目的地的緯度依據',
      PrintConv => {
        'North' => '北緯',
        'South' => '南緯',
      },
    },
   'GPSDestLongitude' => '目的地經度',
   'GPSDestLongitudeRef' => {
      Description => '目的地的經度依據',
      PrintConv => {
        'East' => '東經',
        'West' => '西經',
      },
    },
   'GPSDifferential' => {
      Description => 'GPS 定位偏差修正',
      PrintConv => {
        'Differential Corrected' => '定位偏差修正',
        'No Correction' => '無定位偏差修正',
      },
    },
   'GPSImgDirection' => '影像方位',
   'GPSImgDirectionRef' => {
      Description => '影像方位依據',
      PrintConv => {
        'Magnetic North' => '磁性的方位 ',
        'True North' => '真實的方位',
      },
    },
   'GPSLatitude' => '緯度',
   'GPSLatitudeRef' => {
      Description => '北/南緯',
      PrintConv => {
        'North' => '北緯',
        'South' => '南緯',
      },
    },
   'GPSLongitude' => '經度',
   'GPSLongitudeRef' => {
      Description => '東/西經',
      PrintConv => {
        'East' => '東經',
        'West' => '西經',
      },
    },
   'GPSMapDatum' => '使用大地測量數據',
   'GPSMeasureMode' => {
      Description => 'GPS 測量模式',
      PrintConv => {
        '2-Dimensional Measurement' => '2-三維測量',
        '3-Dimensional Measurement' => '3-三維測量',
      },
    },
   'GPSProcessingMethod' => 'GPS處理名稱',
   'GPSSatellites' => '用於測量的全球衛星定位系統衛星',
   'GPSSpeed' => 'GPS 接收機的速度',
   'GPSSpeedRef' => {
      Description => '速度單位',
      PrintConv => {
        'km/h' => '時速',
        'knots' => '節',
        'mph' => '英里',
      },
    },
   'GPSStatus' => {
      Description => 'GPS接收機的狀態',
      PrintConv => {
        'Measurement Active' => '測量有效',
        'Measurement Void' => '測量無效',
      },
    },
   'GPSTimeStamp' => 'GPS 時間 (原子鐘)',
   'GPSTrack' => '移動方位',
   'GPSTrackRef' => {
      Description => '移動方位依據',
      PrintConv => {
        'Magnetic North' => '磁性的方位 ',
        'True North' => '真實的方位',
      },
    },
   'GPSVersionID' => 'GPS 標籤版本',
   'GainControl' => {
      Description => '增益控制',
      PrintConv => {
        'High gain down' => '高衰減',
        'High gain up' => '高增益',
        'Low gain down' => '低衰減',
        'Low gain up' => '低增益',
        'None' => '無',
      },
    },
   'GrayResponseCurve' => '灰色反應曲線',
   'GrayResponseUnit' => '灰色反應單位',
   'HostComputer' => '主機',
   'IPTC-NAA' => 'IPTC-NAA 元資料',
   'ImageDescription' => '影像標題',
   'ImageHeight' => '影像高度',
   'ImageHistory' => '影像歷史',
   'ImageNumber' => '影像編號',
   'ImageSourceData' => '影像來源資料',
   'ImageUniqueID' => '獨特的影像ID',
   'ImageWidth' => '影像寬度',
   'Interlace' => '交錯',
   'InteropIndex' => '互通性鑑定',
   'InteropVersion' => '互通性版本',
   'Keyword' => '關鍵字',
   'Lens' => '鏡頭',
   'LightSource' => {
      Description => '光源',
      PrintConv => {
        'Cloudy' => '多雲',
        'Cool White Fluorescent' => '冷白色熒光燈 (W 3900 - 4500K)',
        'Day White Fluorescent' => '日光白色熒光燈 (N 4600 - 5400K)',
        'Daylight' => '日光',
        'Daylight Fluorescent' => '日光熒光燈 (D 5700 - 7100K)',
        'Fine Weather' => '晴天',
        'Flash' => '閃光燈',
        'Fluorescent' => '日光燈',
        'ISO Studio Tungsten' => 'ISO 攝影棚鎢燈',
        'Other' => '其他光源',
        'Shade' => '陰天',
        'Standard Light A' => '標準燈光 A',
        'Standard Light B' => '標準燈光 B',
        'Standard Light C' => '標準燈光 C',
        'Tungsten' => '鎢絲燈',
        'Unknown' => '未知',
        'White Fluorescent' => '白色熒光燈 (WW 3200 - 3700K)',
      },
    },
   'Location' => '地址',
   'Make' => '製造商',
   'MakerNote' => '製造商註解',
   'MaxApertureValue' => '鏡頭最大光圈',
   'MaxSampleValue' => '大樣品值',
   'MeteringMode' => {
      Description => '測光模式',
      PrintConv => {
        'Average' => '平均測光',
        'Center-weighted average' => '中央重點平均測光',
        'Multi-segment' => '評價測光',
        'Multi-spot' => '多點測光',
        'Other' => '其他',
        'Partial' => '局部測光',
        'Spot' => '點測光',
        'Unknown' => '未知',
      },
    },
   'MinSampleValue' => '小樣品值',
   'Model' => '相機型號',
   'Model2' => '第二影像輸入設備',
   'ModifyDate' => '檔案建立日期及時間',
   'Noise' => '雜訊',
   'NoiseReduction' => '雜訊抑制',
   'Opto-ElectricConvFactor' => '光電轉換因子',
   'Orientation' => {
      Description => '影像的方向',
      PrintConv => {
        'Horizontal (normal)' => '0° (頂端/左邊)',
        'Mirror horizontal' => '0° (頂端/右邊)',
        'Mirror horizontal and rotate 270 CW' => '90° CW (左邊/頂端)',
        'Mirror horizontal and rotate 90 CW' => '90° CCW (右邊/底部)',
        'Mirror vertical' => '180° (底部/左邊)',
        'Rotate 180' => '180° (底部/右邊)',
        'Rotate 270 CW' => '90° CW (左邊/底部)',
        'Rotate 90 CW' => '90° CCW (右邊/頂端)',
      },
    },
   'Padding' => '填充',
   'PageName' => '名稱',
   'PageNumber' => '頁次',
   'PhotometricInterpretation' => {
      Description => '像素格式',
      PrintConv => {
        'BlackIsZero' => '黑色為零',
        'Color Filter Array' => 'CFA (彩色濾光片矩陣)',
        'RGB Palette' => '調色板的顏色',
        'Transparency Mask' => '透明遮罩',
        'WhiteIsZero' => '白色為零',
      },
    },
   'PlanarConfiguration' => {
      Description => '影像資料編排方式',
      PrintConv => {
        'Chunky' => 'Chunky 格式 (交錯型)',
        'Planar' => 'Planar 格式 (平面型)',
      },
    },
   'Predictor' => {
      Description => '預測',
      PrintConv => {
        'Horizontal differencing' => '水平區別',
        'None' => '沒有使用過預測編碼方案',
      },
    },
   'PrimaryChromaticities' => '預選的色度',
   'ProcessingSoftware' => '處理軟體',
   'Rating' => '評分',
   'RatingPercent' => '評分的百分比',
   'ReferenceBlackWhite' => '對黑色和白色的參考價值',
   'RelatedImageFileFormat' => '相關的影像檔案格式',
   'RelatedImageHeight' => '相關的影像高度',
   'RelatedImageWidth' => '相關的影像寬度',
   'RelatedSoundFile' => '相關的音頻檔案',
   'ResolutionUnit' => {
      Description => '寬與高的單位',
      PrintConv => {
        'None' => '無',
        'cm' => '公分',
        'inches' => '英吋',
      },
    },
   'SamplesPerPixel' => '元件數量',
   'Saturation' => {
      Description => '飽和度',
      PrintConv => {
        'High' => '高飽和度',
        'Low' => '低飽和度',
        'Normal' => '標準',
      },
    },
   'SceneCaptureType' => {
      Description => '場景擷取類型',
      PrintConv => {
        'Landscape' => '風景',
        'Night' => '夜景',
        'Portrait' => '肖像',
        'Standard' => '標準',
      },
    },
   'SceneType' => {
      Description => '場景類型',
      PrintConv => {
        'Directly photographed' => '直接拍攝的影像',
      },
    },
   'SecurityClassification' => {
      Description => '安全分類',
      PrintConv => {
        'Confidential' => '秘密',
        'Restricted' => '限制',
        'Secret' => '機密',
        'Top Secret' => '最高機密',
        'Unclassified' => '未分類',
      },
    },
   'SelfTimerMode' => '倒數自拍模式',
   'SensingMethod' => {
      Description => '感測器類型',
      PrintConv => {
        'Color sequential area' => '連續彩色感測器',
        'Color sequential linear' => '連續彩色線性感測器',
        'Monochrome area' => '單色感測器',
        'Monochrome linear' => '單色線性感測器',
        'Not defined' => '未定義',
        'One-chip color area' => '單晶片彩色感測器',
        'Three-chip color area' => '三晶片彩色感測器',
        'Trilinear' => '三線性感測器',
        'Two-chip color area' => '雙晶片彩色感測器',
      },
    },
   'Sharpness' => {
      Description => '銳利度',
      PrintConv => {
        'Hard' => '硬',
        'Normal' => '標準',
        'Soft' => '軟',
      },
    },
   'ShutterSpeed' => '曝光時間',
   'ShutterSpeedValue' => '快門',
   'Software' => '軟體',
   'SpatialFrequencyResponse' => '空間頻率響應',
   'SpectralSensitivity' => '光譜靈敏度',
   'StripByteCounts' => '此資料區段的容量',
   'StripOffsets' => '影像資料位址',
   'SubSecTime' => '日期時間秒',
   'SubSecTimeDigitized' => '數位化的日期時間秒',
   'SubSecTimeOriginal' => '原始影像日期時間秒',
   'SubfileType' => '新的 subfile 類型',
   'Subject' => '主旨',
   'SubjectArea' => '主題地區',
   'SubjectDistance' => '主體距離範圍',
   'SubjectDistanceRange' => {
      Description => '主體距離範圍',
      PrintConv => {
        'Close' => '近',
        'Distant' => '遠',
        'Macro' => '微距',
        'Unknown' => '未知',
      },
    },
   'SubjectLocation' => '主題位置',
   'T4Options' => '未壓縮',
   'Title' => '標題',
   'TransferFunction' => '傳遞函數',
   'UserComment' => '使用者註解',
   'WhiteBalance' => {
      Description => '白平衡',
      PrintConv => {
        'Auto' => '自動',
        'Manual' => '手動',
      },
    },
   'WhitePoint' => '白點色度',
   'XMP' => 'XMP 元資料',
   'XPosition' => 'X 位置',
   'XResolution' => '水平解析度',
   'YCbCrCoefficients' => '顏色空間變化矩陣系數',
   'YCbCrPositioning' => {
      Description => 'Y 及 C 的設定',
      PrintConv => {
        'Centered' => '中心',
      },
    },
   'YCbCrSubSampling' => 'Y 到 C 的抽樣比率',
   'YPosition' => 'Y 位置',
   'YResolution' => '垂直解析度',
);

1;  # end


__END__

=head1 NAME

Image::ExifTool::Lang::zh_tw.pm - ExifTool Traditional Chinese language translations

=head1 DESCRIPTION

This file is used by Image::ExifTool to generate localized tag descriptions
and values.

=head1 AUTHOR

Copyright 2003-2010, Phil Harvey (phil at owl.phy.queensu.ca)

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to Jens Duttke and MikeF for providing this translation.

=head1 SEE ALSO

L<Image::ExifTool(3pm)|Image::ExifTool>,
L<Image::ExifTool::TagInfoXML(3pm)|Image::ExifTool::TagInfoXML>

=cut
