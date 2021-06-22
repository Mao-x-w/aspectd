import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

@pragma("vm:entry-point")
class HookImpl {
  static final _instance = HookImpl._();

  var _deviceInfoMap = <String, Object>{};

  HookImpl._() {
    _deviceInfoMap["os"] = Platform.operatingSystem;
    _deviceInfoMap["os_version"] = Platform.operatingSystemVersion;
  }

  factory HookImpl.getInstance() => _instance;

  HitTestEntry hitTestEntry;
  var elementInfoMap = <String, Object>{};
  bool searchStop = false;

  Element elementTypeElement;
  var elementPathList = <Element>[];

  List<String> contentList = [];

  void hookHitTest(HitTestEntry entry, PointerEvent event) {
    hitTestEntry = entry;
  }

  void hookClick(String eventName) {
    if (eventName == "onTap") {
      initValues();
      _getElementPath();
      _getElementType();
      _getElementContent();
      _printClick(elementInfoMap);
      _resetValues();
    }
  }

  void initValues() {
    elementPathList.clear();
    searchStop = false;
    elementInfoMap.clear();
  }

  void _resetValues() {
    initValues();
    contentList.clear();
    elementTypeElement = null;
  }

  void _getElementContent() {
    RenderObject renderObject = hitTestEntry.target;
    DebugCreator debugCreator = renderObject.debugCreator;
    Element element = debugCreator.element;

    Element finalContainerElement;
    element.visitAncestorElements((element) {
      String finalResult;
      dynamic widget = element.widget;
      finalResult = widget.runtimeType.toString();
      if (finalResult != null) {
        finalContainerElement = element;
        return false;
      }
      return true;
    });

    if (finalContainerElement == null &&
        (element.widget is Text || element.widget is RichText)) {
      finalContainerElement = element;
    }

    if (finalContainerElement != null) {
      _getElementContentByType(finalContainerElement);
      if (contentList.isNotEmpty) {
        String result = contentList.join("-");
        elementInfoMap[r"$element_content"] = result;
      }
    }
  }

  void _getElementContentByType(Element element) {
    if (element != null) {
      String tmp = getTextFromWidget(element.widget);
      if (tmp != null) {
        contentList.add(tmp);
        return;
      }

      element.visitChildElements(_getElementContentByType);
    }
  }

  String getTextFromWidget(Widget widget) {
    String result;
    if (widget is Text) {
      result = widget.data;
    } else if (widget is Tab) {
      result = widget.text;
    } else if (widget is IconButton) {
      result = widget.tooltip ?? "";
    }
    return result;
  }

  bool _shouldAddToPath(Element element) {
    Widget widget = element.widget;
    if (widget is _CustomHasCreationLocation) {
      _CustomHasCreationLocation creationLocation =
          widget as _CustomHasCreationLocation;
      if (creationLocation._customLocation != null) {
        return creationLocation._customLocation.isProjectRoot();
      }
    }
    return false;
  }

  void _getElementPath() {
    var listResult = <String>[];
    RenderObject renderObject = hitTestEntry.target;
    DebugCreator debugCreator = renderObject.debugCreator;
    Element element = debugCreator.element;
    if (_shouldAddToPath(element)) {
      var result = "${element.widget.runtimeType.toString()}";
      int slot = 0;
      if (element.slot != null) {
        if (element.slot is IndexedSlot) {
          slot = (element.slot as IndexedSlot).index;
        }
      }
      result += "[$slot]";
      listResult.add(result);
      elementPathList.add(element);
    }

    element.visitAncestorElements((element) {
      if (_shouldAddToPath(element)) {
        var result = "${element.widget.runtimeType.toString()}";
        int slot = 0;
        if (element.slot != null) {
          if (element.slot is IndexedSlot) {
            slot = (element.slot as IndexedSlot).index;
          }
        }
        result += "[$slot]";
        listResult.add(result);
        elementPathList.add(element);
      }
      return true;
    });
    String finalResult = "";
    listResult.reversed.forEach((element) {
      finalResult += "/$element";
    });

    if (finalResult.startsWith('/')) {
      finalResult = finalResult.replaceFirst('/', '');
    }
    elementInfoMap[r"$element_path"] = finalResult;
  }

  void _getElementType() {
    if (elementPathList.isEmpty) {
      return;
    }
    String elementTypeResult;

    for (Element element in elementPathList) {
      Widget widget = element.widget;
      elementTypeResult = widget.runtimeType.toString();
      if (elementTypeResult != null) {
        elementTypeElement = element;
        break;
      }
    }
    if (elementTypeResult == null) {
      elementTypeResult = elementPathList[0].widget.runtimeType.toString();
      elementTypeElement = elementPathList[0];
    }

    elementInfoMap[r"$element_type"] = elementTypeResult;
  }

  void _printClick(Map<String, Object> otherData) {
    String result = "";
    result +=
        "\n==========================================Clicked========================================\n";
    _deviceInfoMap.forEach((key, value) {
      result += "$key: $value\n";
    });
    otherData?.forEach((key, value) {
      result += "$key: $value\n";
    });
    result += "time: ${DateTime.now().toString()}\n";
    result +=
        "=========================================================================================";
    CustomLog.i(result);
  }
}

///Location Part
@pragma("vm:entry-point")
abstract class _CustomHasCreationLocation {
  _CustomLocation get _customLocation;
}

@pragma("vm:entry-point")
class _CustomLocation {
  const _CustomLocation({
    this.file,
    this.rootUrl,
    this.line,
    this.column,
    this.name,
    this.parameterLocations,
  });

  final String rootUrl;
  final String file;
  final int line;
  final int column;
  final String name;
  final List<_CustomLocation> parameterLocations;

  bool isProjectRoot() {
    if (rootUrl == null || file == null) {
      return false;
    }
    return file.startsWith(rootUrl);
  }

  @override
  String toString() {
    return '_CustomLocation{rootUrl: $rootUrl, file: $file, line: $line, column: $column, name: $name}';
  }
}

class CustomLog {
  static void d(String str) {
    print("CustomLog:::::ddddd:::::$str");
  }

  static void i(String str) {
    print("CustomLog:::::iiiii:::::$str");
  }

  static void w(String str) {
    print("CustomLog:::::wwwww:::::$str");
  }
}