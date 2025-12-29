import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class TableViewConfig {
  static final minorBorder = BorderSide(color: Colors.gray.shade800);
  static const spanPadding = SpanPadding(leading: 8.0, trailing: 8.0);
  static const defaultLeadingForegroundDecoration =
      SpanDecoration(border: SpanBorder());
  static final defaultForegroundDecoration =
      SpanDecoration(border: SpanBorder(leading: minorBorder));
  static final defaultTrailingForegroundDecoration = SpanDecoration(
      border: SpanBorder(leading: minorBorder, trailing: minorBorder));

  static final defaultHeaderRowSpan = TableSpan(
    extent: const FixedSpanExtent(56),
    backgroundDecoration: SpanDecoration(
      color: Colors.gray.shade900,
      border: SpanBorder(
        trailing: BorderSide(color: Colors.gray.shade800),
      ),
    ),
  );
}
