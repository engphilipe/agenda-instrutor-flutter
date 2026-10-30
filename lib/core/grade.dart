/// Cálculo dos horários de um instrutor:
/// livres = regras semanais + exceções "extra" − exceções "bloqueio" − aulas − passado.
/// O banco aplica a mesma regra (`slot_disponivel`) e revalida ao agendar.
library;

import 'tempo.dart';

enum EstadoHorario { fechado, livre, ocupado, passado }

class Regra {
  const Regra(this.diaSemana, this.horaInicio, this.horaFim);

  factory Regra.deJson(Map<String, dynamic> j) => Regra(
        j['dia_semana'] as int,
        lerHora(j['hora_inicio'] as String),
        lerHora(j['hora_fim'] as String),
      );

  final int diaSemana;
  final int horaInicio;

  /// Exclusivo: regra 08–12 abre 08, 09, 10 e 11.
  final int horaFim;

  Map<String, Object> paraJson() => {
        'dia_semana': diaSemana,
        'hora_inicio': horaTexto(horaInicio),
        'hora_fim': horaTexto(horaFim),
      };

  bool cobre(int hora) => hora >= horaInicio && hora < horaFim;
}

class Excecao {
  const Excecao(this.data, this.horaInicio, this.horaFim, this.tipo);

  factory Excecao.deJson(Map<String, dynamic> j) => Excecao(
        lerData(j['data'] as String),
        lerHora(j['hora_inicio'] as String),
        lerHora(j['hora_fim'] as String),
        j['tipo'] as String,
      );

  final DateTime data;
  final int horaInicio;
  final int horaFim;

  /// `bloqueio` ou `extra`
  final String tipo;

  bool cobre(DateTime dia, int hora) =>
      data == dia && hora >= horaInicio && hora < horaFim;
}

class Intervalo {
  const Intervalo(this.inicio, this.fim);

  final DateTime inicio;
  final DateTime fim;

  bool sobrepoe(DateTime outroInicio, DateTime outroFim) =>
      inicio.isBefore(outroFim) && outroInicio.isBefore(fim);
}

class Horario {
  const Horario(this.data, this.hora, this.inicio, this.aberto, this.estado);

  final DateTime data;
  final int hora;
  final DateTime inicio;
  final bool aberto;
  final EstadoHorario estado;
}

/// Os 19 horários de um dia com o estado de cada um.
List<Horario> gradeDoDia(
  DateTime data, {
  required List<Regra> regras,
  required List<Excecao> excecoes,
  required List<Intervalo> ocupados,
  required DateTime agora,
}) {
  final dia = diaDaSemana(data);
  return [
    for (final hora in horasDaGrade)
      () {
        final inicio = paraInstante(data, hora);
        final fim = inicio.add(duracaoAula);
        final doDia = excecoes.where((e) => e.cobre(data, hora));
        final bloqueado = doDia.any((e) => e.tipo == 'bloqueio');
        final aberto = !bloqueado &&
            (doDia.any((e) => e.tipo == 'extra') ||
                regras.any((r) => r.diaSemana == dia && r.cobre(hora)));
        final ocupado = ocupados.any((o) => o.sobrepoe(inicio, fim));

        final EstadoHorario estado;
        if (ocupado) {
          estado = EstadoHorario.ocupado;
        } else if (!inicio.isAfter(agora)) {
          estado = EstadoHorario.passado;
        } else if (aberto) {
          estado = EstadoHorario.livre;
        } else {
          estado = EstadoHorario.fechado;
        }
        return Horario(data, hora, inicio, aberto, estado);
      }(),
  ];
}

/// Semana padrão (dia → horas abertas) em regras com horas consecutivas agrupadas.
List<Regra> regrasDaSemana(Map<int, Set<int>> semana) {
  final regras = <Regra>[];
  for (final dia in semana.keys.toList()..sort()) {
    final horas = semana[dia]!.toList()..sort();
    int? inicio;
    for (var i = 0; i < horas.length; i++) {
      inicio ??= horas[i];
      final ultimaDoBloco = i == horas.length - 1 || horas[i + 1] != horas[i] + 1;
      if (ultimaDoBloco) {
        regras.add(Regra(dia, inicio, horas[i] + 1));
        inicio = null;
      }
    }
  }
  return regras;
}

/// Regras do banco → semana padrão (dia → horas abertas).
Map<int, Set<int>> semanaDasRegras(List<Regra> regras) {
  final semana = {for (var d = 0; d < 7; d++) d: <int>{}};
  for (final r in regras) {
    for (var h = r.horaInicio; h < r.horaFim; h++) {
      if (horasDaGrade.contains(h)) semana[r.diaSemana]!.add(h);
    }
  }
  return semana;
}
