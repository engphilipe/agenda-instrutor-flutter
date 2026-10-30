/// Formatação em pt-BR (datas sempre no fuso de São Paulo).
library;

import 'tempo.dart';

const _diasCurtos = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
const diasDaSemana = [
  'Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado',
];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

/// `seg, 03/11`
String formatarData(DateTime dataLocal) =>
    '${_diasCurtos[diaDaSemana(dataLocal)]}, ${_doisDigitos(dataLocal.day)}/${_doisDigitos(dataLocal.month)}';

/// `seg, 03/11 · 09:00–09:50`
String formatarAula(DateTime inicio) {
  final l = paraLocal(inicio);
  final f = l.add(duracaoAula);
  return '${formatarData(soData(l))} · ${_doisDigitos(l.hour)}:${_doisDigitos(l.minute)}–${_doisDigitos(f.hour)}:${_doisDigitos(f.minute)}';
}

/// `R$ 25,00`
String formatarMoeda(int centavos) {
  final reais = (centavos ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  return 'R\$ $reais,${_doisDigitos(centavos % 100)}';
}

/// `(11) 98765-4321`
String formatarTelefone(String? digitos) {
  if (digitos == null || digitos.isEmpty) return '';
  if (digitos.length == 11) {
    return '(${digitos.substring(0, 2)}) ${digitos.substring(2, 7)}-${digitos.substring(7)}';
  }
  if (digitos.length == 10) {
    return '(${digitos.substring(0, 2)}) ${digitos.substring(2, 6)}-${digitos.substring(6)}';
  }
  return digitos;
}

const nomesCategoria = {'A': 'Moto (A)', 'B': 'Carro (B)'};
