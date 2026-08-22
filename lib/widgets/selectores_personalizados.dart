import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xff6D3EFF);
const Color kTextDarkColor = Color(0xff102A43);

InputDecoration inputDecoration(
  String label, {
  IconData? icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
    prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade500) : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

/// ─────────────────────────────────────────────────────────────────
/// Tarjeta de sección con encabezado (icono + título) usada en
/// "Nuevo Pedido". Reutilízala para que otros formularios (como
/// Recordatorios) tengan el mismo aspecto.
/// ─────────────────────────────────────────────────────────────────
Widget seccionCard({
  required String titulo,
  required IconData icon,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kPrimaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextDarkColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

String formatearFechaLarga(DateTime fecha) {
  const meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  const diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  return '${diasSemana[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
}

String _formatearMesAnio(DateTime fecha) {
  const meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${meses[fecha.month - 1]} ${fecha.year}';
}

/// ─────────────────────────────────────────────────────────────────
/// Calendario personalizado (el mismo diseño morado con cuadrícula
/// de días que ya tenías en "Nuevo Pedido"), ahora reutilizable.
/// Rango permitido: hoy → hoy + 365 días (igual que antes).
/// ─────────────────────────────────────────────────────────────────
Widget calendarioPersonalizado({
  required DateTime mesActual,
  required Function(DateTime) onDateSelected,
  required DateTime fechaSeleccionada,
  required Function(DateTime) onMesCambiado,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final year = mesActual.year;
  final month = mesActual.month;
  final firstDay = DateTime(year, month, 1);
  final firstDayWeekday = firstDay.weekday;
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final prevMonth = month == 1 ? 12 : month - 1;
  final prevYear = month == 1 ? year - 1 : year;
  final daysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
  final prevMonthDays = List.generate(
    firstDayWeekday - 1,
    (index) => daysInPrevMonth - (firstDayWeekday - 2) + index,
  );
  final currentMonthDays = List.generate(daysInMonth, (index) => index + 1);
  final totalDays = prevMonthDays.length + currentMonthDays.length;
  final remainingDays = (7 - totalDays % 7) % 7;
  final nextMonthDays = List.generate(remainingDays, (index) => index + 1);
  final allDays = [
    ...prevMonthDays.map((d) => {'day': d, 'isCurrentMonth': false}),
    ...currentMonthDays.map((d) => {'day': d, 'isCurrentMonth': true}),
    ...nextMonthDays.map((d) => {'day': d, 'isCurrentMonth': false}),
  ];

  List<Widget> rows = [];
  for (int i = 0; i < allDays.length; i += 7) {
    final weekDays = allDays.sublist(
      i,
      i + 7 > allDays.length ? allDays.length : i + 7,
    );
    rows.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((dayInfo) {
            final day = dayInfo['day'] as int;
            final isCurrentMonth = dayInfo['isCurrentMonth'] as bool;
            int dayMonth = month;
            int dayYear = year;
            if (!isCurrentMonth) {
              if (day > 15) {
                dayMonth = month - 1;
                if (dayMonth == 0) {
                  dayMonth = 12;
                  dayYear = year - 1;
                }
              } else {
                dayMonth = month + 1;
                if (dayMonth == 13) {
                  dayMonth = 1;
                  dayYear = year + 1;
                }
              }
            }
            final date = DateTime(dayYear, dayMonth, day);
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isSelected =
                date.year == fechaSeleccionada.year &&
                date.month == fechaSeleccionada.month &&
                date.day == fechaSeleccionada.day;
            final isBeforeToday = date.isBefore(today);
            final isAfterYear = date.isAfter(
              today.add(const Duration(days: 365)),
            );
            final isDisabled = isBeforeToday || isAfterYear;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!isDisabled) onDateSelected(date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimaryColor
                        : isToday && !isSelected
                        ? kPrimaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isDisabled
                            ? Colors.grey.shade300
                            : isSelected
                            ? Colors.white
                            : isToday
                            ? kPrimaryColor
                            : isCurrentMonth
                            ? kTextDarkColor
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200, width: 1.5),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => onMesCambiado(
                  DateTime(mesActual.year, mesActual.month - 1, 1),
                ),
              ),
              Text(
                _formatearMesAnio(mesActual),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => onMesCambiado(
                  DateTime(mesActual.year, mesActual.month + 1, 1),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'].map((dia) {
              return Expanded(
                child: Center(
                  child: Text(
                    dia,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: rows),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

/// Abre el diálogo con el calendario personalizado y devuelve la fecha
/// elegida (o null si el usuario cancela).
Future<DateTime?> mostrarSelectorFecha(
  BuildContext context, {
  required DateTime fechaInicial,
}) async {
  DateTime mesActual = DateTime(fechaInicial.year, fechaInicial.month, 1);
  DateTime fechaTemp = fechaInicial;
  DateTime? resultado;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatearFechaLarga(fechaTemp),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                calendarioPersonalizado(
                  mesActual: mesActual,
                  fechaSeleccionada: fechaTemp,
                  onDateSelected: (date) =>
                      setStateDialog(() => fechaTemp = date),
                  onMesCambiado: (nuevoMes) =>
                      setStateDialog(() => mesActual = nuevoMes),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        resultado = fechaTemp;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  return resultado;
}

/// ─────────────────────────────────────────────────────────────────
/// Selector de hora tipo "reloj" (como el de las alarmas del
/// teléfono). Usa el time picker nativo de Flutter, forzado a modo
/// "dial" (reloj) y coloreado con el morado de la app.
/// ─────────────────────────────────────────────────────────────────
Future<TimeOfDay?> mostrarSelectorHora(
  BuildContext context, {
  required TimeOfDay horaInicial,
}) {
  return showTimePicker(
    context: context,
    initialTime: horaInicial,
    initialEntryMode:
        TimePickerEntryMode.dial, // fuerza el reloj (no el teclado)
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: kPrimaryColor, // manecilla y hora seleccionada
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            dialHandColor: kPrimaryColor,
            dialBackgroundColor: kPrimaryColor.withValues(alpha: 0.08),
            entryModeIconColor: kPrimaryColor,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
          ),
        ),
        child: child!,
      );
    },
  );
}
