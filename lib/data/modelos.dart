/// Modelos de dados (linhas do banco convertidas de/para JSON).
library;

class Cidade {
  const Cidade(this.id, this.nome, this.uf);

  factory Cidade.deJson(Map<String, dynamic> j) =>
      Cidade(j['id'] as int, j['nome'] as String, j['uf'] as String);

  final int id;
  final String nome;
  final String uf;

  @override
  String toString() => '$nome/$uf';
}

enum Papel { aluno, instrutor, admin }

Papel _papel(String role) => switch (role) {
      'instructor' => Papel.instrutor,
      'admin' => Papel.admin,
      _ => Papel.aluno,
    };

class Perfil {
  const Perfil({
    required this.id,
    required this.papel,
    required this.nome,
    this.telefone,
    this.cidadeId,
  });

  factory Perfil.deJson(Map<String, dynamic> j) => Perfil(
        id: j['id'] as String,
        papel: _papel(j['role'] as String),
        nome: j['nome'] as String,
        telefone: j['telefone'] as String?,
        cidadeId: j['cidade_id'] as int?,
      );

  final String id;
  final Papel papel;
  final String nome;
  final String? telefone;
  final int? cidadeId;

  bool get ehInstrutor => papel == Papel.instrutor;
}

/// Instrutor aprovado, como aparece na busca (view `instrutores_publicos`).
class Instrutor {
  const Instrutor({
    required this.id,
    required this.nome,
    required this.categorias,
    this.bio,
    this.veiculo,
    this.cidade,
    this.regiaoAtuacao,
    this.pontoEncontro,
    this.ofereceBusca = false,
    this.taxaBuscaCentavos,
    this.notaMedia = 0,
    this.totalAvaliacoes = 0,
  });

  factory Instrutor.deJson(Map<String, dynamic> j) => Instrutor(
        id: j['id'] as String,
        nome: j['nome'] as String? ?? '',
        categorias: List<String>.from(j['categorias_cnh'] as List? ?? const []),
        bio: j['bio'] as String?,
        veiculo: j['veiculo'] as String?,
        cidade: j['cidade_nome'] == null
            ? null
            : '${j['cidade_nome']}/${j['cidade_uf']}',
        regiaoAtuacao: j['regiao_atuacao'] as String?,
        pontoEncontro: j['ponto_encontro'] as String?,
        ofereceBusca: j['oferece_busca'] as bool? ?? false,
        taxaBuscaCentavos: j['taxa_busca_centavos'] as int?,
        notaMedia: (j['nota_media'] as num?)?.toDouble() ?? 0,
        totalAvaliacoes: j['total_avaliacoes'] as int? ?? 0,
      );

  final String id;
  final String nome;
  final List<String> categorias;
  final String? bio;
  final String? veiculo;
  final String? cidade;
  final String? regiaoAtuacao;
  final String? pontoEncontro;
  final bool ofereceBusca;
  final int? taxaBuscaCentavos;
  final double notaMedia;
  final int totalAvaliacoes;
}

/// Perfil profissional do próprio instrutor (tabela `instructors`).
class PerfilProfissional {
  const PerfilProfissional({
    required this.categorias,
    required this.status,
    required this.ativo,
    this.bio,
    this.veiculo,
    this.cidadeId,
    this.pontoEncontro,
    this.ofereceBusca = false,
    this.taxaBuscaCentavos,
  });

  factory PerfilProfissional.deJson(Map<String, dynamic> j) =>
      PerfilProfissional(
        categorias: List<String>.from(j['categorias_cnh'] as List? ?? const []),
        status: j['status_verificacao'] as String,
        ativo: j['ativo'] as bool? ?? true,
        bio: j['bio'] as String?,
        veiculo: j['veiculo'] as String?,
        cidadeId: j['cidade_id'] as int?,
        pontoEncontro: j['ponto_encontro'] as String?,
        ofereceBusca: j['oferece_busca'] as bool? ?? false,
        taxaBuscaCentavos: j['taxa_busca_centavos'] as int?,
      );

  final List<String> categorias;

