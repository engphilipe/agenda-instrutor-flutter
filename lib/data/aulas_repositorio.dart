import '../core/api.dart';
import 'modelos.dart';

/// Aulas do usuário logado. Escrita só por funções do banco (RPC), que aplicam
/// as regras: grade, disponibilidade, conflito e prazo de 2 h.
class AulasRepositorio {
  AulasRepositorio(this._api);

  final Api _api;

  Future<List<Aula>> doAluno(String alunoId) async {
    final json = await _api.get('/rest/v1/bookings', query: {
      'select': '*',
      'student_id': 'eq.$alunoId',
      'order': 'inicio.desc',
      'limit': '100',
    }) as List;
    final aulas = json.map((j) => Aula.deJson(j)).toList();
    return _comContrapartes(aulas, (a) => a.instrutorId);
  }

  /// Aulas do instrutor entre dois instantes (inclusive canceladas).
  Future<List<Aula>> doInstrutor(
    String instrutorId,
    DateTime de,
    DateTime ate,
  ) async {
    final json = await _api.get('/rest/v1/bookings', query: {
      'select': '*',
      'instructor_id': 'eq.$instrutorId',
      'and': '(inicio.gte.${de.toUtc().toIso8601String()},'
          'inicio.lt.${ate.toUtc().toIso8601String()})',
      'order': 'inicio',
    }) as List;
    final aulas = json.map((j) => Aula.deJson(j)).toList();
    return _comContrapartes(aulas, (a) => a.alunoId);
  }

  /// Nome/telefone da outra parte (o banco libera o perfil de quem tem aula em comum).
  Future<List<Aula>> _comContrapartes(
    List<Aula> aulas,
    String? Function(Aula) idDe,
  ) async {
    final ids = aulas.map(idDe).whereType<String>().toSet();
    if (ids.isEmpty) return aulas;
    final json = await _api.get('/rest/v1/profiles', query: {
      'select': 'id,role,nome,telefone,cidade_id',
      'id': 'in.(${ids.join(',')})',
    }) as List;
    final perfis = {
      for (final p in json.map((j) => Perfil.deJson(j))) p.id: p,
    };
    return [for (final a in aulas) a.comContraparte(perfis[idDe(a)])];
  }

  Future<void> cancelar(String aulaId, {String? motivo}) =>
      _api.rpc('cancelar_aula', {
        'p_booking': aulaId,
        if (motivo != null && motivo.trim().isNotEmpty) 'p_motivo': motivo.trim(),
      });

  /// Instrutor lança uma aula na própria agenda (ex.: aluno que marcou por telefone).
  Future<void> lancar({
    required DateTime inicio,
    required String alunoNome,
    String? alunoTelefone,
  }) =>
      _api.rpc('lancar_aula', {
        'p_inicio': inicio.toUtc().toIso8601String(),
        'p_aluno_nome': alunoNome.trim(),
        if (alunoTelefone != null && alunoTelefone.isNotEmpty)
          'p_aluno_telefone': alunoTelefone,
      });

  Future<void> registrarDesfecho(String aulaId, StatusAula status) =>
      _api.rpc('registrar_desfecho_aula', {
        'p_booking': aulaId,
        'p_status': status.name,
      });
}
