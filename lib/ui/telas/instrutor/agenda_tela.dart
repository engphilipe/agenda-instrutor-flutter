import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao.dart';
import '../../../core/grade.dart';
import '../../../core/tempo.dart';
import '../../../core/validadores.dart';
import '../../../data/agenda_repositorio.dart';
import '../../../data/aulas_repositorio.dart';
import '../../../data/modelos.dart';
import '../../../state/sessao.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import '../aluno/minhas_aulas_tela.dart' show ChipStatus;

class _Dia {
  const _Dia(this.grade, this.aulas, this.status);

  final List<Horario> grade;
  final List<Aula> aulas;
  final String status;
}

/// Agenda do instrutor: os 19 horários do dia, com aulas, horários abertos e fechados.
class AgendaTela extends StatefulWidget {
  const AgendaTela({super.key});

  @override
  State<AgendaTela> createState() => _AgendaTelaState();
}

class _AgendaTelaState extends State<AgendaTela> {
  final _hoje = hojeLocal();
  late DateTime _dia = _hoje;

  Future<_Dia> _carregar() async {
    final id = context.read<Sessao>().usuarioId;
    final agenda = context.read<AgendaRepositorio>();
    final (regras, excecoes, aulas, perfil) = await (
      agenda.regras(id),
      agenda.excecoes(id, _dia, _dia),
      context.read<AulasRepositorio>().doInstrutor(
            id,
            paraInstante(_dia, 0),
            paraInstante(somarDias(_dia, 1), 0),
          ),
      agenda.perfilProfissional(id),
    ).wait;
    final ocupados = [
      for (final a in aulas.where((a) => a.status != StatusAula.cancelada))
        Intervalo(a.inicio, a.fim),
    ];
    final grade = gradeDoDia(
      _dia,
      regras: regras,
      excecoes: excecoes,
      ocupados: ocupados,
      agora: DateTime.now(),
    );
    return _Dia(grade, aulas, perfil.status);
  }

