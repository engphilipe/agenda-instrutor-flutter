import 'package:agenda_instrutor_flutter/core/erros.dart';
import 'package:agenda_instrutor_flutter/core/formatacao.dart';
import 'package:agenda_instrutor_flutter/core/grade.dart';
import 'package:agenda_instrutor_flutter/core/tempo.dart';
import 'package:agenda_instrutor_flutter/core/validadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tempo (São Paulo = UTC-3)', () {
    test('hora local vira instante UTC', () {
      final segunda = DateTime.utc(2030, 3, 4);
      expect(paraInstante(segunda, 9), DateTime.utc(2030, 3, 4, 12));
      expect(diaDaSemana(segunda), 1);
      expect(diaDaSemana(DateTime.utc(2030, 3, 3)), 0);
    });

    test('instante perto da meia-noite UTC cai no dia anterior em SP', () {
      expect(hojeLocal(DateTime.utc(2030, 3, 5, 1)), DateTime.utc(2030, 3, 4));
    });

    test('datas e horas em texto', () {
      expect(dataIso(DateTime.utc(2030, 3, 4)), '2030-03-04');
      expect(lerData('2030-03-04'), DateTime.utc(2030, 3, 4));
      expect(lerHora('08:00:00'), 8);
      expect(horaTexto(8), '08:00');
    });
  });

  group('grade', () {
    final segunda = DateTime.utc(2030, 3, 4);
    final antes = DateTime.utc(2030, 3, 1);
    const regras = [Regra(1, 8, 12)];

    test('regra semanal abre horários; bloqueio fecha; aula ocupa', () {
      final grade = gradeDoDia(
        segunda,
        regras: regras,
        excecoes: [
          Excecao(segunda, 10, 11, 'bloqueio'),
          Excecao(segunda, 15, 16, 'extra'),
        ],
        ocupados: [Intervalo(paraInstante(segunda, 9), paraInstante(segunda, 9).add(duracaoAula))],
        agora: antes,
      );
      EstadoHorario estado(int h) => grade.firstWhere((x) => x.hora == h).estado;

      expect(grade, hasLength(19));
      expect(estado(8), EstadoHorario.livre);
      expect(estado(9), EstadoHorario.ocupado);
      expect(estado(10), EstadoHorario.fechado);
      expect(estado(11), EstadoHorario.livre);
      expect(estado(12), EstadoHorario.fechado);
      expect(estado(15), EstadoHorario.livre);
    });

    test('horário que já começou não é agendável', () {
      final grade = gradeDoDia(
        segunda,
        regras: regras,
        excecoes: const [],
        ocupados: const [],
        agora: paraInstante(segunda, 9),
      );
      expect(grade.firstWhere((x) => x.hora == 9).estado, EstadoHorario.passado);
      expect(grade.firstWhere((x) => x.hora == 10).estado, EstadoHorario.livre);
    });

    test('semana padrão ↔ regras agrupa horas consecutivas', () {
      final regras = regrasDaSemana({1: {8, 9, 10, 14}, 3: {}});
      expect(regras.map((r) => r.paraJson()), [
        {'dia_semana': 1, 'hora_inicio': '08:00', 'hora_fim': '11:00'},
        {'dia_semana': 1, 'hora_inicio': '14:00', 'hora_fim': '15:00'},
      ]);
      expect(semanaDasRegras(regras)[1], {8, 9, 10, 14});
      expect(semanaDasRegras(regras)[3], isEmpty);
    });
  });

  group('validadores', () {
    test('e-mail', () {
      expect(validarEmail('ana@exemplo.com'), isNull);
      expect(validarEmail('ana@'), isNotNull);
      expect(validarEmail(''), isNotNull);
    });

    test('senha exige 8 caracteres com letras e números', () {
      expect(validarSenha('abc12345'), isNull);
      expect(validarSenha('abcdefgh'), isNotNull);
      expect(validarSenha('1234567'), isNotNull);
    });

    test('telefone com DDD', () {
      expect(validarTelefone(''), isNull);
      expect(validarTelefone('', opcional: false), isNotNull);
      expect(validarTelefone('(11) 98765-4321'), isNull);
      expect(validarTelefone('98765'), isNotNull);
    });

    test('CEP e taxa', () {
      expect(validarCep('01310-100'), isNull);
      expect(validarCep('0131'), isNotNull);
      expect(validarTaxa('25,50'), isNull);
      expect(validarTaxa('-1'), isNotNull);
      expect(reaisParaCentavos('25,50'), 2550);
    });
  });

  group('formatação', () {
    test('moeda, telefone e aula', () {
      expect(formatarMoeda(123456), r'R$ 1.234,56');
      expect(formatarTelefone('11987654321'), '(11) 98765-4321');
      expect(formatarAula(DateTime.utc(2030, 3, 4, 12)), 'seg, 04/03 · 09:00–09:50');
    });
  });

  group('erros', () {
    test('código de regra do banco vira mensagem em português', () {
      final e = erroDaResposta(400, {'code': 'P0001', 'message': 'PRAZO_CANCELAMENTO_EXPIRADO'});
      expect(e.codigo, 'PRAZO_CANCELAMENTO_EXPIRADO');
      expect(e.mensagem, contains('2 horas'));
    });

    test('erros do Auth, de formato e do servidor', () {
      expect(erroDaResposta(400, {'error_code': 'invalid_credentials'}).mensagem,
          'E-mail ou senha incorretos.');
      expect(erroDaResposta(400, {'code': '23514'}).tipo, TipoErro.validacao);
      expect(erroDaResposta(503, null).tipo, TipoErro.servico);
    });
  });
}
