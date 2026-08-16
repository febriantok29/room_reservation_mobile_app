import 'package:flutter/material.dart';

/// Layout grid sederhana berbasis Column-Row (bukan GridView).
///
/// Item di-chunk menjadi baris-baris, tiap baris adalah [Row] berisi
/// [Expanded] per kolom. Dirender dalam [ListView] sehingga tetap lazy
/// per baris dan cocok untuk infinite scroll.
class AppGridLayout extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry padding;
  final Widget? footer;

  const AppGridLayout({
    super.key,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
    this.runSpacing = 12,
    this.padding = EdgeInsets.zero,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final rowCount = (itemCount / crossAxisCount).ceil();
    final totalRows = rowCount + (footer != null ? 1 : 0);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      itemCount: totalRows,
      itemBuilder: (context, rowIndex) {
        if (footer != null && rowIndex == rowCount) {
          return footer;
        }

        final startIndex = rowIndex * crossAxisCount;
        final children = <Widget>[];

        // Render selalu crossAxisCount kolom; kolom kosong di baris terakhir
        // diisi placeholder agar item yang ada tidak melebar penuh.
        for (var i = 0; i < crossAxisCount; i++) {
          if (i > 0) children.add(SizedBox(width: spacing));

          final index = startIndex + i;
          if (index >= itemCount) {
            children.add(const Expanded(child: SizedBox.shrink()));
          } else {
            children.add(Expanded(child: itemBuilder(context, index)));
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: rowIndex == rowCount - 1 ? 0 : runSpacing,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      },
    );
  }
}