  @override
  Widget build(BuildContext context) {
    final dias = [for (var i = -7; i <= 30; i++) somarDias(_hoje, i)];
    return Scaffold(
      appBar: AppBar(title: const Text('Minha agenda')),
      body: Column(children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            controller: ScrollController(initialScrollOffset: 7 * 66),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dias.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) => _BotaoDia(
              dia: dias[i],
              hoje: dias[i] == _hoje,
              selecionado: dias[i] == _dia,
              aoTocar: () => setState(() => _dia = dias[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Carregador<_Dia>(
            key: ValueKey(_dia),
            carregar: _carregar,
            construir: (context, dia, recarregar) {
              final canceladas = dia.aulas.where((a) => a.status == StatusAula.cancelada);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (dia.status != 'aprovado') _AvisoVerificacao(dia.status),
                  Text(formatarData(_dia), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final h in dia.grade)
                    _LinhaHorario(
                      horario: h,
                      aula: dia.aulas
                          .where((a) => a.status != StatusAula.cancelada && a.inicio == h.inicio)
                          .firstOrNull,
                      aoMudar: recarregar,
                    ),
                  if (canceladas.isNotEmpty) ...[
                    const Secao('Canceladas'),
                    for (final a in canceladas)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${formatarAula(a.inicio)} · ${a.nomeAluno}'),
                        subtitle: a.motivoCancelamento == null ? null : Text(a.motivoCancelamento!),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _BotaoDia extends StatelessWidget {
  const _BotaoDia({
    required this.dia,
    required this.hoje,
    required this.selecionado,
    required this.aoTocar,
  });

  final DateTime dia;
  final bool hoje;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: aoTocar,
        child: Container(
          width: 60,
          decoration: BoxDecoration(
            color: selecionado ? Cores.botao : Cores.cartao,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hoje ? Cores.primaria : Cores.borda),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(diasDaSemana[diaDaSemana(dia)].substring(0, 3),
                  style: const TextStyle(fontSize: 12)),
              Text('${dia.day}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

class _AvisoVerificacao extends StatelessWidget {
  const _AvisoVerificacao(this.status);

  final String status;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline, color: Cores.nota),
            title: Text(status == 'recusado' ? 'Cadastro recusado' : 'Cadastro em análise'),
            subtitle: const Text(
              'Você ainda não aparece na busca dos alunos, mas já pode organizar '
              'sua agenda e lançar aulas.',
            ),
          ),
        ),
      );
}

class _LinhaHorario extends StatelessWidget {
  const _LinhaHorario({required this.horario, required this.aula, required this.aoMudar});

  final Horario horario;
  final Aula? aula;
  final Future<void> Function() aoMudar;

  @override
  Widget build(BuildContext context) {
    final h = horario;
    final passado = !h.inicio.isAfter(DateTime.now());
    final (cor, texto) = aula != null
        ? (Cores.perigoTexto, aula!.nomeAluno)
        : switch (h.estado) {
            EstadoHorario.livre => (Cores.primaria, 'Aberto para agendamento'),
            EstadoHorario.passado => (Cores.textoSuave, h.aberto ? 'Aberto (passou)' : '—'),
            _ => (Cores.textoSuave, 'Fechado'),
          };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: aula != null ? Cores.perigo.withValues(alpha: 0.15) : Cores.cartao,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: aula != null
              ? () => _detalhesAula(context, aula!)
              : passado
                  ? null
                  : () => _lancarAula(context, h),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              SizedBox(
                width: 52,
                child: Text(horaTexto(h.hora), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(child: Text(texto, style: TextStyle(color: cor))),
              if (aula != null)
                ChipStatus(aula!.status)
              else if (!passado)
                const Icon(Icons.add, size: 18, color: Cores.textoSuave),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _lancarAula(BuildContext context, Horario h) async {
    final lancou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LancarAula(horario: h),
    );
    if (lancou == true) await aoMudar();
  }

  Future<void> _detalhesAula(BuildContext context, Aula a) async {
    final mudou = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => _DetalhesAula(aula: a),
    );
    if (mudou == true) await aoMudar();
  }
}

/// Instrutor lança aula manualmente (aluno com ou sem conta no app).
class _LancarAula extends StatefulWidget {
  const _LancarAula({required this.horario});

  final Horario horario;

  @override
  State<_LancarAula> createState() => _LancarAulaState();
}

class _LancarAulaState extends State<_LancarAula> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  bool _ocupado = false;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _ocupado = true);
    try {
      await context.read<AulasRepositorio>().lancar(
            inicio: widget.horario.inicio,
            alunoNome: _nome.text,
            alunoTelefone: somenteDigitos(_telefone.text),
          );
      if (!mounted) return;
      mostrarMensagem(context, 'Aula lançada na agenda.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Lançar aula', style: Theme.of(context).textTheme.titleLarge),
              Text(formatarAula(widget.horario.inicio)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nome,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome do aluno'),
                textCapitalization: TextCapitalization.words,
                validator: validarNome,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefone,
                decoration: const InputDecoration(labelText: 'Telefone do aluno (opcional)'),
                keyboardType: TextInputType.phone,
                validator: validarTelefone,
              ),
              const SizedBox(height: 20),
              BotaoAcao(texto: 'Lançar aula', ocupado: _ocupado, aoPressionar: _salvar),
            ],
          ),
        ),
      );
}

class _DetalhesAula extends StatefulWidget {
  const _DetalhesAula({required this.aula});

  final Aula aula;

  @override
  State<_DetalhesAula> createState() => _DetalhesAulaState();
}

class _DetalhesAulaState extends State<_DetalhesAula> {
  bool _ocupado = false;

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    setState(() => _ocupado = true);
    try {
      await acao();
      if (!mounted) return;
      mostrarMensagem(context, sucesso);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.aula;
    final repo = context.read<AulasRepositorio>();
    final comecou = !a.inicio.isAfter(DateTime.now());
    final suave = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text(a.nomeAluno, style: Theme.of(context).textTheme.titleLarge)),
              ChipStatus(a.status),
            ]),
            Text(formatarAula(a.inicio)),
            if (a.telefoneAluno != null) Text(formatarTelefone(a.telefoneAluno), style: suave),
            Text(a.origem == 'aluno' ? 'Agendada pelo aluno no app' : 'Lançada por você', style: suave),
            if (a.localTipo == 'busca') Text('Buscar em: ${a.enderecoBusca}', style: suave),
            if (a.observacaoAluno != null) Text('Obs. do aluno: ${a.observacaoAluno}', style: suave),
            const SizedBox(height: 16),
            if (!comecou && a.ativa)
              OutlinedButton.icon(
                onPressed: _ocupado
                    ? null
                    : () async {
                        final ok = await confirmar(
                          context,
                          titulo: 'Cancelar aula?',
                          mensagem: 'O aluno será avisado.',
                          confirmarTexto: 'Cancelar aula',
                        );
                        if (ok) {
                          await _executar(
                            () => repo.cancelar(a.id, motivo: 'Cancelada pelo instrutor'),
                            'Aula cancelada.',
                          );
                        }
                      },
                icon: const Icon(Icons.close),
                label: const Text('Cancelar aula'),
                style: OutlinedButton.styleFrom(foregroundColor: Cores.perigoTexto),
              ),
            if (comecou && a.status != StatusAula.cancelada)
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _ocupado
                        ? null
                        : () => _executar(
                              () => repo.registrarDesfecho(a.id, StatusAula.concluida),
                              'Aula marcada como concluída.',
                            ),
                    icon: const Icon(Icons.check),
                    label: const Text('Concluída'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _ocupado
                        ? null
                        : () => _executar(
                              () => repo.registrarDesfecho(a.id, StatusAula.faltou),
                              'Falta registrada.',
                            ),
                    icon: const Icon(Icons.person_off_outlined),
                    label: const Text('Faltou'),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
