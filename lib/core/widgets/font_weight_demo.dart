import 'package:flutter/material.dart';
import 'package:zhi_ming/core/theme/z_text_styles.dart';

class FontWeightDemo extends StatelessWidget {
  const FontWeightDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Font Noto Sans SC')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Header', [
              _buildTextExample(
                'H1 demilight',
                '32/48',
                32,
                AppFontWeight.demiLight,
              ),
              _buildTextExample('H2 medium', '24/30', 24, AppFontWeight.medium),
              _buildTextExample(
                'H3 demilight',
                '22/28',
                22,
                AppFontWeight.demiLight,
              ),
              _buildTextExample(
                'H4 demilight',
                '20/24',
                20,
                AppFontWeight.demiLight,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Body', [
              _buildTextExample(
                'L regular',
                '20/30',
                20,
                AppFontWeight.regular,
              ),
              _buildTextExample(
                'M regular',
                '18/28',
                18,
                AppFontWeight.regular,
              ),
              _buildTextExample('M medium', '16/24', 16, AppFontWeight.medium),
              _buildTextExample(
                'M demilight',
                '16/24',
                16,
                AppFontWeight.demiLight,
              ),
              _buildTextExample(
                'S demilight',
                '14/22',
                14,
                AppFontWeight.demiLight,
              ),
              _buildTextExample(
                'XS demilight',
                '12/16',
                12,
                AppFontWeight.demiLight,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('All Weights', [
              _buildTextExample('Thin 100', '', 16, AppFontWeight.thin),
              _buildTextExample(
                'Extra Light 200',
                '',
                16,
                AppFontWeight.extraLight,
              ),
              _buildTextExample('Light 300', '', 16, AppFontWeight.light),
              _buildTextExample(
                'DemiLight 350',
                '',
                16,
                AppFontWeight.demiLight,
              ),
              _buildTextExample('Regular 400', '', 16, AppFontWeight.regular),
              _buildTextExample('Medium 500', '', 16, AppFontWeight.medium),
              _buildTextExample(
                'Semi Bold 600',
                '',
                16,
                AppFontWeight.semiBold,
              ),
              _buildTextExample('Bold 700', '', 16, AppFontWeight.bold),
              _buildTextExample(
                'Extra Bold 800',
                '',
                16,
                AppFontWeight.extraBold,
              ),
              _buildTextExample('Black 900', '', 16, AppFontWeight.black),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextExample(
    String text,
    String size,
    double fontSize,
    FontWeight fontWeight,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              text,
              style: ZTextStyle.font(
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
          if (size.isNotEmpty)
            Expanded(
              child: Text(
                size,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