  /// `pendente`, `aprovado` ou `recusado`
  final String status;
  final bool ativo;
  final String? bio;
  final String? veiculo;
  final int? cidadeId;
  final String? pontoEncontro;
  final bool ofereceBusca;
  final int? taxaBuscaCentavos;
}

class Endereco {
  const Endereco({
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidadeId,
    this.complemento,
  });

  factory Endereco.deJson(Map<String, dynamic> j) => Endereco(
        cep: j['cep'] as String,
        logradouro: j['logradouro'] as String,
        numero: j['numero'] as String,
        bairro: j['bairro'] as String,
        cidadeId: j['cidade_id'] as int,
        complemento: j['complemento'] as String?,
      );

  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final int cidadeId;

  Map<String, Object?> paraJson(String perfilId) => {
        'profile_id': perfilId,
        'cep': cep,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cidade_id': cidadeId,
      };
}

enum StatusAula { pendente, confirmada, cancelada, concluida, faltou }

const nomesStatus = {
  StatusAula.pendente: 'Pendente',
  StatusAula.confirmada: 'Confirmada',
  StatusAula.cancelada: 'Cancelada',
  StatusAula.concluida: 'Concluída',
  StatusAula.faltou: 'Aluno faltou',
};

class Aula {
  const Aula({
    required this.id,
    required this.instrutorId,
    required this.inicio,
    required this.status,
    required this.origem,
    required this.localTipo,
    this.alunoId,
    this.alunoAvulsoNome,
    this.alunoAvulsoTelefone,
    this.enderecoBusca,
    this.taxaBuscaCentavos,
    this.observacaoAluno,
    this.motivoCancelamento,
    this.contraparte,
  });

  factory Aula.deJson(Map<String, dynamic> j) => Aula(
        id: j['id'] as String,
        instrutorId: j['instructor_id'] as String,
        alunoId: j['student_id'] as String?,
        alunoAvulsoNome: j['aluno_avulso_nome'] as String?,
        alunoAvulsoTelefone: j['aluno_avulso_telefone'] as String?,
        inicio: DateTime.parse(j['inicio'] as String).toUtc(),
        status: StatusAula.values.byName(j['status'] as String),
        origem: j['origem'] as String,
        localTipo: j['local_tipo'] as String,
        enderecoBusca: j['endereco_busca'] as String?,
        taxaBuscaCentavos: j['taxa_busca_centavos'] as int?,
        observacaoAluno: j['observacao_aluno'] as String?,
        motivoCancelamento: j['motivo_cancelamento'] as String?,
      );

  final String id;
  final String instrutorId;
  final String? alunoId;
  final String? alunoAvulsoNome;
  final String? alunoAvulsoTelefone;
  final DateTime inicio;
  final StatusAula status;

  /// `aluno` (agendada pelo aluno) ou `instrutor` (lançada manualmente)
  final String origem;

  /// `ponto_encontro` ou `busca`
  final String localTipo;
  final String? enderecoBusca;
  final int? taxaBuscaCentavos;
  final String? observacaoAluno;
  final String? motivoCancelamento;

  /// Nome e telefone da outra parte (instrutor para o aluno, aluno para o instrutor).
  final Perfil? contraparte;

  DateTime get fim => inicio.add(const Duration(minutes: 50));

  bool get ativa =>
      status == StatusAula.confirmada || status == StatusAula.pendente;

  String get nomeAluno => contraparte?.nome ?? alunoAvulsoNome ?? 'Aluno';

  String? get telefoneAluno => contraparte?.telefone ?? alunoAvulsoTelefone;

  Aula comContraparte(Perfil? perfil) => Aula(
        id: id,
        instrutorId: instrutorId,
        alunoId: alunoId,
        alunoAvulsoNome: alunoAvulsoNome,
        alunoAvulsoTelefone: alunoAvulsoTelefone,
        inicio: inicio,
        status: status,
        origem: origem,
        localTipo: localTipo,
        enderecoBusca: enderecoBusca,
        taxaBuscaCentavos: taxaBuscaCentavos,
        observacaoAluno: observacaoAluno,
        motivoCancelamento: motivoCancelamento,
        contraparte: perfil,
      );
}
