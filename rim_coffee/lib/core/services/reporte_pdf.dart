import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rim_coffee/core/services/reportes_service.dart';
import 'package:rim_coffee/core/utils/formato.dart';

/// Reporte de ventas en PDF (hoy, semana o mes) con sus gráficas, listo
/// para guardar, imprimir o mandar por WhatsApp o correo.
class ReportePdf {
  ReportePdf._();

  static const PdfColor _espresso = PdfColor.fromInt(0xFF24160F);
  static const PdfColor _cafe = PdfColor.fromInt(0xFF6B4632);
  static const PdfColor _caramelo = PdfColor.fromInt(0xFFC4864F);
  static const PdfColor _crema = PdfColor.fromInt(0xFFF3EADF);
  static const PdfColor _linea = PdfColor.fromInt(0xFFEADFD3);
  static const PdfColor _gris = PdfColor.fromInt(0xFF8C786A);

  static Future<pw.Font> _fuente(String archivo) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$archivo'));

  /// Arma el PDF del reporte.
  static Future<Uint8List> generar(ResumenReporte r, {required String negocio}) async {
    final regular = await _fuente('Poppins-Regular.ttf');
    final negrita = await _fuente('Poppins-SemiBold.ttf');
    final serif = await _fuente('DMSerifDisplay-Regular.ttf');
    final ahora = DateTime.now();

    final doc = pw.Document(
      title: 'Reporte de ${r.periodo} · $negocio',
      author: negocio,
      creator: 'Rim Coffee',
      theme: pw.ThemeData.withFont(base: regular, bold: negrita),
    );

    pw.Widget titulo(String texto) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
          child: pw.Text(texto, style: pw.TextStyle(font: serif, fontSize: 17, color: _espresso)),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Rim Coffee · página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _gris),
          ),
        ),
        build: (ctx) => [
          // Encabezado
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: const pw.BoxDecoration(
              color: _espresso,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        negocio,
                        style: pw.TextStyle(font: serif, fontSize: 24, color: PdfColors.white),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Reporte de ventas · ${r.periodo}',
                        style: const pw.TextStyle(fontSize: 12, color: _crema),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  'Generado: ${fechaCorta(ahora)} ${horaDe(ahora)}',
                  style: const pw.TextStyle(fontSize: 9, color: _crema),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          // Indicadores
          pw.Row(
            children: [
              _kpi('Ventas', money(r.total)),
              pw.SizedBox(width: 8),
              _kpi('Cuentas pagadas', '${r.cuentas}'),
              pw.SizedBox(width: 8),
              _kpi('Ticket promedio', money(r.ticketPromedio)),
              pw.SizedBox(width: 8),
              _kpi('No cobradas', '${r.noCobradas} · ${money(r.noCobradasTotal)}'),
            ],
          ),
          titulo('Ventas del periodo'),
          _graficaBarras(r.etiquetas, r.valores),
          titulo('Productos más vendidos'),
          if (r.top.isEmpty)
            pw.Text('Sin ventas en este periodo.', style: const pw.TextStyle(color: _gris))
          else
            _barrasHorizontales(
              [for (final p in r.top) p.nombre],
              [for (final p in r.top) p.unidades.toDouble()],
              (v) => '${v.toInt()} pzas',
            ),
          titulo('Datos destacados'),
          _tabla(
            const ['Dato', 'Valor'],
            [
              if (r.mejorDia != null)
                ['Mejor día', '${fechaConDia(r.mejorDia!)} · ${money(r.mejorDiaTotal)}'],
              if (r.diaFuerte != null) ['Día que más vende', r.diaFuerte!],
              if (r.horaPico != null) ['Hora pico', '${r.horaPico}:00 h'],
              for (final m in r.mesasTop) ['Mesa ${m.key}', '${m.value} cuentas'],
            ],
          ),
          titulo('Personal'),
          _tabla(
            const ['Persona', 'Mesas atendidas', 'Cuentas cobradas', 'Ventas cobradas'],
            [
              for (final nombre in {
                ...r.atendieron.map((p) => p.nombre),
                ...r.vendieron.map((p) => p.nombre),
              })
                [
                  nombre,
                  '${_buscar(r.atendieron, nombre)?.cuentas ?? 0}',
                  '${_buscar(r.vendieron, nombre)?.cuentas ?? 0}',
                  money(_buscar(r.vendieron, nombre)?.ventas ?? 0),
                ],
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// Abre el menú de compartir para guardar o mandar el PDF.
  static Future<void> compartir(Uint8List bytes, String archivo) {
    return Printing.sharePdf(bytes: bytes, filename: archivo);
  }

  static PersonaStat? _buscar(List<PersonaStat> lista, String nombre) {
    for (final p in lista) {
      if (p.nombre == nombre) {
        return p;
      }
    }
    return null;
  }

  static pw.Widget _kpi(String etiqueta, String valor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _crema,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: _linea),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(etiqueta, style: const pw.TextStyle(fontSize: 9, color: _gris)),
            pw.SizedBox(height: 3),
            pw.Text(
              valor,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _espresso),
            ),
          ],
        ),
      ),
    );
  }

  /// Gráfica de barras verticales (ventas por hora, día o semana).
  static pw.Widget _graficaBarras(List<String> etiquetas, List<double> valores) {
    const altoMaximo = 130.0;
    final maximo = valores.isEmpty ? 0.0 : valores.reduce((a, b) => a > b ? a : b);
    if (valores.isEmpty || maximo <= 0) {
      return pw.Text('Sin ventas en este periodo.', style: const pw.TextStyle(color: _gris));
    }
    final muchas = valores.length > 10;
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(8, 10, 8, 6),
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _linea),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < valores.length; i++)
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    if (!muchas && valores[i] > 0)
                      pw.Text(
                        money(valores[i]),
                        style: const pw.TextStyle(fontSize: 7, color: _cafe),
                      ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      height: valores[i] <= 0 ? 1 : (valores[i] / maximo) * altoMaximo,
                      decoration: pw.BoxDecoration(
                        color: valores[i] == maximo ? _caramelo : _cafe,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(3),
                          topRight: pw.Radius.circular(3),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      i < etiquetas.length ? etiquetas[i] : '',
                      style: pw.TextStyle(fontSize: muchas ? 6 : 8, color: _gris),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Barras horizontales (productos más vendidos).
  static pw.Widget _barrasHorizontales(
    List<String> etiquetas,
    List<double> valores,
    String Function(double) formato,
  ) {
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    return pw.Column(
      children: [
        for (var i = 0; i < valores.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 140,
                  child: pw.Text(
                    '${i + 1}. ${etiquetas[i]}',
                    style: const pw.TextStyle(fontSize: 10),
                    maxLines: 1,
                  ),
                ),
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: maximo <= 0 ? 1 : (valores[i] / maximo * 100).round().clamp(1, 100).toInt(),
                        child: pw.Container(
                          height: 12,
                          decoration: pw.BoxDecoration(
                            color: i == 0 ? _caramelo : _cafe,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: maximo <= 0
                            ? 99
                            : (100 - (valores[i] / maximo * 100).round()).clamp(0, 99).toInt() + 1,
                        child: pw.SizedBox(),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(
                  width: 60,
                  child: pw.Text(
                    formato(valores[i]),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 10, color: _cafe),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _tabla(List<String> encabezados, List<List<String>> filas) {
    if (filas.isEmpty) {
      return pw.Text('Sin datos en este periodo.', style: const pw.TextStyle(color: _gris));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: _linea, width: 0.8),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _crema),
          children: [
            for (final e in encabezados)
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  e,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _cafe),
                ),
              ),
          ],
        ),
        for (final f in filas)
          pw.TableRow(
            children: [
              for (final c in f)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(c, style: const pw.TextStyle(fontSize: 10)),
                ),
            ],
          ),
      ],
    );
  }
}
