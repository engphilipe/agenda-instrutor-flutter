/// Datas e horas no fuso de São Paulo.
///
/// O banco guarda instantes em UTC; a agenda é pensada em hora local de
/// America/Sao_Paulo, que é UTC-3 o ano todo (sem horário de verão desde 2019).
///
/// Convenção: uma "data local" é um `DateTime.utc(ano, mes, dia)` cujos campos
/// representam o dia no calendário de São Paulo.
library;

const _offset = Duration(hours: -3);

/// Horas de início possíveis das aulas: 04:00 a 22:00 (aulas de 50 min).
const horasDaGrade = [
  4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
];

const duracaoAula = Duration(minutes: 50);

/// Aluno só cancela até 2 h antes do início.
const antecedenciaCancelamento = Duration(hours: 2);

/// Instante → relógio de São Paulo (campos do DateTime são a hora local).
DateTime paraLocal(DateTime instante) => instante.toUtc().add(_offset);

/// Data local + hora cheia → instante UTC.
DateTime paraInstante(DateTime dataLocal, int hora) =>
    DateTime.utc(dataLocal.year, dataLocal.month, dataLocal.day, hora)
        .subtract(_offset);

/// Dia de hoje em São Paulo.
DateTime hojeLocal([DateTime? agora]) => soData(paraLocal(agora ?? DateTime.now()));

DateTime soData(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime somarDias(DateTime dataLocal, int dias) =>
    DateTime.utc(dataLocal.year, dataLocal.month, dataLocal.day + dias);

/// 0 = domingo … 6 = sábado (mesma convenção do banco).
int diaDaSemana(DateTime dataLocal) => dataLocal.weekday % 7;

/// `2026-10-30`
String dataIso(DateTime dataLocal) =>
    '${dataLocal.year.toString().padLeft(4, '0')}-'
    '${dataLocal.month.toString().padLeft(2, '0')}-'
    '${dataLocal.day.toString().padLeft(2, '0')}';

DateTime lerData(String iso) {
  final p = iso.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// `"08:00:00"` → 8
int lerHora(String hora) => int.parse(hora.split(':').first);

/// 8 → `"08:00"`
String horaTexto(int hora) => '${hora.toString().padLeft(2, '0')}:00';
